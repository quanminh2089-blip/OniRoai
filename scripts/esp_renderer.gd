extends Control
## ESP HUD của chính game OniRoai: hộp nhận diện (kể cả sau vật cản).
## Không dùng API overlay Android và không đọc/ghi bộ nhớ của ứng dụng khác.
const VISIBLE_COLOR := Color("#54f6d2")
const HIDDEN_COLOR := Color("#b69aff")
const LABEL_BG := Color(0.025, 0.050, 0.080, 0.88)
var visibility_cache: Dictionary = {}

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_process(true)

func _process(_delta: float) -> void:
    if Game.esp_enabled or Game.head_aim_enabled:
        queue_redraw()

# Truy vấn ray trong physics tick, không chạy trực tiếp ở render pass.
func _physics_process(_delta: float) -> void:
    if not Game.esp_enabled or not is_instance_valid(Game.hud):
        visibility_cache.clear()
        return
    var world = Game.hud.world
    if not is_instance_valid(world) or not world.playing or world.paused:
        visibility_cache.clear()
        return
    if not is_instance_valid(world.player) or not is_instance_valid(world.enemies): return
    var camera: Camera3D = world.player.camera
    visibility_cache.clear()
    for enemy in world.enemies.get_children():
        if enemy.dead: continue
        var head: Vector3 = enemy.global_position + Vector3.UP * 1.58
        var ray := PhysicsRayQueryParameters3D.create(camera.global_position, head, 1 | 4)
        ray.exclude = [world.player.get_rid()]
        var hit := world.get_world_3d().direct_space_state.intersect_ray(ray)
        visibility_cache[enemy.get_instance_id()] = not hit.is_empty() and hit.collider == enemy

func _draw() -> void:
    if not is_instance_valid(Game.hud): return
    var world = Game.hud.world
    if not is_instance_valid(world) or not world.playing or world.paused: return
    if not is_instance_valid(world.player) or not is_instance_valid(world.enemies): return
    var camera: Camera3D = world.player.camera
    if not is_instance_valid(camera): return

    if Game.head_aim_enabled:
        var center := size * 0.5
        var color := Color("#4ceac6") if world.player.aiming or world.player.fire_held else Color(Color("#4ceac6"), 0.45)
        draw_arc(center, 24.0, 0.0, TAU, 48, color, 1.5, true)
        draw_line(center + Vector2(-6, -30), center + Vector2(6, -30), color, 1.5, true)
        draw_line(center + Vector2(-6, 30), center + Vector2(6, 30), color, 1.5, true)

    if not Game.esp_enabled: return
    var visible_count := 0
    for enemy in world.enemies.get_children():
        if enemy.dead or not is_instance_valid(enemy): continue
        var head: Vector3 = enemy.global_position + Vector3.UP * 1.58
        var top: Vector3 = enemy.global_position + Vector3.UP * 1.82
        var feet: Vector3 = enemy.global_position + Vector3.UP * 0.04
        if camera.is_position_behind(head) or camera.is_position_behind(feet): continue
        var top_px := camera.unproject_position(top)
        var feet_px := camera.unproject_position(feet)
        var height := clampf(absf(feet_px.y - top_px.y), 30.0, 440.0)
        var width := height * 0.39
        var center_x := (top_px.x + feet_px.x) * 0.5
        var rect := Rect2(Vector2(center_x - width * 0.5, top_px.y), Vector2(width, height))
        if rect.end.x < 0 or rect.position.x > size.x or rect.end.y < 0 or rect.position.y > size.y: continue

        # ESP vẫn hiển thị địch sau vật cản; đổi màu theo dữ liệu physics.
        var clear: bool = bool(visibility_cache.get(enemy.get_instance_id(), false))
        var tint := VISIBLE_COLOR if clear else HIDDEN_COLOR
        draw_rect(rect, Color(tint.r, tint.g, tint.b, 0.045), true)
        _corners(rect, tint)

        var head_px := camera.unproject_position(head)
        var pulse := 5.5 + sin(Time.get_ticks_msec() * 0.006) * 0.65
        draw_arc(head_px, pulse, 0.0, TAU, 24, tint, 1.6, true)
        draw_circle(head_px, 1.8, tint)
        draw_line(Vector2(center_x, rect.end.y), Vector2(center_x, rect.end.y + 7), tint, 1.5, true)

        var distance := roundi(camera.global_position.distance_to(enemy.global_position))
        var label := "%s  ·  %dm" % [enemy.bot_name, distance]
        var font: Font = ThemeDB.fallback_font
        var font_size := 14
        var text_width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
        var badge := Rect2(Vector2(center_x - text_width * 0.5 - 8, rect.position.y - 29), Vector2(text_width + 16, 22))
        draw_rect(badge, LABEL_BG, true)
        draw_rect(badge, Color(tint.r, tint.g, tint.b, 0.55), false, 1.0)
        draw_string(font, Vector2(center_x - text_width * 0.5, badge.position.y + 16), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, tint)
        visible_count += 1

    if visible_count > 0:
        var font: Font = ThemeDB.fallback_font
        draw_rect(Rect2(Vector2(size.x * 0.5 - 69, 10), Vector2(138, 26)), LABEL_BG, true)
        draw_string(font, Vector2(size.x * 0.5 - 55, 29), "ESP  •  %d MỤC TIÊU" % visible_count, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, VISIBLE_COLOR)

func _corners(rect: Rect2, tint: Color) -> void:
    var x := rect.position.x
    var y := rect.position.y
    var r := rect.end.x
    var b := rect.end.y
    var corner := minf(17.0, minf(rect.size.x, rect.size.y) * 0.26)
    var thickness := 2.3
    for a in [[Vector2(x, y + corner), Vector2(x, y), Vector2(x + corner, y)],
              [Vector2(r - corner, y), Vector2(r, y), Vector2(r, y + corner)],
              [Vector2(x, b - corner), Vector2(x, b), Vector2(x + corner, b)],
              [Vector2(r - corner, b), Vector2(r, b), Vector2(r, b - corner)]]:
        draw_line(a[0], a[1], tint, thickness, true)
        draw_line(a[1], a[2], tint, thickness, true)
