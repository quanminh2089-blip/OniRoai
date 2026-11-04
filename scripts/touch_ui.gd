extends Control
var hud: CanvasLayer

func _draw() -> void :
	if not is_instance_valid(hud) or not hud.world.playing:
		return
	var center: = size * 0.5
	var ink: = Color(0.93, 0.96, 0.88, 0.85)
	for axis in [Vector2.RIGHT, Vector2.DOWN]:
		draw_line(center - axis * 10, center - axis * 4, ink, 1.5, true)
		draw_line(center + axis * 4, center + axis * 10, ink, 1.5, true)
	draw_circle(center, 1.3, ink)
	if hud.hit_time > 0:
		for dir in [Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]:
			draw_line(center + dir * 8, center + dir * 15, Color("efc383"), 2, true)
	if hud.hurt_alpha > 0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.85, 0.14, 0.08, hud.hurt_alpha))

	var base: Vector2 = hud.joy_origin if hud.joy_id >= 0 else hud.joy_center()
	draw_circle(base, 70, Color(0.03, 0.1, 0.13, 0.35))
	draw_arc(base, 70, 0, TAU, 64, Color(0.8, 0.92, 0.9, 0.4), 1.5, true)
	draw_circle(base + hud.joy_vector * 44, 27, Color(0.78, 0.92, 0.86, 0.35))
	var font: = get_theme_default_font()
	var labels: = {"fire": "BẮN", "aim": "NGẮM", "reload": "ĐẠN", "jump": "NHẢY", "run": "CHẠY", "pause": "Ⅱ"}
	for key in hud.control_positions():
		var p: Vector2 = hud.control_positions()[key]
		var radius: float = 52 if key == "fire" else 33
		draw_circle(p, radius, Color(0.65, 0.39, 0.19, 0.48) if key == "fire" else Color(0.03, 0.1, 0.13, 0.4))
		draw_arc(p, radius, 0, TAU, 48, Color(0.95, 0.88, 0.7, 0.7), 1.5, true)
		var text: String = labels[key]
		var text_width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		draw_string(font, p + Vector2( - text_width / 2, 6), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, ink)

	var angle: float = hud.world.player.rotation.y
	var compass: = Vector2(size.x / 2, 28)
	draw_string(font, compass + Vector2(-7, 0), "B", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("efc383"))
	draw_line(compass + Vector2(0, 10), compass + Vector2(sin(angle) * 18, cos(angle) * 18 + 10), Color("efc383"), 2, true)
