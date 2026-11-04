extends Control
var hud: CanvasLayer
const WHITE: = Color("dfe5e8")
const MUTED: = Color("a8b7bf")
const ACCENT: = Color("d9ac65")
var menu_gradient: GradientTexture2D

func text(value: String, point: Vector2, size_value: int, color: Color = WHITE, center: bool = false) -> void :
	var font: Font = theme.default_font if theme and theme.default_font else ThemeDB.fallback_font
	var offset: float = font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size_value).x * 0.5 if center else 0.0
	draw_string(font, point + Vector2( - offset, 1), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size_value, Color(0, 0, 0, 0.6))
	draw_string(font, point + Vector2( - offset, 0), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size_value, color)

func _draw() -> void :
	if not is_instance_valid(hud): return
	var world = hud.world
	if not world.in_match or world.paused:
		if menu_gradient == null:
			menu_gradient = GradientTexture2D.new()
			menu_gradient.width = 512
			menu_gradient.height = 2
			var gradient = Gradient.new()
			gradient.colors = PackedColorArray([Color(0.015, 0.023, 0.03, 0.88), Color(0.015, 0.023, 0.03, 0)])
			menu_gradient.gradient = gradient
		draw_texture_rect(menu_gradient, Rect2(Vector2.ZERO, size), false)
		draw_rect(Rect2(0, 0, size.x, 6), Color("151c22"))
		draw_rect(Rect2(0, size.y - 6, size.x, 6), Color("151c22"))
		text("MINHQUAN  /  " + Game.VERSION, Vector2(size.x - 205, size.y - 26), 12, MUTED)
		return
	var player: CharacterBody3D = world.player
	var area: Rect2 = hud.layout().safe
	var center = size * 0.5
	var s: float = hud.layout().scale
	if world.playing:
		var ads: float = player.weapon_rig.ads_blend
		if ads > 0.35: _scope(center, ads)
		if ads < 0.8:
			var gap: float = 5 + player.shot_spread() * 500 + player.recoil * 7
			for direction in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
				draw_line(center + direction * gap, center + direction * (gap + 7), Color(0.92, 0.95, 0.96, 0.9), 1.6, true)
			draw_circle(center, 1, WHITE)
	if hud.hit_time > 0:
		var hit_color = ACCENT if hud.last_hit_headshot else WHITE
		for d in [Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]: draw_line(center + d * 10, center + d * 18, hit_color, 2.6, true)
	if hud.hurt_alpha > 0:
		for i in range(5):
			var edge = 12.0 + float(i) * 8.0
			var color = Color(0.7, 0.08, 0.04, hud.hurt_alpha * (0.5 - float(i) * 0.08))
			draw_rect(Rect2(edge / 2, edge / 2, size.x - edge, size.y - edge), color, false, edge)
	if hud.damage_time > 0 and hud.damage_source.is_finite():
		var offset: Vector3 = hud.damage_source - player.global_position
		var bearing = atan2(offset.x, - offset.z) + player.rotation.y - PI / 2
		draw_arc(center, 87, bearing - 0.25, bearing + 0.25, 24, Color(1, 0.25, 0.16, minf(hud.damage_time, 0.9)), 6, true)
	var info = area.position + Vector2(0, 3)
	draw_style_box(load_box(), Rect2(info, Vector2(252, 87)))
	text("ĐỘI XANH  /  1 NGƯỜI", info + Vector2(14, 22), 12, Color("91cce6"))
	text("CÒN SỐNG" if player.health > 0 else "ĐÃ BỊ LOẠI", info + Vector2(14, 50), 23, WHITE)
	text("500 HP • THÂN -10 • ĐẦU -250", info + Vector2(14, 73), 11, MUTED)
	text("THUNG LŨNG  /  TRẠM 04", info + Vector2(8, 109), 12, MUTED)
	text("%02d:%02d" % [int(world.elapsed) / 60, int(world.elapsed) % 60], info + Vector2(8, 131), 15, WHITE)
	_scoreboard(area)
	_compass()
	for i in range(hud.kill_feed.size()):
		var entry: Dictionary = hud.kill_feed[i]
		var p = Vector2(area.end.x - 316, area.position.y + 110 + i * 31)
		draw_style_box(load_box(), Rect2(p - Vector2(10, 21), Vector2(270, 29)))
		text("BẠN  ·  MP5  ·  " + entry.name + ("  [ĐẦU]" if entry.headshot else ""), p, 12, ACCENT if entry.headshot else WHITE)
	if hud.notice_time > 0 and world.phase == world.Phase.LIVE:
		text(hud.get("notification").text, Vector2(size.x * 0.5, area.position.y + 177), 14, ACCENT, true)
	var ammo_pos = Vector2(size.x * 0.5, area.end.y - 213 * s)
	draw_style_box(load_box(), Rect2(ammo_pos + Vector2(-132, -38), Vector2(264, 82)))
	_weapon_icon(ammo_pos + Vector2(-110, -4))
	text("MP5 A5", ammo_pos + Vector2(-110, 29), 12, MUTED)
	text("%02d" % player.ammo, ammo_pos + Vector2(-19, 6), 36, WHITE)
	text("/ %03d" % player.reserve, ammo_pos + Vector2(47, 4), 19, MUTED)
	text("TỰ ĐỘNG  /  1 PHÁT", ammo_pos + Vector2(-19, 29), 11, ACCENT)
	if player.reload_time > 0:
		draw_rect(Rect2(ammo_pos + Vector2(-110, 38), Vector2(220, 3)), Color("3c464d"))
		draw_rect(Rect2(ammo_pos + Vector2(-110, 38), Vector2(220 * (1 - player.reload_time / player.RELOAD_DURATION), 3)), ACCENT)
		text("THAY BĂNG  %.1f s" % player.reload_time, center + Vector2(0, 96), 15, ACCENT, true)
	if Game.show_fps: text("%d FPS" % Engine.get_frames_per_second(), Vector2(area.end.x - 135, area.position.y + 38), 12, MUTED)
	_joystick()
	for action in hud.control_positions(): _button(action, hud.control_positions()[action])
	_phase_overlay(center)

func _scoreboard(area: Rect2) -> void :
	var world = hud.world
	var p = Vector2(size.x * 0.5 - 182, area.position.y)
	draw_style_box(load_box(), Rect2(p, Vector2(364, 91)))
	draw_rect(Rect2(p, Vector2(182, 3)), Color("70b3d0"))
	draw_rect(Rect2(p + Vector2(182, 0), Vector2(182, 3)), Color("c57362"))
	text("BẠN", p + Vector2(65, 22), 12, Color("91cce6"), true)
	text("ĐỘI MÁY", p + Vector2(299, 22), 12, Color("e5a392"), true)
	text(str(world.score[0]), p + Vector2(128, 55), 38, WHITE, true)
	text(":", p + Vector2(182, 51), 25, MUTED, true)
	text(str(world.score[1]), p + Vector2(235, 55), 38, WHITE, true)
	draw_circle(p + Vector2(65, 45), 4, Color("91cce6") if world.player.health > 0 else Color("4b5359"))
	for i in range(4): draw_circle(p + Vector2(278 + i * 14, 45), 4, Color("e5a392") if i < world.alive_bots() else Color("4b5359"))
	text("VÁN %d  ·  CHẠM 4" % world.round_number, p + Vector2(182, 78), 12, MUTED, true)

func _phase_overlay(center: Vector2) -> void :
	var world = hud.world
	if world.phase == world.Phase.COUNTDOWN:
		var p = center + Vector2(0, -45)
		text("VÁN %d  /  CHUẨN BỊ" % world.round_number, p + Vector2(0, -44), 16, ACCENT, true)
		text(str(maxi(1, ceili(world.phase_time))), p + Vector2(0, 40), 82, WHITE, true)
		text("Hạ cả 4 đối thủ. Bắn thân -10 HP, bắn đầu -250 HP.", p + Vector2(0, 83), 16, WHITE, true)
	elif world.phase == world.Phase.ROUND_OVER:
		var p = center + Vector2(-285, -108)
		draw_style_box(load_box(), Rect2(p, Vector2(570, 178)))
		var won = world.round_winner == 0
		text("THẮNG VÁN" if won else "THUA VÁN", p + Vector2(285, 48), 32, Color("91cce6") if won else Color("e5a392"), true)
		text("%d  :  %d" % [world.score[0], world.score[1]], p + Vector2(285, 103), 44, WHITE, true)
		var final_round = world.score[0] >= 4 or world.score[1] >= 4
		text("Kết thúc trận…" if final_round else "Ván tiếp theo sau %d giây" % maxi(1, ceili(world.phase_time)), p + Vector2(285, 145), 16, MUTED, true)

func _weapon_icon(p: Vector2) -> void :
	var color = Color("aab8bc")
	draw_rect(Rect2(p + Vector2(-2, -9), Vector2(38, 12)), color)
	draw_rect(Rect2(p + Vector2(36, -7), Vector2(29, 5)), color)
	draw_line(p + Vector2(65, -5), p + Vector2(76, -5), color, 3, true)
	draw_colored_polygon(PackedVector2Array([p + Vector2(4, 2), p + Vector2(13, 2), p + Vector2(9, 16), p + Vector2(1, 16)]), color)
	draw_colored_polygon(PackedVector2Array([p + Vector2(26, 3), p + Vector2(34, 3), p + Vector2(38, 19), p + Vector2(30, 22)]), color)
	draw_polyline(PackedVector2Array([p + Vector2(-2, -7), p + Vector2(-14, -4), p + Vector2(-14, 6)]), color, 3, true)

var panel_style: StyleBoxFlat
func load_box() -> StyleBoxFlat:
	if panel_style == null:
		panel_style = StyleBoxFlat.new()
		panel_style.bg_color = Color(0.035, 0.045, 0.055, 0.68)
		panel_style.border_color = Color(0.6, 0.68, 0.72, 0.16)
		panel_style.set_border_width_all(1)
		panel_style.border_width_left = 2
	return panel_style

func _compass() -> void :
	var heading: float = fposmod( - rad_to_deg(hud.world.player.rotation.y), 360)
	var cx = size.x * 0.5
	var y: float = hud.layout().safe.position.y + 134
	draw_line(Vector2(cx - 170, y), Vector2(cx + 170, y), Color(0.8, 0.86, 0.88, 0.22), 1, true)
	for i in range(-5, 6):
		var angle = roundi(heading / 15) * 15 + i * 15
		var x = cx + (angle - heading) * 2.4
		draw_line(Vector2(x, y - 3), Vector2(x, y + 3 if angle % 45 else y + 8), MUTED, 1, true)
		if angle % 90 == 0: text(["B", "Đ", "N", "T"][posmod(angle / 90, 4)], Vector2(x, y - 14), 12, WHITE, true)
	draw_colored_polygon(PackedVector2Array([Vector2(cx - 4, y + 15), Vector2(cx + 4, y + 15), Vector2(cx, y + 9)]), ACCENT)

func _scope(center: Vector2, blend: float) -> void :
	var alpha: = smoothstep(0.35, 0.95, blend)
	var radius: = size.y * 0.365
	var large: = maxf(size.x, size.y)
	draw_arc(center, radius + large, 0, TAU, 128, Color(0.005, 0.008, 0.01, alpha), large * 2, true)
	draw_arc(center, radius + 9, 0, TAU, 96, Color(0.08, 0.1, 0.11, alpha), 18, true)
	draw_arc(center, radius - 2, 0, TAU, 96, Color(0.55, 0.64, 0.66, alpha * 0.45), 1, true)
	draw_circle(center, radius, Color(0.08, 0.18, 0.2, alpha * 0.045))
	var color: = Color(0.02, 0.025, 0.02, alpha)
	draw_line(center + Vector2( - radius * 0.75, 0), center + Vector2(-12, 0), color, 1.2, true)
	draw_line(center + Vector2(12, 0), center + Vector2(radius * 0.75, 0), color, 1.2, true)
	draw_line(center + Vector2(0, 12), center + Vector2(0, radius * 0.76), color, 1.2, true)
	draw_colored_polygon(PackedVector2Array([center + Vector2(0, -7), center + Vector2(-4, 2), center + Vector2(4, 2)]), Color(0.72, 0.16, 0.08, alpha))
	for i in range(1, 5):
		draw_line(center + Vector2(-10 + i, 32 + i * 22), center + Vector2(10 - i, 32 + i * 22), color, 1, true)
	text("3×", center + Vector2(radius * 0.55, radius * 0.65), 12, Color(0.45, 0.55, 0.53, alpha))

func _joystick() -> void :
	var base: Vector2 = hud.joy_origin if hud.joy_id >= 0 else hud.joy_center()
	var alpha: float = Game.control_opacity
	var r: float = hud.layout().joy_radius
	draw_circle(base, r, Color(0.02, 0.04, 0.05, alpha * 0.34))
	draw_arc(base, r, 0, TAU, 72, Color(0.83, 0.89, 0.91, alpha * 0.7), 1.8, true)
	draw_arc(base, r * 0.82, 0, TAU, 64, Color(0.75, 0.81, 0.84, alpha * 0.16), 1, true)
	for dir in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		draw_line(base + dir * r * 0.88, base + dir * r, Color(0.8, 0.85, 0.87, alpha * 0.6), 2, true)
	var thumb: Vector2 = base + hud.visual_joy * r * 0.61
	var knob = r * 0.38
	draw_circle(thumb + Vector2(0, 4), knob + 2, Color(0, 0, 0, alpha * 0.2))
	draw_circle(thumb, knob, Color(0.19, 0.23, 0.25, alpha * 0.85))
	draw_arc(thumb, knob, 0, TAU, 48, Color(0.9, 0.94, 0.95, alpha * 0.85), 1.8, true)
	if hud.joy_id >= 0 and hud.visual_joy.length() > 0.15:
		draw_arc(base, r + 5, hud.visual_joy.angle() - 0.25, hud.visual_joy.angle() + 0.25, 16, ACCENT, 3, true)

func _fire_pad(p: Vector2) -> void :
	var alpha: float = Game.control_opacity
	var r: float = hud.control_radius("fire")
	var active: float = hud.held_fx.get("fire", 0)
	var color = WHITE.lerp(ACCENT, active)
	draw_circle(p, r, Color(0.02, 0.04, 0.05, alpha * 0.36))
	draw_arc(p, r, 0, TAU, 72, Color(color, alpha * 0.75), 1.9, true)
	draw_arc(p, r * 0.82, 0, TAU, 64, Color(color, alpha * 0.18), 1, true)
	for dir in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]: draw_line(p + dir * r * 0.88, p + dir * r, Color(color, alpha * 0.65), 2, true)
	var thumb: Vector2 = p + hud.visual_fire * r * 0.56
	var knob = r * (0.39 - active * 0.025)
	draw_circle(thumb + Vector2(0, 4), knob + 2, Color(0, 0, 0, alpha * 0.2))
	draw_circle(thumb, knob, Color(0.19, 0.23, 0.25, alpha * 0.85))
	draw_arc(thumb, knob, 0, TAU, 48, Color(color, alpha * 0.95), 1.9, true)
	_icon("fire", thumb, Color(color, alpha), 1.1)
	text("GIỮ BẮN / KÉO NGẮM", p + Vector2(0, r * 0.73), 11, Color(color, alpha), true)
	if active > 0.1: draw_arc(p, r + 5, hud.visual_fire.angle() - 0.28, hud.visual_fire.angle() + 0.28, 16, Color(ACCENT, active), 3, true)
	if hud.world.player.reload_time > 0:
		draw_arc(p, r + 4, - PI / 2, - PI / 2 + TAU * (1 - hud.world.player.reload_time / hud.world.player.RELOAD_DURATION), 56, ACCENT, 3, true)

func _button(action: String, p: Vector2) -> void :
	if action == "fire":
		_fire_pad(p)
		return
	var active: float = hud.held_fx.get(action, 0)
	var pulse: float = hud.press_fx.get(action, 0)
	var radius: float = hud.control_radius(action)
	var alpha: float = Game.control_opacity
	var color: = WHITE.lerp(ACCENT, active)
	color.a = alpha * (0.88 + active * 0.12)
	var scale_value: = 1 - active * 0.06
	var hit_radius = radius
	radius *= scale_value
	draw_circle(p + Vector2(0, 2), radius, Color(0, 0, 0, alpha * 0.18))
	draw_circle(p, radius, Color(0.035, 0.045, 0.055, alpha * (0.52 + active * 0.18)))
	draw_arc(p, radius, 0, TAU, 64, color, 2.1 if action == "fire" else 1.6, true)
	draw_arc(p, radius - 5, - PI * 0.8, PI * 0.2, 40, Color(color, alpha * 0.18), 1, true)
	if pulse > 0:
		draw_arc(p, radius + 8 * (1 - pulse), 0, TAU, 48, Color(ACCENT, pulse * 0.5), 1.5, true)
	var icon_scale = hit_radius / (74.0 if action == "fire" else 44.0) * scale_value
	var icon_at = p - Vector2(0, radius * 0.18) if action != "pause" else p
	_icon("fire" if action == "fire_left" else action, icon_at, color, icon_scale)
	if action != "pause":
		var names: Dictionary = {"fire": "BẮN", "fire_left": "BẮN TRÁI", "aim": "NGẮM", "reload": "NẠP ĐẠN", "jump": "NHẢY", "run": "KHÓA CHẠY" if hud.sprint_locked else "CHẠY", "crouch": "ĐỨNG" if hud.world.player.crouching else "CÚI", "heal": "CỨU ×%d" % hud.world.player.medkits}
		text(names[action], p + Vector2(0, radius * 0.58), 14 if action == "fire" else 12, Color(color, alpha * 0.95), true)
	if action in ["fire", "reload"] and hud.world.player.reload_time > 0:
		var fraction = 1 - hud.world.player.reload_time / hud.world.player.RELOAD_DURATION
		draw_arc(p, hit_radius + 4, - PI / 2, - PI / 2 + TAU * fraction, 56, ACCENT, 3, true)
	if action == "heal" and hud.world.player.medkits <= 0:
		draw_line(p + Vector2( - radius * 0.5, radius * 0.5), p + Vector2(radius * 0.5, - radius * 0.5), Color(1, 0.55, 0.4, alpha), 2, true)

func _icon(action: String, p: Vector2, color: Color, s: float) -> void :
	match action:
		"fire":
			for i in range(3):
				var shift = Vector2((i - 1) * 11, abs(i - 1) * 4) * s
				var points = PackedVector2Array([Vector2(-3, 15), Vector2(-3, -7), Vector2(0, -14), Vector2(3, -7), Vector2(3, 15), Vector2(-3, 15)])
				var transformed = PackedVector2Array()
				for point in points: transformed.append(p + shift + point.rotated(0.35) * s)
				draw_polyline(transformed, color, 1.9, true)
		"aim":
			draw_arc(p, 13 * s, 0, TAU, 32, color, 1.7, true)
			draw_line(p + Vector2(-20, 0) * s, p + Vector2(-8, 0) * s, color, 1.8, true)
			draw_line(p + Vector2(8, 0) * s, p + Vector2(20, 0) * s, color, 1.8, true)
			draw_line(p + Vector2(0, -20) * s, p + Vector2(0, -8) * s, color, 1.8, true)
			draw_line(p + Vector2(0, 8) * s, p + Vector2(0, 20) * s, color, 1.8, true)
		"reload":
			draw_arc(p, 15 * s, -2.7, 1.9, 32, color, 2, true)
			draw_colored_polygon(PackedVector2Array([p + Vector2(-14, -13) * s, p + Vector2(-4, -15) * s, p + Vector2(-12, -4) * s]), color)
			draw_rect(Rect2(p + Vector2(-3, -8) * s, Vector2(6, 17) * s), color, false, 1.5)
		"run":
			for y in [-5, 5]:
				draw_polyline(PackedVector2Array([p + Vector2(-11, y + 5) * s, p + Vector2(0, y - 4) * s, p + Vector2(11, y + 5) * s]), color, 2, true)
		"jump":
			draw_polyline(PackedVector2Array([p + Vector2(-11, 0) * s, p + Vector2(0, -12) * s, p + Vector2(11, 0) * s]), color, 2, true)
			draw_line(p + Vector2(0, -10) * s, p + Vector2(0, 12) * s, color, 2, true)
			draw_line(p + Vector2(-10, 15) * s, p + Vector2(10, 15) * s, color, 1.5, true)
		"crouch":
			draw_circle(p + Vector2(-4, -12) * s, 4 * s, color)
			draw_polyline(PackedVector2Array([p + Vector2(-4, -6) * s, p + Vector2(3, 3) * s, p + Vector2(15, 3) * s]), color, 3 * s, true)
			draw_polyline(PackedVector2Array([p + Vector2(1, 2) * s, p + Vector2(-11, 8) * s, p + Vector2(-2, 16) * s, p + Vector2(9, 16) * s]), color, 3 * s, true)
			draw_line(p + Vector2(-1, -2) * s, p + Vector2(11, -6) * s, color, 2.5 * s, true)
		"heal":
			draw_rect(Rect2(p + Vector2(-5, -16) * s, Vector2(10, 32) * s), color)
			draw_rect(Rect2(p + Vector2(-16, -5) * s, Vector2(32, 10) * s), color)
		"pause":
			draw_line(p + Vector2(-5, -8), p + Vector2(-5, 8), color, 3, true)
			draw_line(p + Vector2(5, -8), p + Vector2(5, 8), color, 3, true)
