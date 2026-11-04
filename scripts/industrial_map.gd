extends RefCounted

var world: Node3D
var materials: Dictionary = {}

func build(arena: Node3D) -> void :
	world = arena
	var asphalt: = surface("Asphalt031", 3.0)
	var concrete: = surface("Concrete047A", 2.8)
	var metal: = surface("corrugated_iron", 2.5)
	var steel: = surface("Metal063", 2.0)
	var timber: = surface("WeatheredPlanks", 2.0)
	var dark: = Game.material(Color("292e31"))
	var paint: = Game.material(Color("b89c55"))
	box(Vector3(0, -0.25, 0), Vector3(62, 0.5, 62), asphalt)
	world._collider(Vector3(0, -0.25, 0), Vector3(62, 0.5, 62), false)

	for side in [-1.0, 1.0]:
		box(Vector3(side * 29, 2.2, 0), Vector3(0.5, 4.4, 58), concrete, true)
		box(Vector3(0, 2.2, side * 29), Vector3(58, 4.4, 0.5), concrete, true)
	for i in range(10):
		var p: = Vector3(-50 + i * 11, 4 + (i % 4) * 2, -45)
		box(p, Vector3(8, 8 + (i % 4) * 4, 12), concrete)
	for i in range(8):
		box(Vector3(-27 + i * 8, 4.6, -29), Vector3(0.1, 0.7, 0.1), steel)
		box(Vector3(-27 + i * 8, 4.6, 29), Vector3(0.1, 0.7, 0.1), steel)
	box(Vector3(0, 4.8, -29), Vector3(58, 0.04, 0.04), steel)
	box(Vector3(0, 4.8, 29), Vector3(58, 0.04, 0.04), steel)

	box(Vector3(-14, 0.015, -8), Vector3(14, 0.03, 18), concrete)
	box(Vector3(-21, 2.6, -8), Vector3(0.35, 5.2, 18), concrete, true)
	box(Vector3(-7, 2.6, -8), Vector3(0.35, 5.2, 18), concrete, true)
	box(Vector3(-14, 2.6, -17), Vector3(14, 5.2, 0.35), concrete, true)
	box(Vector3(-18.5, 2.6, 1), Vector3(5, 5.2, 0.35), concrete, true)
	box(Vector3(-9.5, 2.6, 1), Vector3(5, 5.2, 0.35), concrete, true)
	box(Vector3(-14, 4.7, 1), Vector3(4, 1, 0.4), metal)
	box(Vector3(-14, 5.25, -8), Vector3(14.4, 0.18, 18.4), metal)
	for z in [-15, -10, -5, 0]:
		box(Vector3(-14, 4.9, z), Vector3(14.2, 0.18, 0.22), steel)
	for x in [-20.4, -7.6]:
		for z in [-15, -7, 0]: box(Vector3(x, 2.55, z), Vector3(0.16, 5.1, 0.2), steel)
	add_sign("KHO 07", Vector3(-14, 3.95, 1.24), 0, 64, Color("d0cbb7"))
	add_sign("CẤM VÀO  /  KHU HẠN CHẾ", Vector3(-18.6, 1.7, 1.23), 0, 22, Color("c6a467"))

	for x in [-19.1, -8.9]:
		for z in [-12.0, -5.0]:
			for y in [0.45, 1.6, 2.75]: box(Vector3(x, y, z), Vector3(2.1, 0.09, 4.6), timber)
			for sx in [-0.95, 0.95]:
				for sz in [-2.2, 2.2]: box(Vector3(x + sx, 1.5, z + sz), Vector3(0.08, 3.0, 0.08), steel)
			world._collider(Vector3(x, 1.5, z), Vector3(2.1, 3, 4.6))
	for p in [Vector3(-15, 0, -10), Vector3(-12, 0, -14), Vector3(-17, 0, -4)]:
		prop("old_military_crate", p, 1.0, Vector3(1.0, 0.8, 0.7))

	box(Vector3(13, 2.3, -19.5), Vector3(12, 4.6, 8), concrete, true)
	box(Vector3(13, 4.7, -19.5), Vector3(12.4, 0.18, 8.4), steel)
	for x in [9, 12, 15, 18]:
		box(Vector3(x, 2.5, -15.45), Vector3(1.9, 1.5, 0.04), dark)
		box(Vector3(x, 2.45, -15.4), Vector3(0.06, 1.6, 0.06), steel)
	box(Vector3(8.5, 1.25, -15.42), Vector3(1.1, 2.5, 0.08), metal)
	add_sign("ĐIỀU HÀNH", Vector3(14.0, 3.8, -15.39), 0, 32, Color("bac0c1"))

	for data in [[Vector3(11, 0, -6), 0], [Vector3(18, 0, 2), PI / 2], [Vector3(10, 0, 16), 0]]:
		var p: Vector3 = data[0]
		var size: = Vector3(7, 2.7, 2.8) if float(data[1]) == 0 else Vector3(2.8, 2.7, 7)
		box(p + Vector3(0, 1.35, 0), size, metal, true)
		box(p + Vector3(0, 2.75, 0), size * Vector3(1.01, 0.03, 1.01), steel)
		for i in range(2): box(p + Vector3(-0.6 + i * 1.2, 1.35, size.z / 2 + 0.02), Vector3(0.06, 2.4, 0.05), steel)
	add_sign("MQ / 07", Vector3(10.8, 1.8, -4.56), 0, 32, Color("c9c5b9"))

	for z in range(-23, 24, 5):
		box(Vector3(0, 0.009, z), Vector3(0.12, 0.015, 2.3), paint)
	for z in [7.0, 13.0]: box(Vector3(5, 0.012, z), Vector3(12, 0.015, 0.12), paint)
	for x in [0, 4, 8, 12]: box(Vector3(x, 0.012, 10), Vector3(0.1, 0.015, 6), paint)
	for p in [Vector3(-3, 0, -11), Vector3(4, 0, 2), Vector3(-10, 0, 15), Vector3(18, 0, 12)]:
		prop("concrete_road_barrier", p, 1.0, Vector3(2.1, 0.9, 0.6))
	for p in [Vector3(-4, 0, 16), Vector3(15, 0, -11), Vector3(21, 0, 18)]:
		prop("old_military_crate", p, 1.0, Vector3(1.1, 0.85, 0.8))
	for p in [Vector3(-24, 0, 10), Vector3(22, 0, -9), Vector3(21.1, 0, -9), Vector3(-10, 0, 7)]:
		prop("Barrel_01", p, 1.0, Vector3(0.65, 1.1, 0.65))
	prop("portable_generator", Vector3(-24, 0, -12), 1.0, Vector3(1.4, 1.3, 1.2))

	for p in [Vector3(-14, 4.9, -7), Vector3(-14, 4.9, -13), Vector3(6, 4.6, 9), Vector3(0, 4.0, -20)]:
		box(p, Vector3(1.1, 0.1, 0.24), Game.material(Color("d2b782"), true))
		var lamp: = OmniLight3D.new()
		lamp.position = p - Vector3(0, 0.25, 0)
		lamp.light_color = Color("e3cba3")
		lamp.light_energy = 1.6
		lamp.omni_range = 7
		lamp.shadow_enabled = false
		world.add_child(lamp)
	for p in [Vector3(6, 0, 9), Vector3(0, 0, -20)]: box(p + Vector3(0, 2, 0), Vector3(0.1, 4, 0.1), steel)
	add_sign("ĐIỂM THOÁT", Vector3(0, 2.6, -23), 0, 38, Color("abc5b0"))

func box(p: Vector3, size: Vector3, mat: Material, collide: bool = false) -> MeshInstance3D:
	var mesh: MeshInstance3D = world.box_mesh(p, size, mat, collide)
	if size.y < 0.1: mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mesh

func surface(name_text: String, meters: float) -> StandardMaterial3D:
	if materials.has(name_text): return materials[name_text]
	var mat: = StandardMaterial3D.new()
	var base: String = "res://assets/tactical/textures/" + name_text + "/"
	mat.albedo_texture = load(base + "Color.webp")
	mat.normal_enabled = true
	mat.normal_texture = load(base + "NormalGL.webp")
	mat.normal_scale = 0.35
	mat.roughness_texture = load(base + "Roughness.webp")
	mat.roughness = 0.9
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3.ONE / meters
	mat.albedo_color = Color(0.66, 0.69, 0.72)
	if name_text == "Asphalt031":
		mat.roughness_texture = null
		mat.roughness = 1.0
		mat.normal_scale = 0.12
	if "Metal" in name_text or "iron" in name_text: mat.metallic = 0.5
	materials[name_text] = mat
	return mat

func prop(name_text: String, p: Vector3, scale_value: float, collision: Vector3) -> void :
	var model: = Game.model(name_text + ".glb")
	model.position = p
	model.scale = Vector3.ONE * scale_value
	world.add_child(model)
	world._collider(p + Vector3(0, collision.y / 2, 0), collision)
	for part in model.find_children("*", "GeometryInstance3D", true, false): part.visibility_range_end = 48

func add_sign(text: String, p: Vector3, angle: float, size: int, color: Color) -> void :
	var label: = Label3D.new()
	label.text = text
	label.font = load("res://assets/fonts/DejaVuSans.ttf")
	label.font_size = size
	label.pixel_size = 0.008
	label.modulate = color
	label.outline_size = 1
	label.position = p
	label.rotation.y = angle
	world.add_child(label)
