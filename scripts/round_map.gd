extends Node3D
var world: Node3D
var library: Node3D
var materials: Dictionary = {}
var tree_count = 0
var rock_count = 0
var fern_count = 0
func build(arena: Node3D) -> void :
	world = arena
	name = "ValleyOutpost"
	library = Node3D.new()
	library.set_script(preload("res://scripts/round_assets.gd"))
	library.hide()
	add_child(library)
	_ground()
	_cover()
	_landscape()
	_details()
	call_deferred("_batch")
func pbr(name: String, tile: float = 0.5) -> StandardMaterial3D:
	if materials.has(name): return materials[name]
	var mat = StandardMaterial3D.new()
	var path = "res://assets/citadel/textures/" + name + "/"
	mat.albedo_texture = load(path + "color.jpg")
	mat.normal_texture = load(path + "normal.jpg")
	mat.normal_enabled = true
	mat.normal_scale = 0.45
	mat.roughness = 0.95
	mat.roughness_texture = load(path + "roughness.jpg")
	mat.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3.ONE * tile
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	materials[name] = mat
	return mat
func box(at: Vector3, size: Vector3, mat: Material, collision: bool = false) -> MeshInstance3D:
	var mesh = BoxMesh.new()
	mesh.size = size
	var node = MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	node.position = at
	add_child(node)
	if collision: world._collider(at, size)
	return node
func _ground() -> void :
	var shader = Shader.new()
	shader.code = "shader_type spatial;\nuniform sampler2D earth : source_color, filter_linear_mipmap_anisotropic, repeat_enable;\nuniform sampler2D grass : source_color, filter_linear_mipmap_anisotropic, repeat_enable;\nuniform sampler2D earth_normal : hint_normal, filter_linear_mipmap, repeat_enable;\nuniform sampler2D grass_normal : hint_normal, filter_linear_mipmap, repeat_enable;\nvarying vec3 wp;\nfloat noise(vec2 p){return sin(p.x*0.19+sin(p.y*0.17))*cos(p.y*0.13)*0.5+0.5;}\nvoid vertex(){wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}\nvoid fragment(){vec2 uv=wp.xz*0.45;float g=smoothstep(0.28,0.68,noise(wp.xz))*0.65;ALBEDO=mix(texture(earth,uv).rgb*0.87,texture(grass,uv).rgb*vec3(0.76,0.85,0.72),g);NORMAL_MAP=mix(texture(earth_normal,uv).rgb,texture(grass_normal,uv).rgb,g);NORMAL_MAP_DEPTH=0.48;ROUGHNESS=0.96;SPECULAR=0.1;}\n"









	var mat = ShaderMaterial.new()
	mat.shader = shader
	for pair in [["earth", "forest_ground_04/color.jpg"], ["grass", "leafy_grass/color.jpg"], ["earth_normal", "forest_ground_04/normal.jpg"], ["grass_normal", "leafy_grass/normal.jpg"]]: mat.set_shader_parameter(pair[0], load("res://assets/citadel/textures/" + pair[1]))
	box(Vector3(0, -0.18, 0), Vector3(400, 0.35, 400), mat).set_meta("keep", true)
	world._collider(Vector3(0, -0.2, 0), Vector3(48, 0.4, 58), false)
	var stone = pbr("medieval_blocks_03", 0.55)
	for side in [-1, 1]:
		box(Vector3(side * 23, 0.65, 0), Vector3(0.6, 1.3, 56), stone)
		world._collider(Vector3(side * 23, 2, 0), Vector3(0.6, 4, 56))
		box(Vector3(0, 0.65, side * 27), Vector3(46, 1.3, 0.6), stone)
		world._collider(Vector3(0, 2, side * 27), Vector3(46, 4, 0.6))
		_fence(Vector3(side * 23, 2.5, 0), 56, PI / 2)
		_fence(Vector3(0, 2.5, side * 27), 46, 0)
	for at in [Vector3(-12, 0, 17), Vector3(0, 0, -20)]: box(at + Vector3(0, 0.01, 0), Vector3(8, 0.035, 6), stone)
func _cover() -> void :
	var stone = pbr("medieval_blocks_03", 0.6)
	for entry in [[Vector3(-10, 1.15, 8), Vector3(5, 2.3, 0.65)], [Vector3(7, 1.1, 7), Vector3(5.5, 2.2, 0.65)], [Vector3(-7, 1.25, -8), Vector3(5.8, 2.5, 0.65)], [Vector3(11, 1.15, -6), Vector3(4.5, 2.3, 0.65)], [Vector3(-18, 1, 0), Vector3(0.65, 2, 5)], [Vector3(17, 0.5, 14), Vector3(4, 1, 0.65)]]: box(entry[0], entry[1], stone, true)
	var at = Vector3(10, 0, 0)
	box(at + Vector3(0, 0.06, 0), Vector3(7, 0.12, 6), stone)
	box(at + Vector3(-3.5, 1.5, 0), Vector3(0.3, 3, 6), stone, true)
	box(at + Vector3(3.5, 1.5, -1.7), Vector3(0.3, 3, 2.6), stone, true)
	box(at + Vector3(3.5, 1.5, 2.2), Vector3(0.3, 3, 1.6), stone, true)
	box(at + Vector3(0, 1.5, -3), Vector3(7, 3, 0.3), stone, true)
	for x in [-2.65, 2.65]: box(at + Vector3(x, 1.5, 3), Vector3(1.7, 3, 0.3), stone, true)
	box(at + Vector3(0, 2.7, 3), Vector3(3.6, 0.6, 0.3), stone)
	world._collider(at + Vector3(0, 2.7, 3), Vector3(3.6, 0.6, 0.3), false)
	box(at + Vector3(0, 3.1, 0), Vector3(7.6, 0.16, 6.5), Game.material(Color("594d3b")))
	world._collider(at + Vector3(0, 3.1, 0), Vector3(7.6, 0.16, 6.5), false)
	for entry in [[Vector3(-10, 0, -1), 0.0], [Vector3(0, 0, 11), 0.0], [Vector3(-4, 0, -16), PI / 2], [Vector3(15, 0, -14), 0.0]]: prop("concrete_road_barrier.glb", entry[0], Vector3(2.1, 0.9, 0.65), entry[1])
	for entry in [[Vector3(-4, 0, 5), 0.0], [Vector3(-16, 0, -9), 0.2], [Vector3(17, 0, 8), 0.0], [Vector3(3, 0, -12), PI / 2], [Vector3(-18, 0, 15), 0.0]]: prop("old_military_crate.glb", entry[0], Vector3(1.25, 1.05, 0.95), entry[1])
	_rock(Vector3(0, 0, 0), 3, 2, true)
	_rock(Vector3(-3, 0, -2), 1.6, 4, true)
	_rock(Vector3(3, 0, 3), 1.45, 1, true)
	_rock(Vector3(-16, 0, 5), 1.5, 5, true)
	_rock(Vector3(18, 0, -11), 2.2, 3, true)
	_gate(Vector3(-17, 0, -17))
	_gate(Vector3(17, 0, 19))
func prop(file: String, at: Vector3, collision: Vector3, angle: float = 0) -> void :
	var model = Game.model(file)
	model.position = at
	model.rotation.y = angle
	add_child(model)
	var size = Vector3(collision.z, collision.y, collision.x) if absf(sin(angle)) > 0.7 else collision
	world._collider(at + Vector3.UP * size.y * 0.5, size)
func _rock(at: Vector3, height: float, variant: int, collision: bool = false, boundary: int = 0) -> void :
	var rock = library.piece("rock_moss_set_01.gltf", height, "rock0" + str(variant))
	rock.position = at
	rock.rotation.y = float(variant) * 0.63 + at.x * 0.2
	var width = float(rock.get_meta("width")) * rock.scale.x
	var depth = float(rock.get_meta("depth")) * rock.scale.x
	var c = absf(cos(rock.rotation.y)); var d = absf(sin(rock.rotation.y))
	var footprint = Vector2(width * c + depth * d, depth * c + width * d)
	if boundary == 1: rock.position.x = signf(at.x) * (24.5 + footprint.x * 0.5)
	if boundary == 2: rock.position.z = signf(at.z) * (28.5 + footprint.y * 0.5)
	add_child(rock)
	if collision:
		_static_collision(rock)
		var size = footprint + Vector2.ONE * 0.65
		world.blocked.append(Rect2(Vector2(at.x, at.z) - size * 0.5, size))
	rock_count += 1
func _static_collision(model: Node3D) -> void :
	for part in model.get_children():
		if not part is MeshInstance3D: continue
		var body = StaticBody3D.new()
		body.transform = part.transform
		var shape = CollisionShape3D.new()
		shape.shape = part.mesh.create_trimesh_shape()
		body.add_child(shape)
		model.add_child(body)
func _gate(at: Vector3) -> void :
	var stone = pbr("medieval_blocks_03", 0.75)
	for side in [-1, 1]: box(at + Vector3(side * 2.05, 1.15, 0), Vector3(0.9, 2.3, 1.25), stone, true)

	var tool = SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(14):
		var a = PI * i / 14.0 + 0.008; var b = PI * (i + 1) / 14.0 - 0.008
		var vertices: Array[Vector3] = []
		for z in [-0.62, 0.62]:
			for p in [Vector2(cos(a), sin(a)) * 1.6, Vector2(cos(b), sin(b)) * 1.6, Vector2(cos(b), sin(b)) * 2.5, Vector2(cos(a), sin(a)) * 2.5]: vertices.append(Vector3(p.x, 2.3 + p.y, z))
		for face in [[0, 2, 1, 0, 3, 2], [4, 5, 6, 4, 6, 7], [0, 1, 5, 0, 5, 4], [1, 2, 6, 1, 6, 5], [2, 3, 7, 2, 7, 6], [3, 0, 4, 3, 4, 7]]:
			for index in face: tool.set_uv(Vector2(vertices[index].x, vertices[index].y));tool.add_vertex(vertices[index])
	tool.generate_normals();tool.generate_tangents()
	var mesh = MeshInstance3D.new();mesh.mesh = tool.commit();mesh.material_override = stone;mesh.position = at;add_child(mesh)
	var body = StaticBody3D.new();body.position = at
	var col = CollisionShape3D.new();col.shape = mesh.mesh.create_trimesh_shape();body.add_child(col);add_child(body)
func _landscape() -> void :
	var rng = RandomNumberGenerator.new();rng.seed = 4904
	for side in [-1, 1]:
		for i in range(8): _rock(Vector3(side * rng.randf_range(26, 32), -0.3, -32 + i * 9.0), rng.randf_range(5.5, 9), i % 6 + 1, false, 1)
		for i in range(5): _rock(Vector3(-28 + i * 14, -0.4, side * 32), rng.randf_range(5, 8), (i + 2) % 6 + 1, false, 2)
	for at in [Vector3(-20, 0, 21), Vector3(-19, 0, 11), Vector3(-20, 0, -11), Vector3(-7, 0, 22), Vector3(18, 0, 20), Vector3(20, 0, 11), Vector3(19, 0, -20), Vector3(7, 0, -23), Vector3(-10, 0, -23), Vector3(-32, 0, 14), Vector3(31, 0, -8), Vector3(-33, 0, -18)]:
		var tree = library.piece("forest_tree.glb", rng.randf_range(6, 8));tree.position = at;tree.rotation.y = rng.randf() * TAU;add_child(tree)
		if absf(at.x) < 22 and absf(at.z) < 26: world._collider(at + Vector3.UP * 0.9, Vector3(0.55, 1.8, 0.55))
		tree_count += 1
	var water = ShaderMaterial.new(); var shader = Shader.new()
	shader.code = "shader_type spatial;varying vec3 wp;void vertex(){wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}void fragment(){float w=sin(wp.z*2.3+wp.x*1.7-TIME*1.2);ALBEDO=vec3(0.045,0.15,0.14)+w*0.012;ROUGHNESS=0.65;SPECULAR=0.18;}"
	water.shader = shader
	box(Vector3(26, 0.015, 0), Vector3(5, 0.03, 80), water).set_meta("keep", true)
func _details() -> void :
	for at in [Vector3(-18, 0, 11), Vector3(15, 0, -10), Vector3(17, 0, -9), Vector3(8, 0, 1)]: prop("Barrel_01.glb", at, Vector3(0.65, 1.1, 0.65))
	prop("portable_generator.glb", Vector3(11, 0, -1), Vector3(1.5, 1.25, 1.3))
	var plants = [Vector3(-18, 0, 19), Vector3(-19, 0, 18), Vector3(-18, 0, 12), Vector3(-19, 0, -9), Vector3(-17, 0, -10), Vector3(18, 0, 10), Vector3(18, 0, 9), Vector3(19, 0, -18), Vector3(6, 0, -23), Vector3(7, 0, -24), Vector3(-9, 0, -23), Vector3(-8, 0, -24), Vector3(-3, 0, -3), Vector3(-4, 0, -2), Vector3(3, 0, 4), Vector3(4, 0, 4), Vector3(17, 0, -11), Vector3(19, 0, -11), Vector3(-17, 0, 5), Vector3(-16, 0, 6), Vector3(7, 0, -3), Vector3(7, 0, -2), Vector3(14, 0, -2), Vector3(-18, 0, 14)]
	for i in range(plants.size()):
		var plant = library.piece("fern_02.gltf", 0.52 + float(i % 4) * 0.1, "fern_02_" + ["a", "b", "c", "d"][i % 4])
		plant.position = plants[i];plant.rotation.y = i * 1.618;add_child(plant);fern_count += 1
	_flag(Vector3(-14, 0, 19), Color("3f8aad"));_flag(Vector3(1, 0, -23), Color("b65a49"))
	var label = Label3D.new();label.text = "TRẠM 04";label.font = load("res://assets/fonts/DejaVuSans.ttf");label.font_size = 40;label.pixel_size = 0.014;label.modulate = Color("d7c9a1");label.position = Vector3(10, 2.3, 3.19);add_child(label)
func _flag(at: Vector3, color: Color) -> void :
	box(at + Vector3.UP * 2.1, Vector3(0.075, 4.2, 0.075), Game.material(Color("555e5c")))
	var shader = Shader.new();shader.code = "shader_type spatial;render_mode cull_disabled;uniform vec4 cloth_color : source_color;void vertex(){VERTEX.z+=sin(TIME*2.1+UV.x*6.0+UV.y)*UV.x*0.10;}void fragment(){ALBEDO=cloth_color.rgb*(0.84+sin(UV.x*15.0)*0.06);ROUGHNESS=1.0;SPECULAR=0.1;}"
	var mat = ShaderMaterial.new();mat.shader = shader;mat.set_shader_parameter("cloth_color", color)
	var flag = MeshInstance3D.new(); var mesh = PlaneMesh.new();mesh.orientation = PlaneMesh.FACE_Z;mesh.size = Vector2(1.5, 0.9);mesh.subdivide_width = 12;mesh.subdivide_depth = 5
	flag.mesh = mesh;flag.material_override = mat;flag.position = at + Vector3(0.8, 3.55, 0);flag.set_meta("keep", true);add_child(flag)
func _fence(at: Vector3, width: float, angle: float) -> void :
	var shader = Shader.new();shader.code = "shader_type spatial;render_mode cull_disabled;uniform float repeats;void fragment(){vec2 u=UV*vec2(repeats,5.0);float a=abs(fract(u.x+u.y)-0.5);float b=abs(fract(u.x-u.y)-0.5);if(min(a,b)>0.055){discard;}ALBEDO=vec3(0.27,0.31,0.28);ROUGHNESS=0.8;METALLIC=0.25;}"
	var mat = ShaderMaterial.new();mat.shader = shader;mat.set_shader_parameter("repeats", width * 2.5)
	var mesh = PlaneMesh.new();mesh.orientation = PlaneMesh.FACE_Z;mesh.size = Vector2(width, 2.4)
	var node = MeshInstance3D.new();node.mesh = mesh;node.material_override = mat;node.position = at;node.rotation.y = angle;node.set_meta("keep", true);add_child(node)
	for i in range(0, int(width), 4): box(at + Vector3( - width / 2 + i, 0, 0).rotated(Vector3.UP, angle), Vector3(0.065, 2.5, 0.065), Game.material(Color("626c5c")))
func _batch() -> void :
	var groups: Dictionary = {}; var meshes: Dictionary = {}
	for node in find_children("*", "MeshInstance3D", true, false):
		if not node.is_visible_in_tree() or node.get_meta("keep", false) or not node.mesh: continue
		var mk = str(node.mesh.get_instance_id())
		for surface in range(node.mesh.get_surface_count()):
			var mat = node.get_active_material(surface);mk += ":" + str(mat.get_instance_id() if mat else 0)
		var key = mk + str(Vector2i(floori(node.global_position.x / 16), floori(node.global_position.z / 16)))
		if not meshes.has(mk):
			var shared = node.mesh.duplicate() as Mesh
			for surface in range(shared.get_surface_count()): shared.surface_set_material(surface, node.get_active_material(surface))
			meshes[mk] = shared
		if not groups.has(key): groups[key] = {"mesh": meshes[mk], "poses": []}
		groups[key].poses.append(global_transform.affine_inverse() * node.global_transform);node.queue_free()
	for group in groups.values():
		var multi = MultiMesh.new();multi.transform_format = MultiMesh.TRANSFORM_3D;multi.mesh = group.mesh;multi.instance_count = group.poses.size()
		for i in range(multi.instance_count): multi.set_instance_transform(i, group.poses[i])
		var node = MultiMeshInstance3D.new();node.multimesh = multi;add_child(node)
	print("ROUND_MAP_READY trees=", tree_count, " rocks=", rock_count, " ferns=", fern_count, " batches=", groups.size())
