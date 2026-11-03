extends Control

const FREE_KEY := "FreeKey_MinhQuan"
const ORIGINAL_GAME_SCENE := "res://scenes/boot.tscn"

var input_key: LineEdit
var info: Label
var open_button: Button
var avatar: TextureRect
var background: TextureRect
var loading := false

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _make_ui()
    get_viewport().size_changed.connect(_relayout)
    _relayout()

func _make_ui() -> void:
    background = TextureRect.new()
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    background.texture = load("res://assets/oniroai/key_panel.png")
    add_child(background)

    var tint := ColorRect.new()
    tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    tint.color = Color(0.025, 0.04, 0.075, 0.78)
    add_child(tint)

    var center := CenterContainer.new()
    center.name = "Center"
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(center)

    var card := PanelContainer.new()
    card.name = "Card"
    card.custom_minimum_size = Vector2(410, 0)
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.065, 0.105, 0.15, 0.94)
    style.border_color = Color(0.31, 0.76, 0.85, 0.82)
    style.set_border_width_all(2)
    style.set_corner_radius_all(20)
    style.set_content_margin_all(18)
    card.add_theme_stylebox_override("panel", style)
    center.add_child(card)

    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 8)
    card.add_child(column)

    avatar = TextureRect.new()
    avatar.custom_minimum_size = Vector2(82, 82)
    avatar.texture = load("res://assets/oniroai/avatar.png")
    var round_shader := load("res://assets/oniroai/round_avatar.gdshader") as Shader
    if round_shader != null:
        var avatar_material := ShaderMaterial.new()
        avatar_material.shader = round_shader
        avatar.material = avatar_material
    avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    avatar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    column.add_child(avatar)

    var heading := Label.new()
    heading.text = "ONIROAI"
    heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    heading.add_theme_font_size_override("font_size", 25)
    heading.add_theme_color_override("font_color", Color(0.77, 0.95, 1.0))
    column.add_child(heading)

    var caption := Label.new()
    caption.text = "ĐĂNG NHẬP KEY • OFFLINE"
    caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    caption.add_theme_font_size_override("font_size", 12)
    column.add_child(caption)

    input_key = LineEdit.new()
    input_key.placeholder_text = "Nhập key để bắt đầu"
    input_key.custom_minimum_size.y = 44
    input_key.secret = false
    input_key.text_submitted.connect(func(_v: String) -> void: _unlock())
    column.add_child(input_key)

    open_button = Button.new()
    open_button.text = "VÀO GAME"
    open_button.custom_minimum_size.y = 44
    open_button.pressed.connect(_unlock)
    column.add_child(open_button)

    info = Label.new()
    info.text = "Nhập key miễn phí để mở game"
    info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    info.add_theme_font_size_override("font_size", 12)
    column.add_child(info)

func _relayout() -> void:
    var card := get_node_or_null("Center/Card") as Control
    if card != null:
        # Scale the card down on short/wide Android phone displays.
        var viewport_size := get_viewport_rect().size
        var scale_factor: float = minf(1.0, minf((viewport_size.x - 28.0) / 440.0,
                                                (viewport_size.y - 24.0) / 335.0))
        card.scale = Vector2.ONE * maxf(0.5, scale_factor)
        card.pivot_offset = card.size / 2.0

func _unlock() -> void:
    if loading:
        return
    if input_key.text.strip_edges() != FREE_KEY:
        info.text = "Key không đúng. Vui lòng nhập lại."
        info.add_theme_color_override("font_color", Color(1.0, 0.52, 0.52))
        return
    loading = true
    input_key.editable = false
    open_button.disabled = true
    info.text = "Đang tải trò chơi..."
    background.texture = load("res://assets/oniroai/loading.png")
    info.add_theme_color_override("font_color", Color(0.57, 1.0, 0.83))
    avatar.pivot_offset = avatar.size / 2.0
    var spinner := create_tween().set_loops()
    spinner.tween_property(avatar, "rotation", TAU, 1.35).from(0.0)
    var delay := get_tree().create_timer(1.55)
    delay.timeout.connect(_launch_original_game)

func _launch_original_game() -> void:
    if not ResourceLoader.exists(ORIGINAL_GAME_SCENE):
        info.text = "Không tìm thấy màn hình game gốc."
        return
    get_tree().change_scene_to_file(ORIGINAL_GAME_SCENE)
