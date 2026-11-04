extends Node3D
const Art = preload("res://scripts/oniroai_art.gd")

var player: CharacterBody3D
var model: Node3D
var magazine: Node3D
var handle: Node3D
var muzzle_socket: Node3D
var skeleton: Skeleton3D
var left_controller: int = -1
var left_rest: = Vector3.ZERO
var left_rotation: = Quaternion.IDENTITY
var mag_rest: = Transform3D.IDENTITY
var handle_rest: = Vector3.ZERO
var covers: Array[Node3D] = []
var ads_blend: float = 0.0
var reload_elapsed: float = -1.0
var ik: SkeletonIK3D
var ik_target: Marker3D
var flash: Sprite3D
var smoke: Sprite3D
var smoke_timer = 0.0
var fire_blend = 0.0
var flash_timer: float = 0.0
var clock: float = 0.0
var foley: AudioStreamPlayer
var reload_sound_step: int = 0
var sprint_blend: float = 0

func _ready() -> void :
	name = "MP5View"
	model = Game.model("mp5a5.glb")
	add_child(model)
	foley = AudioStreamPlayer.new()
	foley.volume_db = -11
	foley.max_polyphony = 3
	add_child(foley)
	magazine = model.find_child("Magazine", true, false) as Node3D
	handle = model.find_child("ChargingHandle", true, false) as Node3D
	muzzle_socket = model.find_child("MuzzleSocket", true, false) as Node3D
	if magazine: mag_rest = magazine.transform
	if handle: handle_rest = handle.position
	var rigs: = model.find_children("*", "Skeleton3D", true, false)
	if not rigs.is_empty():
		skeleton = rigs[0]
		left_controller = skeleton.find_bone("IK_Hand_Cntrl_L")
		if left_controller >= 0:
			left_rest = skeleton.get_bone_pose_position(left_controller)
			left_rotation = skeleton.get_bone_pose_rotation(left_controller)
			ik_target = Marker3D.new()
			model.add_child(ik_target)
			ik = SkeletonIK3D.new()
			ik.root_bone = "UpArm_L"
			ik.tip_bone = "BoneTwist_01.L_end"
			ik.influence = 1.0
			ik.override_tip_basis = false
			skeleton.add_child(ik)
			ik.target_node = ik.get_path_to(ik_target)

		for bone_name in ["UpArm_L", "UpArm_R"]:
			if skeleton.find_bone(bone_name) < 0: continue
			var attachment: = BoneAttachment3D.new()
			attachment.bone_name = bone_name
			skeleton.add_child(attachment)
			var cuff: = MeshInstance3D.new()
			var cuff_mesh: = CylinderMesh.new()
			cuff_mesh.top_radius = 0.063
			cuff_mesh.bottom_radius = 0.085
			cuff_mesh.height = 0.24
			cuff_mesh.radial_segments = 16
			cuff.mesh = cuff_mesh
			cuff.position.y = -0.12
			var cloth: = Game.material(Color("626653"))
			cloth.albedo_texture = load("res://assets/tactical/models/fp/arms_basecolor.webp")
			cuff.material_override = cloth
			attachment.add_child(cuff)
	_optics()
	flash = Sprite3D.new()
	flash.texture = Art.sprite("flash_0")
	flash.pixel_size = 0.00027
	flash.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	flash.shaded = false
	flash.visible = false
	if muzzle_socket: muzzle_socket.add_child(flash)
	else: add_child(flash)
	smoke = Sprite3D.new();smoke.texture = Art.sprite("smoke_0");smoke.pixel_size = 0.0002;smoke.billboard = BaseMaterial3D.BILLBOARD_ENABLED;smoke.shaded = false;smoke.modulate = Color(0.65, 0.7, 0.72, 0)
	if muzzle_socket: muzzle_socket.add_child(smoke)
	else: add_child(smoke)
	_layers(model)
	var fill: = DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25, 155, 0)
	fill.light_color = Color("becbd6")
	fill.light_energy = 0.6
	fill.light_cull_mask = 2
	add_child(fill)
	scale = Vector3.ONE * 0.7
	position = Vector3(0.2, -0.3, -0.22)
	call_deferred("_start_ik")

func _start_ik() -> void :
	if ik and skeleton:
		_update_ik()
		ik.start()

func _layers(node: Node) -> void :
	if node is GeometryInstance3D:
		node.layers = 2
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children(): _layers(child)

func _optics() -> void :
	var all_optics: = Game.model("optics.glb")
	add_child(all_optics)
	var optic: = all_optics.find_child("ScopeOptic", true, false) as Node3D
	if optic:
		optic.reparent(self, false)
		optic.position = Vector3(0, 0.255, -0.245)
		optic.rotation = Vector3.ZERO
		optic.scale = Vector3.ONE
		var geometry = optic.find_child("ScopeGeometry", true, false) as MeshInstance3D
		if geometry:
			var original = geometry.get_active_material(0) as StandardMaterial3D
			if original:
				var lens = ShaderMaterial.new()
				lens.shader = preload("res://assets/oniroai/open_scope.gdshader")
				lens.set_shader_parameter("body_color", original.albedo_texture)
				lens.set_shader_parameter("body_normal", original.normal_texture)
				geometry.material_override = lens
		for anchor_name in ["ScopeFrontApertureAnchor", "ScopeRearApertureAnchor"]:
			var anchor: = optic.find_child(anchor_name, true, false) as Node3D
			if anchor:
				var hinge: = Node3D.new()
				anchor.add_child(hinge)
				hinge.position.y = 0.026
				var cover: = MeshInstance3D.new()
				var disk: = CylinderMesh.new()
				disk.top_radius = 0.025
				disk.bottom_radius = 0.025
				disk.height = 0.004
				disk.radial_segments = 24
				cover.mesh = disk
				cover.rotation.x = PI / 2
				cover.position.y = -0.026
				cover.material_override = Game.material(Color("191c20"))
				hinge.add_child(cover)
				covers.append(hinge)
		_layers(optic)
	all_optics.queue_free()

func _process(delta: float) -> void :
	if not is_instance_valid(player) or not player.world.playing:
		if flash: flash.hide()
		flash_timer = 0;smoke_timer = 0
		if smoke: smoke.modulate.a = 0
		return
	clock += delta
	ads_blend = move_toward(ads_blend, 1.0 if player.aiming and player.reload_time <= 0 else 0.0, delta * 7.0)
	var moving: = Vector2(player.velocity.x, player.velocity.z).length()
	var sway: = Vector3(sin(player.walk_phase * 0.5) * 0.008, cos(player.walk_phase) * 0.006, 0) * minf(moving / 3.6, 1.0) * Game.camera_motion
	sway += Vector3( - player.look_sway.x * 0.012, player.look_sway.y * 0.008, 0) * Game.camera_motion
	var hip: = Vector3(0.2, -0.3, -0.22) + sway
	var aiming_pose: = Vector3(0, -0.178, -0.14)
	var sprinting = player.running and moving > 3.9 and not player.aiming and not player.fire_held and player.reload_time <= 0 and not player.crouching
	sprint_blend = move_toward(sprint_blend, 1.0 if sprinting else 0.0, delta * 6)
	hip = hip.lerp(Vector3(0.27, -0.4, -0.16) + sway * 1.3, sprint_blend)
	var fire_target = 1.0 if (player.fire_held or player.cooldown > 0.035) and player.reload_time <= 0 else 0.0
	fire_blend = move_toward(fire_blend, fire_target, delta * (10 if fire_target > fire_blend else 6))
	for cover in covers: cover.rotation.x = - maxf(ads_blend, fire_blend) * 2.05
	hip = hip.lerp(Vector3(0.035, -0.2, -0.24) + sway * 0.3, smoothstep(0, 1, fire_blend))
	position = hip.lerp(aiming_pose, smoothstep(0, 1, ads_blend))
	rotation = Vector3(player.recoil * 0.1 - 0.25 * sprint_blend, -0.12 * sprint_blend + player.recoil_yaw * 0.3, -0.15 * sprint_blend)
	position.z += player.recoil * 0.035
	if reload_elapsed >= 0:
		reload_elapsed += delta
		_reload_pose(reload_elapsed)
		if reload_elapsed >= player.RELOAD_DURATION:
			reset_parts()
	flash_timer = maxf(0, flash_timer - delta)
	flash.visible = flash_timer > 0
	smoke_timer = maxf(0, smoke_timer - delta)
	smoke.modulate.a = 0.12 * smoke_timer / 0.24
	smoke.position.y = 0.012 + (0.24 - smoke_timer) * 0.15
	visible = true
	_update_ik()

func _update_ik() -> void :
	if skeleton and ik_target and left_controller >= 0:
		var hand: = skeleton.get_bone_global_pose(left_controller).origin
		ik_target.global_position = skeleton.to_global(hand)

func trigger_flash() -> void :
	flash_timer = 0.022
	flash.texture = Art.sprite("flash_" + str(player.shots_fired % 2))
	flash.pixel_size = randf_range(0.00021, 0.00029)
	flash.rotation.z = randf() * TAU
	smoke_timer = 0.24

func start_reload() -> void :
	reload_elapsed = 0.0
	reload_sound_step = 0

func _curve(t: float, points: Array) -> Vector3:
	if t <= float(points[0][0]): return points[0][1]
	for i in range(1, points.size()):
		if t <= float(points[i][0]):
			var weight: = smoothstep(float(points[i - 1][0]), float(points[i][0]), t)
			return (points[i - 1][1] as Vector3).lerp(points[i][1], weight)
	return points[-1][1]

func _reload_pose(t: float) -> void :
	if t > 0.3 and reload_sound_step == 0:
		foley.stream = Game.asset("rifle_magout.ogg")
		foley.play()
		reload_sound_step = 1
	if t > 1.6 and reload_sound_step == 1:
		foley.stream = Game.asset("rifle_magin.ogg")
		foley.play()
		reload_sound_step = 2
	if t > 2.04 and reload_sound_step == 2:
		foley.stream = Game.asset("bolt_fwd.ogg")
		foley.play()
		reload_sound_step = 3
	var tilt: = smoothstep(0, 0.28, t) * (1 - smoothstep(2.1, 2.45, t))
	rotation.z = -0.18 * tilt
	rotation.x = -0.1 * tilt
	position.y += 0.1 * tilt
	position.x -= 0.05 * tilt
	position.z -= 0.1 * tilt
	var offset: = _curve(t, [[0.0, Vector3.ZERO], [0.35, Vector3.ZERO], [0.78, Vector3(-0.25, -0.12, -0.1)], [1.0, Vector3(-0.25, -0.5, 0.1)], [1.13, Vector3(-0.22, -0.3, -0.05)], [1.65, Vector3.ZERO], [2.45, Vector3.ZERO]])
	if magazine:
		magazine.position = mag_rest.origin + offset
		magazine.rotation.x = 0.15 * sin(t * PI) * tilt
		magazine.visible = not (t > 0.97 and t < 1.09)
	if handle:
		handle.position = handle_rest + Vector3(0, 0, 0.085 * smoothstep(1.88, 2.02, t) * (1 - smoothstep(2.09, 2.18, t)))
	if skeleton and left_controller >= 0:
		var hand_offset: = _curve(t, [[0.0, Vector3.ZERO], [0.33, Vector3(0.08, -0.13, 0.1)], [0.78, Vector3(-0.12, -0.22, -0.05)], [1.05, Vector3(-0.12, -0.6, 0.2)], [1.2, Vector3(-0.13, -0.4, -0.02)], [1.66, Vector3(0.08, -0.13, 0.1)], [1.88, Vector3(0.09, 0.12, -0.07)], [2.03, Vector3(0.09, 0.12, 0.01)], [2.2, Vector3(0.04, 0.06, -0.02)], [2.45, Vector3.ZERO]])
		skeleton.set_bone_pose_position(left_controller, left_rest + hand_offset)
		skeleton.set_bone_pose_rotation(left_controller, left_rotation * Quaternion(Vector3.FORWARD, 0.2 * tilt))

func reset_parts() -> void :
	reload_elapsed = -1
	ads_blend = 0
	sprint_blend = 0
	fire_blend = 0
	flash_timer = 0
	smoke_timer = 0
	position = Vector3(0.2, -0.3, -0.22)
	rotation = Vector3.ZERO
	for cover in covers: cover.rotation.x = 0
	if flash: flash.hide()
	if smoke: smoke.modulate.a = 0
	if magazine:
		magazine.transform = mag_rest
		magazine.show()
	if handle: handle.position = handle_rest
	if skeleton and left_controller >= 0:
		skeleton.set_bone_pose_position(left_controller, left_rest)
		skeleton.set_bone_pose_rotation(left_controller, left_rotation)
	visible = true
