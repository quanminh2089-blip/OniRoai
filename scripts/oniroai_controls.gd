extends Control
const Art = preload("res://scripts/oniroai_art.gd")
const WHITE = Color("e4eaeb")
const MUTED = Color("a9b7ba")
const BLUE = Color("83d6de")
const GOLD = Color("edba73")
var hud: CanvasLayer
var gradient: GradientTexture2D
func text(value: String, p: Vector2, px: int, color: Color = WHITE, center: bool = false) -> void :
	var font: Font = theme.default_font if theme and theme.default_font else ThemeDB.fallback_font
	var width = font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	var at = p - Vector2(width * 0.5 if center else 0, 0)
	draw_string(font, at + Vector2(0, 1), value, HORIZONTAL_ALIGNMENT_LEFT, -1, px, Color(0, 0, 0, 0.8))
	draw_string(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, px, color)
func picture(id: String, rect: Rect2, alpha: float = 1, tint: Color = Color.WHITE) -> void :
	draw_texture_rect(Art.sprite(id), rect, false, Color(tint, alpha))
func disc(id: String, p: Vector2, r: float, alpha: float = 1, tint: Color = Color.WHITE) -> void :
	picture(id, Rect2(p - Vector2.ONE * r, Vector2.ONE * r * 2), alpha, tint)
func _draw() -> void :
	if not is_instance_valid(hud): return
	var world = hud.world
	if not world.in_match or world.paused:
		if gradient == null:
			gradient = GradientTexture2D.new();gradient.width = 512;gradient.height = 2
			var ramp = Gradient.new();ramp.colors = PackedColorArray([Color(0.01, 0.02, 0.025, 0.88), Color(0.01, 0.02, 0.025, 0)])
			gradient.gradient = ramp
		draw_texture_rect(gradient, Rect2(Vector2.ZERO, size), false)
		text("OniRoai  /  " + Game.VERSION, Vector2(size.x - 205, size.y - 26), 12, MUTED)
		return
	var player = world.player
	var center = size * 0.5
	var ads: float = player.weapon_rig.ads_blend
	if world.playing:
		if ads > 0.15: _scope(center, ads)
		else:
			var gap: float = 4 + player.shot_spread() * 270 + player.recoil * 6
			for d in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]: draw_line(center + d * gap, center + d * (gap + 5), Color(WHITE, 0.9), 1.5, true)
	if hud.hit_time > 0:
		for d in [Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]: draw_line(center + d * 9, center + d * 16, GOLD if hud.last_hit_headshot else WHITE, 2, true)
		if hud.last_hit_headshot: text("HEADSHOT  -250", center + Vector2(0, 43), 14, GOLD, true)
	if hud.hurt_alpha > 0:
		draw_rect(Rect2(Vector2.ONE * 4, size - Vector2.ONE * 8), Color(0.7, 0.07, 0.04, hud.hurt_alpha), false, 8)
	if hud.damage_time > 0 and hud.damage_source.is_finite():
		var delta: Vector3 = hud.damage_source - player.global_position
		var bearing = atan2(delta.x, - delta.z) + player.rotation.y - PI / 2
		draw_arc(center, 83, bearing - 0.24, bearing + 0.24, 24, Color(1, 0.28, 0.15, minf(hud.damage_time, 0.85)), 4, true)
	_scoreboard()
	_ammo_card()
	_health_bar()
	_joystick()
	for action in hud.control_positions(): _button(action, hud.control_positions()[action])
	for i in range(hud.kill_feed.size()):
		var entry: Dictionary = hud.kill_feed[i]
		var p: Vector2 = hud.layout().ammo.end + Vector2(-10, 26 + i * 23)
		text("BẠN  ›  " + entry.name + ("  ·  TRÚNG ĐẦU" if entry.headshot else ""), p - Vector2(250, 0), 12, GOLD if entry.headshot else WHITE)
	if Game.show_fps: text("%d FPS" % Engine.get_frames_per_second(), hud.layout().safe.position + Vector2(84, 39), 12, MUTED)
	_phase_overlay(center)
func _scoreboard() -> void :
	var world = hud.world
	var rect: Rect2 = hud.layout().score
	var pop = 1 + hud.score_fx * 0.025
	rect = Rect2(rect.get_center() - rect.size * pop * 0.5, rect.size * pop)
	picture("score", rect)
	var u = rect.size.x / 400
	var y = rect.position.y
	var left = rect.position.x + rect.size.x * 0.25
	var right = rect.position.x + rect.size.x * 0.75
	text("BẠN", Vector2(left - 40 * u, y + 24 * u), roundi(12 * u), BLUE, true)
	text(str(world.score[0]), Vector2(left + 27 * u, y + 58 * u), roundi(34 * u), WHITE, true)
	text("ĐỘI MÁY", Vector2(right + 32 * u, y + 24 * u), roundi(12 * u), GOLD, true)
	text(str(world.score[1]), Vector2(right - 30 * u, y + 58 * u), roundi(34 * u), WHITE, true)
	text("●" if world.player.health > 0 else "○", Vector2(left - 40 * u, y + 48 * u), roundi(10 * u), BLUE, true)
	text("●".repeat(world.alive_bots()) + "○".repeat(4 - world.alive_bots()), Vector2(right + 32 * u, y + 48 * u), roundi(9 * u), GOLD, true)
	text("VÁN %d  /  CHẠM 4" % world.round_number, Vector2(size.x * 0.5, rect.end.y + 17 * u), roundi(11 * u), MUTED, true)
func _ammo_card() -> void :
	var player = hud.world.player
	var rect: Rect2 = hud.layout().ammo
	var u = rect.size.x / 320
	var press: float = hud.held_fx.get("ammo", 0)
	var scale_value = 1 - press * 0.018
	var card = Rect2(rect.get_center() - rect.size * scale_value * 0.5, rect.size * scale_value)
	picture("ammo", card, 1, Color.WHITE.lerp(Color("d3e8eb"), press))
	var gun = Rect2(card.position + Vector2(20, 18) * u, Vector2(185, 76) * u)
	gun.position += Vector2( - hud.ammo_fx * 3, - hud.ammo_fx * 2) * u
	if player.reload_time > 0:
		gun.position.y += sin((1 - player.reload_time / player.RELOAD_DURATION) * TAU) * 2 * u
	picture("mp5", gun, 0.96)
	text("%02d" % player.ammo, card.position + Vector2(262, 48) * u, roundi(31 * u), GOLD if player.ammo < 6 else WHITE, true)
	text("/ %03d" % player.reserve, card.position + Vector2(264, 68) * u, roundi(14 * u), MUTED, true)
	text("MP5 A5", card.position + Vector2(31, 96) * u, roundi(11 * u), MUTED)
	var message = "CHẠM NẠP ĐẠN"
	if player.reload_time > 0: message = "ĐANG NẠP  %.1f s" % player.reload_time
	elif player.ammo <= 0: message = "HẾT ĐẠN · CHẠM NẠP"
	text(message, card.position + Vector2(202, 96) * u, roundi(10 * u), GOLD, true)
	if player.reload_time > 0:
		var value = clampf(1 - player.reload_time / player.RELOAD_DURATION, 0, 1)
		picture("rail", Rect2(card.position + Vector2(34, 100) * u, Vector2(250 * value, 3) * u), 0.9, BLUE)
func _health_bar() -> void :
	var player = hud.world.player
	var p: Vector2 = hud.layout().safe.position + Vector2(0, 86)
	var total: float = player.MAX_HEALTH
	draw_rect(Rect2(p, Vector2(223, 50)), Color(0.035, 0.055, 0.073, 0.85))
	text("MÁU  %03d / %03d" % [ceili(player.health), int(total)], p + Vector2(10, 22), 16, WHITE)
	draw_rect(Rect2(p + Vector2(10, 32), Vector2(203, 8)), Color("36434a"))
	draw_rect(Rect2(p + Vector2(10, 32), Vector2(203 * clampf(player.health / total, 0, 1), 8)), BLUE if player.health > 100 else Color("ee655a"))

func _scope(center: Vector2, blend: float) -> void :

	var color = Color("e38d56");color.a = blend
	draw_line(center + Vector2(-5, 0), center + Vector2(5, 0), color, 1.2, true)
	draw_line(center + Vector2(0, -5), center + Vector2(0, 5), color, 1.2, true)
	draw_circle(center, 1.5, Color(1, 0.35, 0.16, blend))
func _joystick() -> void :
	var base: Vector2 = hud.joy_origin if hud.joy_id >= 0 else hud.joy_center()
	var r: float = hud.layout().joy_radius
	var a = lerpf(0.65, 1, Game.control_opacity)
	disc("joy_base", base, r, a)
	var thumb: Vector2 = base + hud.visual_joy * r * 0.59
	disc("joy_thumb", thumb + Vector2(0, 2), r * 0.43, a)
func _button(action: String, p: Vector2) -> void :
	var r: float = hud.control_radius(action)
	var active: float = hud.held_fx.get(action, 0)
	var alpha = lerpf(0.6, 1, Game.control_opacity)
	if action == "fire":
		disc("fire_base", p, r, alpha)
		var thumb: Vector2 = p + hud.visual_fire * r * 0.54 + Vector2(0, active * 2)
		disc("fire_thumb", thumb, r * (0.44 - active * 0.025), alpha, Color.WHITE.lerp(Color("ffe2b0"), active * 0.25))
		return
	if action == "lean_left" or action == "lean_right":
		var direction: float = -1.0 if action == "lean_left" else 1.0
		var selected = (hud.world.player.lean_direction == -1 and action == "lean_left") or (hud.world.player.lean_direction == 1 and action == "lean_right")
		var tone: Color = BLUE if selected else WHITE
		draw_circle(p, r, Color(0.025, 0.045, 0.06, alpha * 0.85))
		draw_arc(p, r - 2, 0, TAU, 56, tone, 2.8 if selected else 1.7, true)
		draw_circle(p + Vector2(direction * 8, -12), 5.3, tone)
		draw_line(p + Vector2(direction * 8, -5), p + Vector2(-direction * 2, 12), tone, 4, true)
		draw_line(p + Vector2(-direction * 2, 12), p + Vector2(-direction * 11, 17), tone, 3, true)
		draw_line(p + Vector2(-direction * 2, 12), p + Vector2(direction * 9, 17), tone, 3, true)
		draw_line(p + Vector2(direction * 3, 1), p + Vector2(direction * 16, 0), tone, 2.6, true)
		text("NGHIÊNG TRÁI" if action == "lean_left" else "NGHIÊNG PHẢI", p + Vector2(0, r + 14), 11, tone, true)
		return
	var id = "fire_thumb" if action == "fire_left" else action
	var pulse: float = hud.press_fx.get(action, 0)
	disc(id, p + Vector2(0, active * 2), r * (1 - active * 0.07 + pulse * 0.025), alpha, Color.WHITE.lerp(Color("cce6e7"), active * 0.2))
	if action == "pause": return
	var label = {"fire_left": "BẮN", "aim": "NGẮM", "crouch": "ĐỨNG" if hud.world.player.crouching else "CÚI", "jump": "NHẢY", "run": "DỪNG CHẠY" if hud.sprint_locked else "CHẠY"}
	text(label[action], p + Vector2(0, r + 14), 11, MUTED, true)
func _phase_overlay(center: Vector2) -> void :
	var world = hud.world
	if world.phase == world.Phase.COUNTDOWN:
		text("VÁN %d  /  CHUẨN BỊ" % world.round_number, center + Vector2(0, -78), 15, GOLD, true)
		text(str(maxi(1, ceili(world.phase_time))), center + Vector2(0, 10), 76, WHITE, true)
	elif world.phase == world.Phase.ROUND_OVER:
		var rect = Rect2(center - Vector2(255, 85), Vector2(510, 170))
		picture("ammo", rect)
		text("THẮNG VÁN" if world.round_winner == 0 else "THUA VÁN", center + Vector2(-40, -22), 28, BLUE if world.round_winner == 0 else GOLD, true)
		text("%d : %d" % [world.score[0], world.score[1]], center + Vector2(-40, 20), 32, WHITE, true)
		var final_round = world.score[0] >= 4 or world.score[1] >= 4
		text("KẾT THÚC TRẬN" if final_round else "VÁN TIẾP THEO · %d" % maxi(1, ceili(world.phase_time)), center + Vector2(-40, 55), 12, MUTED, true)
