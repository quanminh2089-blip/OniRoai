extends "res://scripts/hud.gd"

var press_fx: Dictionary = {}
var held_fx: Dictionary = {}
var visual_joy: = Vector2.ZERO
var fire_vector: = Vector2.ZERO
var visual_fire: = Vector2.ZERO
var tab: int = 0
var enter_tween: Tween
var sprint_locked = false
var last_hit_headshot = false
var damage_source = Vector3.INF
var damage_time = 0.0
var kill_feed: Array[Dictionary] = []
var safe_insets = Vector4.ZERO
var safe_clock = 0.0
var cached_layout: Dictionary = {}
var cached_size = Vector2.ZERO
var cached_scale = -1.0
var cached_left_fire = false
var cached_custom: Dictionary = {}
var editor: Control
var ammo_fx = 0.0
var score_fx = 0.0
var ammo_snapshot = -1
var score_snapshot = Vector2i(-1, -1)
const DrawScript = preload("res://scripts/oniroai_controls.gd")
const Layout = preload("res://scripts/mobile_layout.gd")

func _ready() -> void :
	super._ready()
	root.set_script(DrawScript)
	root.hud = self
	root.theme.default_font = load("res://assets/fonts/DejaVuSans.ttf")
	stats.hide()
	mission.hide()
	fps.hide()
	notification.hide()

func _process(delta: float) -> void :
	super._process(delta)
	stats.hide()
	mission.hide()
	fps.hide()
	notification.hide()
	visual_joy = visual_joy.lerp(joy_vector, 1 - exp( - delta * 18))
	visual_fire = visual_fire.lerp(fire_vector, 1 - exp( - delta * 20))
	ammo_fx = maxf(0, ammo_fx - delta * 7)
	score_fx = maxf(0, score_fx - delta * 3)
	if ammo_snapshot != world.player.ammo:
		if ammo_snapshot >= 0 and world.player.ammo < ammo_snapshot: ammo_fx = 1
		ammo_snapshot = world.player.ammo
	var next_score = Vector2i(world.score[0], world.score[1])
	if next_score != score_snapshot: score_snapshot = next_score;score_fx = 1
	damage_time = maxf(0, damage_time - delta)
	for entry in kill_feed.duplicate():
		entry.life -= delta
		if entry.life <= 0: kill_feed.erase(entry)
	safe_clock -= delta
	if safe_clock <= 0:
		safe_clock = 1.0
		_safe_area()
	if world.playing and sprint_locked and (world.player.aiming or world.player.fire_held or world.player.crouching or world.player.reload_time > 0 or world.player.heal_time > 0):
		sprint_locked = false
		world.player.running = false
		_sync_movement()
	for action in control_positions().keys() + ["ammo"]:
		press_fx[action] = maxf(0, float(press_fx.get(action, 0)) - delta * 3.8)
		var active: bool = touches.values().has(action) or (action == "lean_left" and world.player.lean_direction == -1) or (action == "lean_right" and world.player.lean_direction == 1) or (action == "aim" and world.player.aiming) or (action == "crouch" and world.player.crouching) or (action == "run" and sprint_locked) or (action == "heal" and world.player.heal_time > 0)
		held_fx[action] = move_toward(float(held_fx.get(action, 0)), 1.0 if active else 0.0, delta * 9)

func _place(full: bool) -> void :
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not full:
		overlay.anchor_right = 0
		overlay.offset_left = layout().safe.position.x + 18
		overlay.offset_right = overlay.offset_left + 580

func _make_panel() -> void :
	super._make_panel()
	panel.add_theme_constant_override("separation", 12)
	panel.get_parent().custom_minimum_size.x = 580
	if is_instance_valid(enter_tween): enter_tween.kill()
	panel.modulate.a = 0
	enter_tween = create_tween()
	enter_tween.tween_property(panel, "modulate:a", 1.0, 0.18)

func _button(text: String, action: Callable) -> Button:
	var button: = super._button(text, action)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.text = "   " + text + "   ›"
	button.custom_minimum_size.y = 62
	button.mouse_entered.connect( func():
		var tween: = button.create_tween()
		tween.tween_property(button, "self_modulate", Color("f1d2a0"), 0.12))
	button.mouse_exited.connect( func():
		var tween: = button.create_tween()
		tween.tween_property(button, "self_modulate", Color.WHITE, 0.12))
	return button

func _main_menu() -> void :
	_place(false)
	_make_panel()
	panel.get_parent().add_theme_stylebox_override("panel", UI.box(Color(0.04, 0.05, 0.06, 0.78), 2, Color(0.5, 0.55, 0.58, 0.25)))
	var avatar = TextureRect.new()
	avatar.texture = load("res://assets/oniroai/avatar.png")
	avatar.custom_minimum_size = Vector2(70, 70)
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var brand = HBoxContainer.new()
	brand.add_theme_constant_override("separation", 18)
	brand.add_child(avatar)
	var title = UI.label("OniRoai", 48)
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	brand.add_child(title)
	panel.add_child(brand)
	panel.add_child(UI.label("1 ĐẤU 4  •  500 MÁU  •  THÂN -10 / ĐẦU -250  •  CHẠM 4 ĐIỂM", 13, Color("91a0a8")))
	var line: = HSeparator.new()
	panel.add_child(line)
	panel.add_child(UI.label("THUNG LŨNG — TRẠM 04\nHạ cả 4 đối thủ để thắng ván. Dùng vật chắn để sống sót.", 16, Color("bac2c6")))
	var start: = _button("BẮT ĐẦU TRẬN", world.start_run)
	start.add_theme_stylebox_override("normal", UI.box(Color("605039"), 2, UI.GOLD))
	_button("THIẾT LẬP", _settings)
	_button("HƯỚNG DẪN & THÔNG TIN", _credits)
	panel.add_child(UI.label("MP5 A5   •   ĐIỀU KHIỂN MOBILE   •   " + Game.VERSION, 12, Color("8b999f")))

func _pause_menu() -> void :
	_place(false)
	_make_panel()
	panel.add_child(UI.label("TRẬN ĐẤU ĐANG TẠM DỪNG", 12, UI.GOLD))
	panel.add_child(UI.label("TẠM DỪNG", 36))
	_button("TIẾP TỤC", _resume)
	_button("THIẾT LẬP", _settings)
	_button("CHƠI LẠI TRẬN", world.start_run)
	_button("VỀ MÀN HÌNH CHÍNH", world.return_to_menu)

func toggle_pause() -> void :
	if not world.in_match: return
	if world.paused: _resume()
	else:
		was_playing = true
		world.set_paused(true)
		_pause_menu()

func _resume() -> void :
	was_playing = false
	overlay.hide()
	world.set_paused(false)
	if not OS.has_feature("mobile"): Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _notification(what: int) -> void :
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(world) and world.in_match and not world.paused:
		toggle_pause()

func _settings() -> void :
	_place(true)
	_make_panel()
	panel.get_parent().custom_minimum_size.x = minf(1000, root.size.x - 80)
	panel.add_child(UI.label("THIẾT LẬP", 28))
	var tabs: = HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	panel.add_child(tabs)
	var names: Array[String] = ["HÌNH ẢNH", "NÚT BẤM", "NGẮM & AI", "ÂM THANH"]
	for i in range(4):
		var b: = Button.new()
		b.text = names[i]
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 54
		if i == tab: b.add_theme_stylebox_override("normal", UI.box(Color("443d30"), 2, UI.GOLD))
		b.pressed.connect( func():
			tab = i
			_settings())
		tabs.add_child(b)
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = 330
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var body: = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	scroll.add_child(body)
	match tab:
		0:
			body.add_child(UI.label("CHẤT LƯỢNG HÌNH ẢNH", 13, UI.GOLD))
			var levels: = HBoxContainer.new()
			levels.add_theme_constant_override("separation", 10)
			body.add_child(levels)
			var labels: Array[String] = ["THẤP\nƯu tiên tốc độ", "CÂN BẰNG\nBóng và vật liệu", "CAO\nĐầy đủ chi tiết"]
			for i in range(3):
				var b: = Button.new()
				b.text = labels[i]
				b.custom_minimum_size = Vector2(286, 84)
				if Game.quality == i: b.add_theme_stylebox_override("normal", UI.box(Color("453c2e"), 2, UI.GOLD))
				b.pressed.connect( func():
					Game.quality = i
					world.apply_quality()
					_settings())
				levels.add_child(b)
			_check(body, "Hiện bộ đếm FPS", Game.show_fps, func(value: bool):
				Game.show_fps = value
				Game.apply_settings())
			body.add_child(UI.label("Chọn THẤP nếu máy nóng hoặc chuyển động chưa mượt.", 14, Color("8f9ca4")))
		1:
			body.add_child(UI.label("BỐ CỤC NGHIÊNG TRÁI / PHẢI", 13, UI.GOLD))
			body.add_child(UI.label("Nút nghiêng nằm ngay phía trên joystick. Chạm một lần để nghiêng, chạm lại để đứng thẳng.", 15, Color("9ca9af")))
			var edit_button := Button.new()
			edit_button.text = "✥  TÙY CHỈNH VỊ TRÍ NÚT (KÉO & THẢ)"
			edit_button.custom_minimum_size.y = 60
			edit_button.add_theme_stylebox_override("normal", UI.box(Color("294e4f"), 6, Color("54d2ba")))
			edit_button.pressed.connect(_edit_controls)
			body.add_child(edit_button)
			_slider(body, "Cỡ nút bấm", Game.control_scale, 0.85, 1.2, 0.05, func(value: float):
				Game.control_scale = value
				Game.apply_settings())
			_slider(body, "Độ rõ nút cảm ứng", Game.control_opacity, 0.35, 1.0, 0.05, func(value: float):
				Game.control_opacity = value
				Game.apply_settings())
			_check(body, "Hiện nút bắn bên trái", Game.left_fire, func(value: bool):
				clear_controls()
				Game.left_fire = value
				Game.apply_settings())
			_check(body, "Joystick nổi theo vị trí chạm", Game.floating_joystick, func(value: bool):
				Game.floating_joystick = value
				Game.apply_settings())
			_check(body, "Đẩy joystick lên xa để khóa chạy", Game.auto_sprint, func(value: bool):
				Game.auto_sprint = value
				Game.apply_settings())
			var reset = Button.new()
			reset.text = "ĐẶT LẠI BỐ CỤC MOBILE"
			reset.custom_minimum_size.y = 54
			reset.pressed.connect( func():
				Game.control_scale = 1.05
				Game.control_opacity = 0.82
				Game.left_fire = true
				Game.floating_joystick = false
				Game.auto_sprint = true
				Game.custom_controls.clear()
				cached_layout.clear()
				Game.apply_settings()
				_settings())
			body.add_child(reset)
		2:
			body.add_child(UI.label("ĐỘ KHÓ CỦA ĐỘI MÁY", 13, UI.GOLD))
			var difficulty = OptionButton.new()
			for title in ["DỄ — phản ứng chậm, bắn thưa", "VỪA — phản ứng và độ tản cân bằng", "KHÓ — phản ứng nhanh, bắn chính xác hơn"]: difficulty.add_item(title)
			difficulty.selected = Game.bot_difficulty
			difficulty.custom_minimum_size.y = 58
			difficulty.item_selected.connect( func(index: int):
				Game.bot_difficulty = index
				Game.apply_settings())
			body.add_child(difficulty)
			_slider(body, "Độ nhạy xoay", Game.sensitivity, 0.001, 0.008, 0.00025, func(value: float):
				Game.sensitivity = value
				Game.apply_settings())
			_slider(body, "Độ nhạy khi ngắm", Game.ads_sensitivity, 0.2, 0.85, 0.05, func(value: float):
				Game.ads_sensitivity = value
				Game.apply_settings())
			_slider(body, "Độ rung camera", Game.camera_motion, 0.0, 1.0, 0.1, func(value: float):
				Game.camera_motion = value
				Game.apply_settings())
			_check(body, "Chạm để bật / tắt ống ngắm", Game.aim_toggle, func(value: bool):
				Game.aim_toggle = value
				Game.apply_settings())
		3:
			_check(body, "Âm thanh game", Game.audio_enabled, func(value: bool):
				Game.audio_enabled = value
				Game.apply_settings())
			body.add_child(UI.label("Âm thanh súng, bước chân và thao tác được xử lý riêng.\nChỉnh âm lượng bằng phím âm lượng trên điện thoại.", 15, Color("9ca9af")))
	_button("ÁP DỤNG & QUAY LẠI", _pause_menu if was_playing else _main_menu)

func _edit_controls() -> void:
	if is_instance_valid(editor):
		return
	# Giữ nguyên thế giới đang tạm dừng, nhưng cho phép kéo các nút trên HUD.
	overlay.hide()
	editor = Control.new()
	editor.set_script(preload("res://scripts/control_layout_editor.gd"))
	editor.hud = self
	root.add_child(editor)
	editor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _check(parent: Control, text: String, value: bool, callback: Callable) -> void :
	var check: = CheckButton.new()
	check.text = text
	check.button_pressed = value
	check.custom_minimum_size.y = 58
	check.toggled.connect(callback)
	parent.add_child(check)

func _slider(parent: Control, text: String, value: float, low: float, high: float, step: float, callback: Callable) -> void :
	var row: = HBoxContainer.new()
	parent.add_child(row)
	var label: = UI.label(text, 18)
	label.custom_minimum_size.x = 250
	row.add_child(label)
	var slider: = HSlider.new()
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size.y = 54
	slider.min_value = low
	slider.max_value = high
	slider.step = step
	slider.value = value
	slider.value_changed.connect(callback)
	row.add_child(slider)
	var percent = high >= 0.2 and high <= 1.2
	var number = UI.label("%d%%" % roundi(value * 100) if percent else "%.4f" % value, 16, UI.GOLD)
	number.custom_minimum_size.x = 90
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	slider.value_changed.connect( func(v: float): number.text = "%d%%" % roundi(v * 100) if percent else "%.4f" % v)
	row.add_child(number)

func _credits() -> void :
	_place(true)
	_make_panel()
	panel.get_parent().custom_minimum_size.x = 900
	panel.add_child(UI.label("ĐIỀU KHIỂN & NGUỒN TÀI NGUYÊN", 25))
	panel.add_child(UI.label("1 bạn đấu 4 NPC. Mỗi bên 500 HP: bắn thân -10, bắn đầu -250.\nHạ hết đội kia: +1 điểm. Đội chạm 4 điểm thắng trận.\nJoystick trái: đi. Cần phải: giữ bắn, kéo để ngắm.\nChạm ô súng phía trên phải để nạp đạn.\nCác nút giữa dưới: CÚI / NHẢY.\nNPC nghe tiếng súng, tìm đường và bắn khi nhìn thấy bạn.", 17))
	panel.add_child(UI.label("MODEL / VẬT LIỆU", 13, UI.GOLD))
	panel.add_child(UI.label("MP5: Rotuma  •  Tay FPS: DJMaesen / bumstrum, rig ccransh\nỐng ngắm: Argentavisss  •  Nhân vật: BAMEN\nHoạt ảnh: Quaternius, 100STYLE  •  Đá / PBR: Poly Haven\nCây: musdasch / Yughues / para (OpenGameArt).\nCC BY 4.0 / CC0. Chi tiết nguồn nằm trong mã nguồn.", 14, Color("a5afb5")))
	_button("QUAY LẠI", _main_menu)

func show_match_result(won: bool) -> void :
	was_playing = false
	clear_controls()
	_place(false)
	_make_panel()
	panel.add_child(UI.label("KẾT QUẢ TRẬN ĐẤU  /  1 ĐẤU 4", 12, UI.GOLD))
	panel.add_child(UI.label("CHIẾN THẮNG" if won else "THẤT BẠI", 35, Color("91cce6") if won else UI.GOLD))
	panel.add_child(UI.label("%d  :  %d" % [world.score[0], world.score[1]], 58))
	panel.add_child(UI.label("%d VÁN   •   %02d HẠ GỤC   •   %02d:%02d\nTỔNG: %d THẮNG / %d TRẬN" % [world.round_number, world.kills, int(world.total_elapsed) / 60, int(world.total_elapsed) % 60, Game.match_wins, Game.matches_played], 17, Color("bac2c6")))
	_button("TRẬN MỚI", world.start_run)
	_button("VỀ MÀN HÌNH CHÍNH", world.return_to_menu)

func layout() -> Dictionary:
	var view = root.size if root.size.x > 0 else get_viewport().get_visible_rect().size
	if cached_layout.is_empty() or view != cached_size or Game.control_scale != cached_scale or Game.left_fire != cached_left_fire or Game.custom_controls != cached_custom:
		cached_size = view
		cached_scale = Game.control_scale
		cached_left_fire = Game.left_fire
		cached_custom = Game.custom_controls.duplicate(true)
		cached_layout = Layout.build(view, Game.control_scale, Game.left_fire, safe_insets, Game.custom_controls)
	return cached_layout

func _safe_area() -> void :
	if not OS.has_feature("mobile") or DisplayServer.get_name() == "headless": return
	var safe = DisplayServer.get_display_safe_area()
	var physical = Vector2(get_window().size)
	if safe.size.x <= 0 or physical.x <= 0 or safe.size.x < safe.size.y: return
	var factor = root.size / physical
	var insets = Vector4(maxf(safe.position.x, 0) * factor.x, maxf(safe.position.y, 0) * factor.y, maxf(physical.x - safe.end.x, 0) * factor.x, maxf(physical.y - safe.end.y, 0) * factor.y)
	if safe_insets != insets:
		safe_insets = insets
		cached_layout.clear()

func control_positions() -> Dictionary: return layout().points
func control_radius(action: String) -> float: return float(layout().radii.get(action, 0))
func joy_center() -> Vector2: return layout().joystick

func clear_controls() -> void :
	super.clear_controls()
	sprint_locked = false
	visual_joy = Vector2.ZERO
	fire_vector = Vector2.ZERO
	visual_fire = Vector2.ZERO

func start_game() -> void :
	super.start_game()
	was_playing = false
	kill_feed.clear()
	damage_time = 0

func show_hit(headshot: bool) -> void :
	last_hit_headshot = headshot
	super.show_hit(headshot)

func show_damage_from(source: Vector3) -> void :
	damage_source = source
	damage_time = 1.5

func report_kill(headshot: bool, bot_name: String = "ĐỎ") -> void :
	kill_feed.push_front({"headshot": headshot, "life": 4.0, "count": world.kills, "name": bot_name})
	if kill_feed.size() > 3: kill_feed.pop_back()

func _sync_movement() -> void :
	world.player.move_input = joy_vector if joy_id >= 0 else (Vector2(0, -1) if sprint_locked else Vector2.ZERO)

func _joystick_move(position: Vector2) -> void :
	var raw = (position - joy_origin) / float(layout().joy_travel)
	var length = raw.length()
	joy_vector = raw.normalized() * clampf((length - 0.1) / 0.9, 0, 1) if length > 0.1 else Vector2.ZERO
	if raw.y > 0.3: sprint_locked = false
	if Game.auto_sprint and raw.y < -1.35 and absf(raw.x) < 0.6 and not world.player.crouching and not world.player.aiming and not world.player.fire_held: sprint_locked = true
	_sync_movement()

func _input(event: InputEvent) -> void :
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		toggle_pause()
		return
	if not world.playing:
		if world.in_match and not world.paused and event is InputEventScreenTouch and event.pressed:
			if event.position.distance_to(control_positions().pause) <= control_radius("pause"): toggle_pause()
		return
	if event is InputEventScreenTouch:
		if event.pressed and not event.canceled:
			var action: String = ""
			if layout().ammo.has_point(event.position): action = "ammo"
			else:
				for key in control_positions():
					var radius: float = control_radius(key)
					if event.position.distance_to(control_positions()[key]) <= radius:
						action = key
						break
			if action.is_empty() and layout().move_zone.has_point(event.position) and joy_id == -1:
				action = "move"
				joy_id = event.index
				joy_origin = event.position if Game.floating_joystick else joy_center()
				if Game.floating_joystick:
					var r = float(layout().joy_radius)
					joy_origin = joy_origin.clamp(layout().safe.position + Vector2(r, r), layout().safe.end - Vector2(r, r))
				_joystick_move(event.position)
			elif action.is_empty() and event.position.x > root.size.x * 0.4 and look_id == -1:
				action = "look"
				look_id = event.index
			touches[event.index] = action
			if action == "fire": fire_vector = ((event.position - control_positions().fire) / control_radius("fire")).limit_length(1)
			if not action.is_empty(): press_fx[action] = 1.0
			if action in ["fire", "fire_left", "aim", "crouch", "heal"]: sprint_locked = false
			if action == "aim" and Game.aim_toggle:
				world.player.heal_time = 0
				world.player.aiming = not world.player.aiming
			elif action == "jump": world.player.jump()
			elif action == "ammo": world.player.reload_weapon()
			elif action == "crouch": world.player.toggle_crouch()
			elif action == "lean_left": world.player.toggle_lean(-1)
			elif action == "lean_right": world.player.toggle_lean(1)
			elif action == "run":
				sprint_locked = not sprint_locked
				if sprint_locked:
					if world.player.crouching: world.player.toggle_crouch()
					world.player.aiming = false
					world.player.heal_time = 0
			elif action == "heal":
				_sync_movement()
				world.player.heal()
			elif action == "pause": toggle_pause()
		else:
			if event.canceled: sprint_locked = false
			if touches.get(event.index, "") == "fire": fire_vector = Vector2.ZERO
			touches.erase(event.index)
			if event.index == joy_id:
				joy_id = -1
				joy_vector = Vector2.ZERO
			if event.index == look_id: look_id = -1
		_sync_movement()
		_held_actions()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if event.index == joy_id:
			_joystick_move(event.position)
			_held_actions()
		elif event.index == look_id or touches.get(event.index, "") == "fire":
			if touches.get(event.index, "") == "fire": fire_vector = ((event.position - control_positions().fire) / control_radius("fire")).limit_length(1)
			var physical = not event.screen_relative.is_zero_approx()
			world.player.look(event.screen_relative if physical else event.relative, physical)
		get_viewport().set_input_as_handled()

func _held_actions() -> void :
	world.player.fire_held = (touches.values().has("fire") or touches.values().has("fire_left")) and world.playing
	if world.player.fire_held or world.player.aiming or world.player.crouching: sprint_locked = false
	world.player.running = sprint_locked and world.playing and world.player.reload_time <= 0 and world.player.heal_time <= 0
	if not Game.aim_toggle: world.player.aiming = touches.values().has("aim") and world.playing
	_sync_movement()
