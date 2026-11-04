extends Control
const UI = preload("res://scripts/ui_style.gd")
const Art = preload("res://scripts/oniroai_art.gd")
var status: Label
var detail: Label
var progress: TextureProgressBar
var retry: Button
var background: TextureRect
var spinner: TextureRect
var curtain: Control
var asset_index = 0
var loading = false
var current_path = ""
var clock = 0.0
var target_progress = 0.0
var displayed_progress = 0.0
var finished = false
var intro: Tween
func _ready() -> void :
	theme = UI.theme()
	theme.default_font = load("res://assets/fonts/DejaVuSans.ttf")
	background = TextureRect.new();background.texture = Art.sprite("loading")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE;background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(background)
	curtain = Control.new();curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(curtain)
	var row = VBoxContainer.new();row.name = "Brand";row.position = Vector2(70, 90);row.custom_minimum_size = Vector2(540, 0);row.add_theme_constant_override("separation", 14);curtain.add_child(row)
	var avatar = TextureRect.new();avatar.texture = Art.sprite("avatar");avatar.custom_minimum_size = Vector2(132, 132);avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE;avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED;avatar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN;row.add_child(avatar)
	row.add_child(UI.label("OniRoai", 68, Color("e5ecea")))
	row.add_child(UI.label("MỘT MÌNH. BỐN ĐỐI THỦ.", 15, Color("ddb57b")))
	var box = Control.new();box.name = "LoadingCard";box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT);box.position = Vector2(65, size.y - 170);box.size = Vector2(550, 125);curtain.add_child(box)
	var frame = TextureRect.new();frame.texture = Art.sprite("ammo");frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE;frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);box.add_child(frame)
	status = UI.label("Đang chuẩn bị…", 18, Color("dbe7e5"));status.position = Vector2(35, 27);box.add_child(status)
	detail = UI.label("0%", 13, Color("a4c5c7"));detail.position = Vector2(35, 54);box.add_child(detail)
	progress = TextureProgressBar.new();progress.texture_progress = Art.sprite("rail");progress.nine_patch_stretch = true;progress.max_value = 100;progress.step = 0.01;progress.position = Vector2(35, 91);progress.size = Vector2(470, 4);progress.tint_progress = Color("81d2d5");box.add_child(progress)
	spinner = TextureRect.new();spinner.texture = Art.sprite("joy_base");spinner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE;spinner.position = Vector2(456, 26);spinner.size = Vector2(48, 48);spinner.pivot_offset = Vector2(24, 24);box.add_child(spinner)
	retry = Button.new();retry.text = "THỬ LẠI";retry.position = Vector2(250, 40);retry.size = Vector2(150, 50);retry.hide();retry.pressed.connect(_begin);box.add_child(retry)
	resized.connect(_layout)
	_layout()
	curtain.modulate.a = 0
	background.scale = Vector2.ONE * 1.035
	intro = create_tween().set_parallel(true)
	intro.tween_property(curtain, "modulate:a", 1, 0.6)
	intro.tween_property(background, "scale", Vector2.ONE, 3.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	call_deferred("_begin")
func _layout() -> void :
	if background: background.pivot_offset = size * 0.5
	if curtain:
		var s = clampf(size.y / 720.0, 0.75, 1.0)
		var brand = curtain.get_node_or_null("Brand")
		if brand: brand.position = Vector2(65, 60) * s;brand.scale = Vector2.ONE * s
		var card = curtain.get_node_or_null("LoadingCard")
		if card: card.position = Vector2(65 * s, size.y - 166 * s);card.scale = Vector2.ONE * s
func _begin() -> void :
	retry.hide();finished = false;loading = true;asset_index = 0;target_progress = 0;status.text = "Đang nạp cảnh vật…";_next_asset()
func _next_asset() -> void :
	if asset_index >= Game.ASSET_PATHS.size():
		loading = false;current_path = "";target_progress = 100;status.text = "Đang dựng chiến trường…";call_deferred("_enter_arena");return
	current_path = Game.ASSET_PATHS[asset_index]
	if ResourceLoader.load_threaded_request(current_path) != OK: _fail("Không mở được dữ liệu game trong APK.")
func _process(delta: float) -> void :
	clock += delta
	if spinner: spinner.rotation = clock * 1.5
	displayed_progress = move_toward(displayed_progress, target_progress, delta * 90)
	if progress: progress.value = displayed_progress
	if detail and not retry.visible: detail.text = "%d%%  /  NGOẠI TUYẾN" % roundi(displayed_progress)
	if not loading or current_path.is_empty(): return
	var state = ResourceLoader.load_threaded_get_status(current_path)
	if state == ResourceLoader.THREAD_LOAD_LOADED:
		Game.assets[current_path.get_file()] = ResourceLoader.load_threaded_get(current_path)
		asset_index += 1;target_progress = 100.0 * asset_index / Game.ASSET_PATHS.size();_next_asset()
	elif state == ResourceLoader.THREAD_LOAD_FAILED or state == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE: _fail("Không mở được dữ liệu game trong APK.")
func _enter_arena() -> void :
	if finished: return
	finished = true
	if DisplayServer.get_name() != "headless": await get_tree().create_timer(maxf(0, 2.0 - clock)).timeout
	var arena = Node3D.new();arena.set_script(load("res://scripts/arena.gd"));get_tree().root.add_child(arena);get_tree().current_scene = arena
	if DisplayServer.get_name() != "headless":
		Game.hud.root.hide()
		status.text = "Sẵn sàng";displayed_progress = 100;progress.value = 100
		await get_tree().process_frame
		var exit = create_tween();exit.tween_property(self, "modulate:a", 0, 0.3); await exit.finished
		Game.hud.root.show()
	queue_free()
func _fail(message: String) -> void :
	loading = false;status.text = "Chưa thể vào game";detail.text = message;retry.show()
