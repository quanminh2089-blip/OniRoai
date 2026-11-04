extends Control
## Aim head reticle overlay. ESP bodies and distances are attached to enemies
## directly in enemy.gd, independent of viewport coordinates/scaling.
const AIM_COLOR := Color("#5eff71")

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_process(true)

func _process(_delta: float) -> void:
    if Game.head_aim_enabled:
        queue_redraw()

func _draw() -> void:
    if not Game.head_aim_enabled or not is_instance_valid(Game.hud):
        return
    var world = Game.hud.world
    if not is_instance_valid(world) or not world.playing or world.paused:
        return
    if not is_instance_valid(world.player):
        return
    var center := size * 0.5
    var tint := AIM_COLOR if world.player.aiming or world.player.fire_held else Color(AIM_COLOR, 0.42)
    draw_arc(center, 23.0, 0.0, TAU, 48, tint, 1.8, true)
    draw_line(center + Vector2(-5, -30), center + Vector2(5, -30), tint, 1.6, true)
    draw_line(center + Vector2(-5, 30), center + Vector2(5, 30), tint, 1.6, true)
