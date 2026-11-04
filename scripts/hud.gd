extends CanvasLayer

const UI = preload("res://scripts/ui_style.gd")
const TouchScript = preload("res://scripts/touch_ui.gd")
var world: Node3D
var root: Control
var overlay: Control
var panel: VBoxContainer
var stats: Label
var mission: Label
var notification: Label
var fps: Label
var timer: float = 0.0
var notice_time: float = 0
var hit_time: float = 0
var hurt_alpha: float = 0
var was_playing: bool = false
var touches: Dictionary = {}
var joy_id: int = -1
var look_id: int = -1
var joy_origin: = Vector2.ZERO
var joy_vector: = Vector2.ZERO

func _ready() -> void :
	root = Control.new()
	root.set_script(TouchScript)
	root.hud = self
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UI.theme()
	var font: = load("res://assets/fonts/DejaVuSans.ttf") as Font
	if font:
		root.theme.default_font = font
	add_child(root)
	stats = UI.label("", 22)
	stats.position = Vector2(40, 24)
	stats.add_theme_color_override("font_shadow_color", Color.BLACK)
	stats.add_theme_constant_override("shadow_offset_y", 2)
	root.add_child(stats)
	mission = UI.label("", 16, UI.GOLD)
	mission.position = Vector2(40, 58)
	root.add_child(mission)
	fps = UI.label("", 14, UI.MINT)
	fps.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	fps.position = Vector2(-180, 28)
	root.add_child(fps)
	notification = UI.label("", 20, UI.GOLD)
	notification.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	notification.position = Vector2(-450, 100)
	notification.size = Vector2(900, 60)
	root.add_child(notification)
	overlay = CenterContainer.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)
	_main_menu()

func _make_panel() -> void :
	for child in overlay.get_children():
		overlay.remove_child(child)
		child.queue_free()
	var frame: = PanelContainer.new()
	frame.custom_minimum_size.x = 560
	overlay.add_child(frame)
	panel = VBoxContainer.new()
	panel.add_theme_constant_override("separation", 12)
	frame.add_child(panel)
	overlay.show()

func _button(text: String, action: Callable) -> Button:
	var b: = Button.new()
	b.text = text
	b.custom_minimum_size.y = 48
	b.pressed.connect(action)
	panel.add_child(b)
	return b

func _main_menu() -> void :
	_make_panel()
	panel.add_child(UI.label("MINHQUAN  /  SURVIVAL 01", 14, UI.MINT))
	panel.add_child(UI.label("TIỀN ĐỒN", 48))
	panel.add_child(UI.label("3D • GÓC NHÌN THỨ NHẤT • OFFLINE", 14, UI.GOLD))
	var description: = UI.label("Thu thập 3 lõi năng lượng trong khu rừng.\nĐến đèn hiệu phía bắc để thoát khỏi cuộc truy sát.", 17)
	panel.add_child(description)
	_button("BẮT ĐẦU SINH TỒN", world.start_run)
	_button("ĐỒ HỌA & ĐIỀU KHIỂN", _settings)
	_button("NGUỒN MODEL & HƯỚNG DẪN", _credits)

func start_game() -> void :
	overlay.hide()
	clear_controls()

func notify(text: String, duration: float) -> void :
	notification.text = text
	notice_time = duration

func show_hit(headshot: bool) -> void :
	hit_time = 0.17
	if headshot:
		notify("TRÚNG ĐẦU", 0.6)

func damage_flash() -> void :
	hurt_alpha = 0.35

func _process(delta: float) -> void :
	timer += delta
	notice_time = maxf(0, notice_time - delta)
	hit_time = maxf(0, hit_time - delta)
	hurt_alpha = maxf(0, hurt_alpha - delta * 0.9)
	notification.visible = notice_time > 0 and world.playing
	if timer > 0.15:
		timer = 0
		stats.text = "♥ %03d     %02d / %03d     HẠ GỤC %d" % [ceili(world.player.health), world.player.ammo, world.player.reserve, world.kills]
		mission.text = "LÕI %d / 3   •   %02d:%02d   •   %s" % [world.cores, int(world.elapsed) / 60, int(world.elapsed) % 60, "ĐẾN ĐÈN HIỆU PHÍA BẮC" if world.cores >= 3 else "THU THẬP NĂNG LƯỢNG"]
		fps.text = "%d FPS  •  %s" % [Engine.get_frames_per_second(), ["NHẸ", "CÂN BẰNG", "ĐẸP"][Game.quality]]
	stats.visible = world.playing
	mission.visible = world.playing
	root.queue_redraw()

func toggle_pause() -> void :
	if world.playing:
		world.playing = false
		was_playing = true
		clear_controls()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_pause_menu()
	elif was_playing:
		_resume()

func _pause_menu() -> void :
	_make_panel()
	panel.add_child(UI.label("TẠM DỪNG", 36))
	_button("TIẾP TỤC", _resume)
	_button("CÀI ĐẶT", _settings)
	_button("CHƠI LẠI", world.start_run)
	_button("VỀ MÀN HÌNH CHÍNH", func():
		was_playing = false
		world.preview.current = true
		_main_menu())

func _resume() -> void :
	was_playing = false
	overlay.hide()
	world.playing = true
	if not OS.has_feature("mobile"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _settings() -> void :
	_make_panel()
	panel.add_child(UI.label("CÀI ĐẶT", 32))
	panel.add_child(UI.label("Đồ họa: giảm nếu máy nóng hoặc FPS thấp", 16, UI.GOLD))
	var option: = OptionButton.new()
	for name_text in ["NHẸ • ưu tiên tốc độ, tắt bóng/cỏ", "CÂN BẰNG • độ phân giải 80%, có bóng", "ĐẸP • độ phân giải đầy đủ, khử răng cưa"]:
		option.add_item(name_text)
	option.selected = Game.quality
	option.custom_minimum_size.y = 44
	option.item_selected.connect( func(index: int):
		Game.quality = index
		world.apply_quality())
	panel.add_child(option)
	panel.add_child(UI.label("Độ nhạy xoay camera", 16))
	var slider: = HSlider.new()
	slider.min_value = 0.001
	slider.max_value = 0.008
	slider.step = 0.00025
	slider.value = Game.sensitivity
	slider.custom_minimum_size.y = 32
	slider.value_changed.connect( func(value: float):
		Game.sensitivity = value
		Game.apply_settings())
	panel.add_child(slider)
	var sound_switch: = CheckButton.new()
	sound_switch.text = "Âm thanh"
	sound_switch.button_pressed = Game.audio_enabled
	sound_switch.toggled.connect( func(value: bool):
		Game.audio_enabled = value
		Game.apply_settings())
	panel.add_child(sound_switch)
	_button("QUAY LẠI", _pause_menu if was_playing else _main_menu)

func _credits() -> void :
	_make_panel()
	panel.add_child(UI.label("ĐIỀU KHIỂN", 30))
	panel.add_child(UI.label("Trái: joystick di chuyển. Phải: kéo để nhìn.\nGiữ BẮN • NGẮM • NHẢY • CHẠY • THAY ĐẠN.\nMáy tính: WASD, chuột, Space, Shift, R, Esc.", 17))
	panel.add_child(UI.label("MODEL & ÂM THANH", 22, UI.GOLD))
	panel.add_child(UI.label("Kenney • Blaster Kit, Nature Kit, City Kit, Tower Defense\nKay Lousberg • KayKit Skeletons (nhân vật & hoạt ảnh)\nGiấy phép CC0 • Font DejaVu: giấy phép kèm mã nguồn.", 15))
	_button("QUAY LẠI", _main_menu)

func show_result(won: bool) -> void :
	was_playing = false
	clear_controls()
	_make_panel()
	panel.add_child(UI.label("THOÁT KHỎI TIỀN ĐỒN" if won else "BẠN ĐÃ GỤC", 32, UI.MINT if won else UI.GOLD))
	panel.add_child(UI.label("%d hạ gục  •  %d giây  •  %d / 3 lõi\nKỷ lục: %d hạ gục" % [world.kills, int(world.elapsed), world.cores, Game.best], 20))
	_button("CHƠI LẠI", world.start_run)
	_button("MÀN HÌNH CHÍNH", func():
		world.preview.current = true
		_main_menu())

func clear_controls() -> void :
	touches.clear()
	joy_id = -1
	look_id = -1
	joy_vector = Vector2.ZERO
	world.player.move_input = Vector2.ZERO
	world.player.fire_held = false
	world.player.running = false
	world.player.aiming = false

func joy_center() -> Vector2:
	return Vector2(135, root.size.y - 130)

func control_positions() -> Dictionary:
	var w: = root.size.x
	var h: = root.size.y
	return {"fire": Vector2(w - 115, h - 145), "aim": Vector2(w - 240, h - 160), "reload": Vector2(w - 115, h - 40), "jump": Vector2(w - 55, h - 290), "run": Vector2(285, h - 70), "pause": Vector2(w - 45, 75)}

func _input(event: InputEvent) -> void :
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		toggle_pause()
	if not world.playing:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			var points: = control_positions()
			var action: = ""
			for key in points:
				var radius: = 53 if key == "fire" else 37
				if event.position.distance_to(points[key]) < radius:
					action = key
					break
			if action.is_empty() and event.position.x < root.size.x * 0.4 and event.position.y > root.size.y * 0.45 and joy_id == -1:
				joy_id = event.index
				joy_origin = event.position
				action = "move"
			elif action.is_empty() and event.position.x > root.size.x * 0.4 and look_id == -1:
				look_id = event.index
				action = "look"
			touches[event.index] = action
			_action(action, true)
		else:
			var action: String = touches.get(event.index, "")
			_action(action, false)
			touches.erase(event.index)
			if event.index == joy_id:
				joy_id = -1
				joy_vector = Vector2.ZERO
				world.player.move_input = Vector2.ZERO
			if event.index == look_id:
				look_id = -1
	elif event is InputEventScreenDrag:
		if event.index == joy_id:
			joy_vector = ((event.position - joy_origin) / 65.0).limit_length(1.0)
			world.player.move_input = joy_vector
		elif event.index == look_id:
			world.player.look(event.relative)

func _action(action: String, down: bool) -> void :
	match action:
		"fire": world.player.fire_held = down
		"aim": world.player.aiming = down
		"run": world.player.running = down
		"jump":
			if down: world.player.jump()
		"reload":
			if down: world.player.reload_weapon()
		"pause":
			if down: toggle_pause()

func _notification(what: int) -> void :
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(world) and world.playing:
		toggle_pause()
