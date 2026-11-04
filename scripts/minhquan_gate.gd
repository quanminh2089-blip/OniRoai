extends Control
## MinhQuan v0.9 — landscape UI; the local key/account are demo-only.
const FREE_KEY := "FreeKey_MinhQuan"
const USER_NAME := "MinhQuan08"
const PASSWORD := "08112008ok"
const BG := Color("#070d19")
const PANEL := Color("#171f2d")
const FIELD := Color("#10151f")
const MINT := Color("#39e3ae")
const WHITE := Color("#f4f5f9")
const MUTED := Color("#a6b0c2")
var phase := "loading"
var seconds := 0
var counter: Label
var key_input: LineEdit
var user_input: LineEdit
var password_input: LineEdit
var message: Label
var center: CenterContainer
var loading_avatar: TextureRect

func _ready() -> void:
    theme = Theme.new()
    var bg := ColorRect.new()
    bg.color = BG
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    center = CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(center)
    _show_loading()

func _clear() -> void:
    for child in center.get_children():
        center.remove_child(child)
        child.queue_free()

func _style(fill: Color, radius: int = 20, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = fill
    s.set_corner_radius_all(radius)
    s.set_border_width_all(1 if border.a > 0.0 else 0)
    s.border_color = border
    s.content_margin_left = 14
    s.content_margin_right = 14
    s.content_margin_top = 12
    s.content_margin_bottom = 12
    return s

func _label(value: String, size: int, tint: Color = WHITE) -> Label:
    var l := Label.new()
    l.text = value
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", tint)
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    return l

func _column(width: float = 410.0, gap: int = 11) -> VBoxContainer:
    var v := VBoxContainer.new()
    v.custom_minimum_size.x = width
    v.add_theme_constant_override("separation", gap)
    return v

func _panel(width: float, height: float, color: Color = PANEL) -> PanelContainer:
    var p := PanelContainer.new()
    p.custom_minimum_size = Vector2(width, height)
    p.add_theme_stylebox_override("panel", _style(color, 23, Color("#303b4b")))
    return p

func _avatar(size_px: int) -> TextureRect:
    var img := TextureRect.new()
    img.texture = load("res://assets/minhquan/avatar.png")
    img.custom_minimum_size = Vector2(size_px, size_px)
    img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    img.size = Vector2(size_px, size_px)
    img.pivot_offset = Vector2(size_px / 2.0, size_px / 2.0)
    return img

func _center_avatar(size_px: int) -> CenterContainer:
    var c := CenterContainer.new()
    c.add_child(_avatar(size_px))
    return c

func _button(caption: String, tint: Color, handler: Callable) -> Button:
    var b := Button.new()
    b.text = caption
    b.custom_minimum_size.y = 48
    b.add_theme_font_size_override("font_size", 18)
    b.add_theme_color_override("font_color", WHITE if tint != MINT else BG)
    b.add_theme_stylebox_override("normal", _style(tint, 11))
    b.add_theme_stylebox_override("hover", _style(tint.lightened(0.12), 11))
    b.add_theme_stylebox_override("pressed", _style(tint.darkened(0.13), 11))
    b.pressed.connect(handler)
    return b

func _input(hint: String, secret: bool = false) -> LineEdit:
    var f := LineEdit.new()
    f.placeholder_text = hint
    f.secret = secret
    f.custom_minimum_size.y = 48
    f.add_theme_font_size_override("font_size", 17)
    f.add_theme_color_override("font_color", WHITE)
    f.add_theme_color_override("font_placeholder_color", MUTED)
    f.add_theme_stylebox_override("normal", _style(FIELD, 10, Color("#354457")))
    f.add_theme_stylebox_override("focus", _style(FIELD, 10, MINT))
    return f

func _show_loading() -> void:
    phase = "loading"
    _clear()
    var card := _panel(315, 155, Color("#2c2928"))
    center.add_child(card)
    var col := _column(280, 6)
    card.add_child(col)
    var avatar_holder := CenterContainer.new()
    col.add_child(avatar_holder)
    loading_avatar = _avatar(74)
    avatar_holder.add_child(loading_avatar)
    col.add_child(_label("Loading data from Server...", 17))
    _spin()
    await get_tree().create_timer(3.0).timeout
    if is_inside_tree() and phase == "loading":
        _show_key()

func _spin() -> void:
    if phase != "loading" or not is_instance_valid(loading_avatar):
        return
    var t := create_tween()
    t.tween_property(loading_avatar, "rotation", TAU, 1.25).from(0.0)
    t.tween_callback(_spin)

func _show_key() -> void:
    phase = "key"
    _clear()
    var card := _panel(460, 0, Color("#342f2e"))
    center.add_child(card)
    var col := _column(420, 9)
    card.add_child(col)
    col.add_child(_center_avatar(82))
    col.add_child(_label("MinhQuan'z", 29))
    col.add_child(_label("Bấm Vào Nút Get Key Để Lấy Key Free", 15))
    counter = _label("-1s", 15, MUTED)
    col.add_child(counter)
    key_input = _input("Nhập Key")
    col.add_child(key_input)
    var actions := HBoxContainer.new()
    actions.add_theme_constant_override("separation", 9)
    col.add_child(actions)
    var get_key := _button("Get Key", Color("#a9343e"), func(): key_input.text = FREE_KEY)
    get_key.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    actions.add_child(get_key)
    var ok := _button("OK", Color("#3475b7"), _check_key)
    ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    actions.add_child(ok)
    message = _label("", 14, Color("#ff9c9c"))
    col.add_child(message)
    col.add_child(_label("Admin: Nguyễn Minh Quân", 14, MUTED))
    col.add_child(_label("Zalo: 0899174526", 14, MUTED))
    col.add_child(_label("Telegram: @mquan08", 14, MUTED))
    seconds = 0
    _tick_key()

func _tick_key() -> void:
    while is_inside_tree() and phase == "key":
        seconds += 1
        if is_instance_valid(counter):
            counter.text = "-%ds" % seconds
        await get_tree().create_timer(1.0).timeout

func _check_key() -> void:
    if key_input.text.strip_edges() != FREE_KEY:
        message.text = "Key không đúng"
        return
    phase = "game"
    MinhQuanOverlay.show_in_game()
    get_tree().change_scene_to_file("res://scenes/boot.tscn")

