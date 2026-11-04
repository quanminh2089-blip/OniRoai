extends CanvasLayer
## Chức năng hỗ trợ riêng trong OniRoai (Godot), không đụng tới game/app khác.
const ACCENT := Color("#4ceac6")
const DARK := Color("#101724")
const MUTED := Color("#9badb9")

var bubble: TextureButton
var popup: PanelContainer
var scrim: ColorRect
var esp_surface: Control
var activated := false

func _ready() -> void:
    layer = 120
    var canvas := Control.new()
    canvas.name = "OverlayRoot"
    canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(canvas)

    esp_surface = Control.new()
    esp_surface.name = "EnemyESP"
    esp_surface.set_script(preload("res://scripts/esp_renderer.gd"))
    esp_surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    esp_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
    canvas.add_child(esp_surface)

    scrim = ColorRect.new()
    scrim.color = Color(0.0, 0.015, 0.03, 0.66)
    scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    scrim.mouse_filter = Control.MOUSE_FILTER_STOP
    scrim.hide()
    canvas.add_child(scrim)
    scrim.gui_input.connect(_on_scrim_input)

    bubble = TextureButton.new()
    bubble.name = "MinhQuanBubble"
    bubble.texture_normal = load("res://assets/minhquan/bubble_avatar.png")
    bubble.ignore_texture_size = true
    bubble.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
    bubble.custom_minimum_size = Vector2(76, 76)
    bubble.size = Vector2(76, 76)
    bubble.tooltip_text = "MINHQUAN • ESP / AIM ĐẦU"
    bubble.mouse_filter = Control.MOUSE_FILTER_STOP
    bubble.hide()
    canvas.add_child(bubble)
    bubble.pressed.connect(_open)

    popup = PanelContainer.new()
    popup.name = "MinhQuanMenu"
    popup.custom_minimum_size = Vector2(440, 0)
    popup.add_theme_stylebox_override("panel", _style(DARK, 23, Color("#38546a"), 22))
    popup.hide()
    canvas.add_child(popup)
    var col := VBoxContainer.new()
    col.add_theme_constant_override("separation", 13)
    popup.add_child(col)

    var heading := HBoxContainer.new()
    heading.add_theme_constant_override("separation", 12)
    col.add_child(heading)
    var title := _label("MINHQUAN  /  ONIROAI", 21, ACCENT)
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    heading.add_child(title)
    var close := Button.new()
    close.text = "✕"
    close.custom_minimum_size = Vector2(40, 40)
    close.add_theme_stylebox_override("normal", _style(Color("#203042"), 12, Color("#496073"), 8))
    close.pressed.connect(_close)
    heading.add_child(close)

    var info := _label("HỖ TRỢ NGẮM  •  TÙY CHỌN TRONG GAME", 13, MUTED)
    col.add_child(info)
    _feature(col, "ESP ĐỊCH", "Khung viền, vị trí đầu và khoảng cách", "esp", Game.esp_enabled)
    _feature(col, "AIM ĐẦU", "Hỗ trợ khóa đầu khi ngắm hoặc bắn", "aim", Game.head_aim_enabled)

    var foot := _label("Bắn thân: -10 HP   •   Bắn đầu: -250 HP", 13, Color("#d5dce5"))
    foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    col.add_child(foot)
    get_viewport().size_changed.connect(_reposition)
    _reposition()

func _style(fill: Color, radius: int, border: Color, pad: int = 14) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = fill
    style.set_corner_radius_all(radius)
    style.set_border_width_all(1)
    style.border_color = border
    style.content_margin_left = pad
    style.content_margin_right = pad
    style.content_margin_top = pad
    style.content_margin_bottom = pad
    return style

func _label(value: String, font_size: int, tint: Color) -> Label:
    var label := Label.new()
    label.text = value
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", tint)
    return label

func _feature(parent: VBoxContainer, title: String, hint: String, key: String, enabled: bool) -> void:
    var card := PanelContainer.new()
    card.add_theme_stylebox_override("panel", _style(Color("#1c2a38"), 15, Color("#355066")))
    parent.add_child(card)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 9)
    card.add_child(row)

    var marker := _label("◎", 26, ACCENT)
    row.add_child(marker)
    var text_col := VBoxContainer.new()
    text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    text_col.add_theme_constant_override("separation", 6)
    row.add_child(text_col)
    text_col.add_child(_label(title, 18, Color.WHITE))
    text_col.add_child(_label(hint, 12, MUTED))

    var toggle := CheckButton.new()
    toggle.button_pressed = enabled
    toggle.text = "BẬT" if enabled else "TẮT"
    toggle.custom_minimum_size.x = 96
    toggle.add_theme_color_override("font_color", ACCENT)
    toggle.add_theme_font_size_override("font_size", 15)
    row.add_child(toggle)
    toggle.toggled.connect(func(on: bool):
        if key == "esp":
            Game.esp_enabled = on
        elif key == "aim":
            Game.head_aim_enabled = on
        toggle.text = "BẬT" if on else "TẮT"
        toggle.add_theme_color_override("font_color", ACCENT if on else MUTED)
        Game.apply_settings()
        if is_instance_valid(esp_surface): esp_surface.queue_redraw()
    )

func show_in_game() -> void:
    activated = true
    if is_instance_valid(bubble): bubble.show()
    _reposition()

func _reposition() -> void:
    if not is_instance_valid(bubble) or not is_instance_valid(popup): return
    var viewport := get_viewport().get_visible_rect().size
    bubble.position = Vector2(maxf(12.0, viewport.x - 98.0), maxf(12.0, viewport.y * 0.37))
    popup.size = Vector2.ZERO
    # Căn giữa theo kích thước gần đúng; độ rộng panel 440.
    popup.position = Vector2(maxf(12.0, (viewport.x - 440.0) * 0.5), maxf(12.0, (viewport.y - 332.0) * 0.5))

func _on_scrim_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        _close()
    elif event is InputEventScreenTouch and event.pressed:
        _close()

func _open() -> void:
    if not activated: return
    scrim.show()
    popup.show()
    bubble.hide()
    _reposition()

func _close() -> void:
    popup.hide()
    scrim.hide()
    if activated: bubble.show()
