extends Control
## Trình kéo-thả nút trên màn hình ngang. Lưu tọa độ 0..1 theo safe area.
const Layout = preload("res://scripts/mobile_layout.gd")
const BLUE := Color("#83d6de")
const GOLD := Color("#edba73")
const BG := Color(0.009, 0.016, 0.025, 0.78)
var hud: CanvasLayer
var draft: Dictionary = {}
var dragging: String = ""
var mouse_is_down := false
var touch_id := -1

const NAMES := {
    "move": "DI CHUYỂN", "lean_left": "NGHIÊNG TRÁI", "lean_right": "NGHIÊNG PHẢI",
    "fire": "BẮN", "fire_left": "BẮN TRÁI", "aim": "NGẮM", "crouch": "CÚI",
    "jump": "NHẢY", "run": "CHẠY", "pause": "DỪNG"
}

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    draft = Game.custom_controls.duplicate(true)
    var buttons := HBoxContainer.new()
    buttons.anchor_left = 1.0
    buttons.anchor_right = 1.0
    buttons.offset_left = -425
    buttons.offset_right = -20
    buttons.offset_top = 14
    buttons.offset_bottom = 66
    buttons.add_theme_constant_override("separation", 8)
    add_child(buttons)
    _create_button(buttons, "MẶC ĐỊNH", _reset_draft, Color("#374452"))
    _create_button(buttons, "HỦY", _cancel, Color("#745151"))
    _create_button(buttons, "LƯU", _save, Color("#28776e"))
    resized.connect(queue_redraw)
    queue_redraw()

func _create_button(row: HBoxContainer, caption: String, action: Callable, fill: Color) -> void:
    var b := Button.new()
    b.text = caption
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    b.custom_minimum_size.y = 51
    b.add_theme_font_size_override("font_size", 17)
    var style := StyleBoxFlat.new()
    style.bg_color = fill
    style.set_corner_radius_all(9)
    style.set_content_margin_all(9)
    b.add_theme_stylebox_override("normal", style)
    b.pressed.connect(action)
    row.add_child(b)

func _current_layout() -> Dictionary:
    return Layout.build(size, Game.control_scale, Game.left_fire, hud.safe_insets, draft)

func _positions() -> Dictionary:
    var l := _current_layout()
    var result: Dictionary = l.points.duplicate()
    result["move"] = l.joystick
    return result

func _draw() -> void:
    if size.x <= 0 or size.y <= 0:
        return
    draw_rect(Rect2(Vector2.ZERO, size), BG)
    var font: Font = ThemeDB.fallback_font
    if theme != null and theme.default_font != null:
        font = theme.default_font
    draw_string(font, Vector2(22, 34), "TÙY CHỈNH NÚT • ONIROAI", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color.WHITE)
    draw_string(font, Vector2(22, 61), "Chạm giữ và kéo từng nút tới vị trí muốn dùng", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, GOLD)
    draw_string(font, Vector2(22, size.y - 20), "Vị trí được lưu cho các lần chơi sau   •   Chọn LƯU để xác nhận", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#b1c4c8"))
    var points := _positions()
    var layout: Dictionary = _current_layout()
    for action in points:
        var at: Vector2 = points[action]
        var radius: float = layout.joy_radius * 0.58 if action == "move" else float(layout.radii[action]) * 0.72
        radius = clampf(radius, 22, 67)
        var focused: bool = action == dragging
        var col: Color = BLUE if action.begins_with("lean") or action == "move" else GOLD
        draw_circle(at, radius, Color(0.025, 0.09, 0.105, 0.92))
        draw_arc(at, radius, 0.0, TAU, 52, col if focused else col.darkened(0.15), 4 if focused else 2, true)
        draw_line(at + Vector2(-10, 0), at + Vector2(10, 0), col, 1.6, true)
        draw_line(at + Vector2(0, -10), at + Vector2(0, 10), col, 1.6, true)
        var caption: String = NAMES.get(action, action)
        var width: float = font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
        draw_string(font, at + Vector2(-width * 0.5, radius + 18), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)

func _hit_test(pos: Vector2) -> String:
    var points := _positions()
    var layout: Dictionary = _current_layout()
    var best := ""
    var best_distance := INF
    for action in points:
        var radius: float = layout.joy_radius if action == "move" else float(layout.radii[action])
        var d: float = points[action].distance_to(pos)
        if d < radius and d < best_distance:
            best = action
            best_distance = d
    return best

func _drag_at(pos: Vector2) -> void:
    if dragging.is_empty():
        return
    var safe: Rect2 = _current_layout().safe
    var at := pos.clamp(safe.position + Vector2(28, 28), safe.end - Vector2(28, 28))
    draft[dragging] = Vector2((at.x - safe.position.x) / safe.size.x, (at.y - safe.position.y) / safe.size.y)
    queue_redraw()

func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed and touch_id == -1:
            dragging = _hit_test(event.position)
            if not dragging.is_empty():
                touch_id = event.index
        elif not event.pressed and event.index == touch_id:
            touch_id = -1
            dragging = ""
        queue_redraw()
        accept_event()
    elif event is InputEventScreenDrag:
        if event.index == touch_id:
            _drag_at(event.position)
            accept_event()
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and touch_id == -1:
        mouse_is_down = event.pressed
        dragging = _hit_test(event.position) if mouse_is_down else ""
        queue_redraw()
        accept_event()
    elif event is InputEventMouseMotion and mouse_is_down and touch_id == -1:
        _drag_at(event.position)
        accept_event()

func _reset_draft() -> void:
    draft.clear()
    dragging = ""
    queue_redraw()

func _save() -> void:
    Game.custom_controls = draft.duplicate(true)
    Game.apply_settings()
    hud.cached_layout.clear()
    _close()

func _cancel() -> void:
    _close()

func _close() -> void:
    hud.editor = null
    queue_free()
    hud._settings()
