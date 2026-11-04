extends RefCounted

static func build(view: Vector2, control_scale: float, left_fire: bool, insets: Vector4 = Vector4.ZERO, custom: Dictionary = {}) -> Dictionary:
	var area = Rect2(Vector2(24 + insets.x, 20 + insets.y), view - Vector2(48 + insets.x + insets.z, 40 + insets.y + insets.w))
	var s = clampf(control_scale, 0.85, 1.2) * minf(1.0, area.size.y / 650.0)
	var left = area.position.x
	var right = area.end.x
	var top = area.position.y
	var bottom = area.end.y
	var points = {
		"fire": Vector2(right - 136 * s, bottom - 148 * s), 
		"aim": Vector2(right - 136 * s, bottom - 370 * s), 
		"jump": Vector2(view.x * 0.5 + 72 * s, bottom - 88 * s), 
		"crouch": Vector2(view.x * 0.5 - 72 * s, bottom - 88 * s), 
		"run": Vector2(left + 136 * s, bottom - 415 * s),
		"lean_left": Vector2(left + 72 * s, bottom - 302 * s),
		"lean_right": Vector2(left + 195 * s, bottom - 302 * s), 
		"pause": Vector2(left + 35, top + 35)}
	var radii = {"fire": 102 * s, "aim": 54 * s, "jump": 52 * s, "crouch": 52 * s, "run": 48 * s, "pause": 32.0, "lean_left": 43 * s, "lean_right": 43 * s}
	if left_fire:
		points["fire_left"] = Vector2(left + 292 * s, top + 130 * s)
		radii["fire_left"] = 52 * s
	var joystick = Vector2(left + 136 * s, bottom - 148 * s)
	for key in points:
		if custom.has(key) and custom[key] is Vector2:
			var coords: Vector2 = custom[key]
			points[key] = area.position + Vector2(clampf(coords.x, 0.0, 1.0) * area.size.x, clampf(coords.y, 0.0, 1.0) * area.size.y)
	if custom.has("move") and custom["move"] is Vector2:
		var move_coords: Vector2 = custom["move"]
		joystick = area.position + Vector2(clampf(move_coords.x, 0.0, 1.0) * area.size.x, clampf(move_coords.y, 0.0, 1.0) * area.size.y)
	var move_zone: Rect2 = Rect2(area.position + Vector2(0, area.size.y * 0.45), Vector2(area.size.x * 0.4, area.size.y * 0.55))
	if custom.has("move"):
		move_zone = Rect2(joystick - Vector2(135 * s, 135 * s), Vector2(270 * s, 270 * s))
	var u = minf(1, area.size.y / 650.0)
	return {"points": points, "radii": radii, "safe": area, "scale": s, 
		"ammo": Rect2(Vector2(right - 320 * u, top), Vector2(320, 112) * u), 
		"score": Rect2(Vector2(view.x * 0.5 - 200 * u, top), Vector2(400, 78) * u), 
		"joystick": joystick, "joy_radius": 102 * s, "joy_travel": 74 * s, 
		"move_zone": move_zone}
