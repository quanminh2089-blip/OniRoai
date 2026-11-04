extends Node3D
var prototypes: Dictionary = {}
var materials: Dictionary = {}
func piece(file: String, height: float, selector: String = "") -> Node3D:
	var key = file + selector
	if not prototypes.has(key): _prepare(key, file, selector)
	var result = prototypes[key].duplicate() as Node3D
	result.scale = Vector3.ONE * height / maxf(float(result.get_meta("height")), 0.01)
	return result
func _prepare(key: String, file: String, selector: String) -> void :
	var source = Game.model(file)
	var parts: Array[Dictionary] = []
	_gather(source, Transform3D.IDENTITY, selector, parts)
	assert ( not parts.is_empty(), "Missing mesh selector: " + key)
	var bounds = AABB()
	for i in range(parts.size()):
		var extent: AABB = parts[i].pose * parts[i].mesh.get_aabb()
		bounds = extent if i == 0 else bounds.merge(extent)
	var prototype = Node3D.new()
	var shift = Vector3( - bounds.get_center().x, - bounds.position.y, - bounds.get_center().z)
	for part in parts:
		var mesh = MeshInstance3D.new()
		mesh.mesh = part.mesh
		mesh.transform = part.pose
		mesh.position += shift
		prototype.add_child(mesh)
		for surface in range(mesh.mesh.get_surface_count()):
			var mat = mesh.mesh.surface_get_material(surface)
			if mat: mesh.set_surface_override_material(surface, _material(mat, file, part.name))
	prototype.set_meta("height", bounds.size.y)
	prototype.set_meta("width", bounds.size.x)
	prototype.set_meta("depth", bounds.size.z)
	add_child(prototype)
	prototypes[key] = prototype
	source.free()
func _gather(node: Node, pose: Transform3D, selector: String, parts: Array[Dictionary]) -> void :
	if node is Node3D: pose = pose * node.transform
	if node is MeshInstance3D and (selector.is_empty() or str(node.name).contains(selector)):
		parts.append({"mesh": node.mesh, "pose": pose, "name": str(node.name)})
	for child in node.get_children(): _gather(child, pose, selector, parts)
func _material(mat: Material, file: String, label: String) -> Material:
	var key = str(mat.get_instance_id()) + file
	if materials.has(key): return materials[key]
	var result: Material = mat.duplicate()
	if result is StandardMaterial3D:
		result.roughness = 0.92
		result.metallic = 0
		result.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		if result.normal_enabled: result.normal_scale = 0.4
		if file == "fern_02.gltf":
			var shader = Shader.new()
			shader.code = "shader_type spatial;\nrender_mode cull_disabled;\nuniform sampler2D leaves : source_color, filter_linear_mipmap_anisotropic;\nuniform sampler2D cutout : filter_linear_mipmap;\nuniform sampler2D normals : hint_normal, filter_linear_mipmap;\nvoid vertex(){vec3 wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;VERTEX.x+=sin(TIME*1.4+wp.z*0.7)*clamp(VERTEX.y,0.0,0.6)*0.035;}\nvoid fragment(){if(texture(cutout,UV).r<0.48){discard;}ALBEDO=texture(leaves,UV).rgb*0.85;NORMAL_MAP=texture(normals,UV).rgb;NORMAL_MAP_DEPTH=0.3;ROUGHNESS=0.95;SPECULAR=0.1;}\n"







			var foliage = ShaderMaterial.new();foliage.shader = shader
			foliage.set_shader_parameter("leaves", mat.albedo_texture)
			foliage.set_shader_parameter("normals", mat.normal_texture)
			foliage.set_shader_parameter("cutout", load("res://assets/citadel/fern/textures/fern_02_alpha_1k.jpg"))
			result = foliage
		if file == "forest_tree.glb" and label.contains("leaves"):
			var shader = Shader.new()
			shader.code = "shader_type spatial;\nrender_mode cull_disabled;\nuniform sampler2D leaves : source_color, filter_linear_mipmap_anisotropic;\nvarying vec3 wp;\nvoid vertex(){wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;VERTEX.x+=sin(TIME*1.15+wp.x*0.7+wp.z*0.4)*0.028;}\nvoid fragment(){vec4 c=texture(leaves,UV);if(c.a<0.48){discard;}ALBEDO=c.rgb*vec3(0.50,0.65,0.43);ROUGHNESS=0.98;SPECULAR=0.1;}\n"






			var foliage = ShaderMaterial.new()
			foliage.shader = shader
			foliage.set_shader_parameter("leaves", mat.albedo_texture)
			result = foliage
	materials[key] = result
	return result
