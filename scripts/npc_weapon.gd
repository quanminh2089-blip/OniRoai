extends Node3D
var muzzle: Marker3D
var flash: MeshInstance3D
var flash_time = 0.0
var magazine: Node3D
var magazine_rest = Transform3D.IDENTITY
func _ready() -> void :
	var source = Game.model("mp5a5.glb")
	var clone = source.find_child("Gun_mp5a5", true, false).duplicate() as Node3D
	add_child(clone)
	clone.transform = Transform3D.IDENTITY
	source.free()
	var socket = clone.find_child("MuzzleSocket", true, false) as Node3D
	muzzle = Marker3D.new()
	muzzle.transform = socket.transform if socket else Transform3D(Basis.IDENTITY, Vector3(0, 0.0988, -0.68))
	clone.add_child(muzzle)
	magazine = clone.find_child("Magazine", true, false)
	if magazine: magazine_rest = magazine.transform
	for mesh in find_children("*", "GeometryInstance3D", true, false): mesh.layers = 1
	flash = MeshInstance3D.new()
	var quad = QuadMesh.new()
	quad.size = Vector2(0.17, 0.17)
	flash.mesh = quad
	var mat = Game.material(Color("ffdb86"), true)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.82
	flash.material_override = mat
	flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	muzzle.add_child(flash)
	flash.hide()
func _process(delta: float) -> void :
	flash_time = maxf(0, flash_time - delta)
	if flash: flash.visible = flash_time > 0
func fire() -> void :
	flash_time = 0.055
	if flash: flash.rotation.z = randf() * TAU
func reload(progress: float) -> void :
	if magazine:
		magazine.transform = magazine_rest
		magazine.position.y -= sin(progress * PI) * 0.22
