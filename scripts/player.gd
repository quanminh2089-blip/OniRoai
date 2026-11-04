extends CharacterBody3D

var camera: Camera3D
var weapon_rig: Node3D
var weapon: Node3D
var world: Node3D
const MAX_HEALTH: float = 500.0
const BULLET_DAMAGE: float = 10.0
const HEADSHOT_DAMAGE: int = 250
var health: float = MAX_HEALTH
var ammo: int = 30
var reserve: int = 900
var cooldown: float = 0.0
var reload_time: float = 0.0
var recoil: float = 0.0
var walk_phase: float = 0.0
var step_time: float = 0.0
var hurt_time: float = 0.0
var aiming: bool = false
var running: bool = false
var fire_held: bool = false
var crouching: bool = false
var lean_direction: int = 0 # -1 trai / 0 dung / 1 phai
var lean_amount: float = 0.0
const LEAN_DISTANCE: float = 0.38
const LEAN_ANGLE: float = 0.20
var body_shape: CollisionShape3D
var recoil_pitch: float = 0.0
var recoil_yaw: float = 0.0
var look_sway = Vector2.ZERO
var shots_fired: int = 0
var medkits: int = 0
var heal_time: float = 0.0
var move_input: = Vector2.ZERO
var pitch: float = 0.0
var sound: AudioStreamPlayer
var footsteps: AudioStreamPlayer
var muzzle: MeshInstance3D
var light_flash: OmniLight3D
var flash_time: float = 0.0
const MAG_SIZE: int = 30
const RELOAD_DURATION: float = 2.45
const HEAL_DURATION: float = 3.0

func _ready() -> void :
	name = "Player"
	collision_layer = 2
	collision_mask = 1
	var shape: = CollisionShape3D.new()
	var capsule: = CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.8
	shape.shape = capsule
	shape.position.y = 0.9
	add_child(shape)
	body_shape = shape
	camera = Camera3D.new()
	camera.position.y = 1.65
	camera.near = 0.04
	camera.far = 150
	camera.fov = 78
	camera.current = true
	add_child(camera)
	weapon_rig = Node3D.new()
	weapon_rig.set_script(preload("res://scripts/weapon_view.gd"))
	weapon_rig.player = self
	camera.add_child(weapon_rig)
	light_flash = OmniLight3D.new()
	light_flash.omni_range = 1.25
	light_flash.light_color = Color("ffd590")
	light_flash.light_energy = 0.0
	camera.add_child(light_flash)
	sound = AudioStreamPlayer.new()
	sound.stream = Game.asset("mp5_shot.ogg")
	sound.volume_db = -12
	sound.max_polyphony = 5
	add_child(sound)
	footsteps = AudioStreamPlayer.new()
	footsteps.stream = Game.asset("walking.ogg")
	footsteps.volume_db = -20
	add_child(footsteps)

func look(delta: Vector2, screen_pixels: bool = false) -> void :
	if not world.playing:
		return
	var height = float(get_window().size.y) if screen_pixels else get_viewport().get_visible_rect().size.y
	var relative = delta * (720.0 / maxf(height, 1))
	var multiplier: float = Game.ads_sensitivity if aiming else 1.0
	rotation.y -= relative.x * Game.sensitivity * multiplier
	pitch = clampf(pitch - relative.y * Game.sensitivity * multiplier, -1.35, 1.35)
	look_sway = (look_sway + relative * 0.025).limit_length(1.0)

func _unhandled_input(event: InputEvent) -> void :


	if event is InputEventMouse and (OS.has_feature("mobile") or event.device == InputEvent.DEVICE_ID_EMULATION):
		return
	if not world.playing:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		look(event.relative)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		fire_held = event.pressed
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_R:
			reload_weapon()
		if event.physical_keycode == KEY_SPACE:
			jump()
		if event.physical_keycode == KEY_C: toggle_crouch()
		if event.physical_keycode == KEY_Q: toggle_lean(-1)
		if event.physical_keycode == KEY_E: toggle_lean(1)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		aiming = event.pressed

func _physics_process(delta: float) -> void :
	if not world.playing:
		return
	cooldown = maxf(0.0, cooldown - delta)
	hurt_time = maxf(0.0, hurt_time - delta)
	flash_time = maxf(0.0, flash_time - delta)
	_heal_step(delta)
	light_flash.light_energy = 0.45 if flash_time > 0 and Game.quality > 0 else 0.0
	if weapon_rig.muzzle_socket: light_flash.global_position = weapon_rig.muzzle_socket.global_position
	if reload_time > 0:
		reload_time -= delta
		if reload_time <= 0:
			var rounds: = mini(MAG_SIZE - ammo, reserve)
			ammo += rounds
			reserve -= rounds
			Game.hud.notify("Đã thay đạn", 1.0)
	var input_dir: = move_input
	if not OS.has_feature("mobile"):
		input_dir += Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), 
			float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
	input_dir = input_dir.limit_length(1.0)
	var sprint: = (running or Input.is_physical_key_pressed(KEY_SHIFT)) and not aiming and not crouching and not fire_held and reload_time <= 0 and heal_time <= 0
	var speed: float = (5.8 if sprint else 3.6) * (0.68 if aiming else 1.0) * (0.55 if crouching else 1.0)
	if heal_time > 0: speed = 0.0
	var direction: = transform.basis * Vector3(input_dir.x, 0, input_dir.y)
	velocity.x = move_toward(velocity.x, direction.x * speed, delta * 22.0)
	velocity.z = move_toward(velocity.z, direction.z * speed, delta * 22.0)
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	move_and_slide()
	var moving: = Vector2(velocity.x, velocity.z).length() > 0.5 and is_on_floor()
	if moving:
		walk_phase += delta * (12.0 if sprint else 8.5)
		step_time -= delta
		if step_time <= 0:
			footsteps.pitch_scale = randf_range(0.9, 1.1)
			footsteps.volume_db = -28 if crouching else -20
			footsteps.play()
			world.heard_player_footstep(global_position, crouching)
			step_time = 0.27 if sprint else 0.43
	recoil = move_toward(recoil, 0.0, delta * 2.5)
	recoil_pitch = move_toward(recoil_pitch, 0.0, delta * 0.12)
	recoil_yaw = move_toward(recoil_yaw, 0.0, delta * 0.045)
	look_sway = look_sway.lerp(Vector2.ZERO, 1 - exp( - delta * 12))
	var bob = sin(walk_phase) * 0.014 * Game.camera_motion if moving else 0.0
	camera.position.y = lerpf(camera.position.y, (1.02 if crouching else 1.65) + bob, 1 - exp( - delta * 12))
	# Nghiêng người kiểu shooter: dịch điểm ngắm sang ngang và nghiêng góc camera.
	# Quét va chạm để camera không xuyên qua tường khi tựa sát vật cản.
	var lean_target: float = float(lean_direction) * LEAN_DISTANCE
	if absf(lean_target) > 0.01:
		var from: Vector3 = global_position + Vector3.UP * (1.02 if crouching else 1.65)
		var to: Vector3 = from + global_basis.x * lean_target
		var query := PhysicsRayQueryParameters3D.create(from, to, 1)
		query.exclude = [get_rid()]
		var wall_hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
		if not wall_hit.is_empty():
			lean_target = signf(lean_target) * maxf(0.0, from.distance_to(wall_hit.position) - 0.1)
	lean_amount = lerpf(lean_amount, lean_target, 1.0 - exp(-delta * 13.0))
	camera.position.x = lean_amount
	camera.rotation.x = clampf(pitch + recoil_pitch, -1.4, 1.4)
	camera.rotation.y = recoil_yaw
	camera.rotation.z = lerpf(camera.rotation.z, -input_dir.x * 0.012 * Game.camera_motion - lean_amount / LEAN_DISTANCE * LEAN_ANGLE, 1 - exp(-delta * 13.0))
	camera.fov = lerpf(camera.fov, 48.0 if aiming and reload_time <= 0 else (81.0 if sprint and moving else (71.0 if fire_held else 75.0)), 1 - exp( - delta * 12))
	# Aim Đầu: chọn địch hiện trên màn hình, có đường bắn thông suốt.
	_update_head_aim(delta)
	camera.rotation.x = clampf(pitch + recoil_pitch, -1.4, 1.4)
	if fire_held:
		shoot()

# Hỗ trợ ngắm đầu chỉ trong game OniRoai, không tác động ứng dụng khác.
# Không tự bắn và không khóa mục tiêu xuyên tường.
func _update_head_aim(delta: float) -> void:
	if not Game.head_aim_enabled or not (aiming or fire_held):
		return
	if not is_instance_valid(world.enemies) or health <= 0:
		return
	var origin: Vector3 = camera.global_position
	var forward: Vector3 = -camera.global_basis.z
	var best_target := Vector3.INF
	var best_score := 100.0
	for enemy in world.enemies.get_children():
		if enemy.dead:
			continue
		var target: Vector3 = enemy.global_position + Vector3.UP * 1.58
		var diff: Vector3 = target - origin
		var distance := diff.length()
		if distance < 0.7 or distance > 65.0:
			continue
		var angle := forward.angle_to(diff.normalized())
		if angle > deg_to_rad(28.0):
			continue
		var query := PhysicsRayQueryParameters3D.create(origin, target, 1 | 4)
		query.exclude = [get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty() or hit.collider != enemy:
			continue
		var score := angle + distance * 0.0009
		if score < best_score:
			best_score = score
			best_target = target
	if not best_target.is_finite():
		return
	var direction: Vector3 = best_target - camera.global_position
	var horizontal := Vector2(direction.x, direction.z).length()
	var desired_yaw := atan2(-direction.x, -direction.z)
	var desired_pitch := atan2(direction.y, maxf(horizontal, 0.001))
	var strength := 1.0 - exp(-delta * (21.0 if fire_held else 13.5))
	rotation.y = lerp_angle(rotation.y, desired_yaw, strength)
	pitch = clampf(lerpf(pitch, desired_pitch - recoil_pitch, strength), -1.35, 1.35)

func toggle_lean(side: int) -> void:
	if not world.playing or health <= 0:
		return
	side = clampi(side, -1, 1)
	lean_direction = 0 if side == lean_direction else side

func toggle_crouch() -> bool:
	if not world.playing: return false
	if crouching:
		var capsule = CapsuleShape3D.new()
		capsule.radius = 0.31
		capsule.height = 1.74
		var query = PhysicsShapeQueryParameters3D.new()
		query.shape = capsule
		query.transform = Transform3D(global_transform.basis, global_position + Vector3.UP * 0.94)
		query.collision_mask = 1
		query.exclude = [get_rid()]
		query.margin = 0.005
		if not get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
			Game.hud.notify("Chưa đủ chỗ để đứng lên", 1.3)
			return false
	crouching = not crouching
	_apply_stance()
	return true

func _apply_stance() -> void :
	var height = 1.15 if crouching else 1.8
	body_shape.shape.height = height
	body_shape.position.y = height * 0.5

func shot_spread() -> float:
	var moving = Vector2(velocity.x, velocity.z).length()
	var spread = (0.0018 if aiming else 0.009) + minf(moving, 5.8) * (0.001 if aiming else 0.0025)
	spread += recoil * (0.001 if aiming else 0.006)
	return spread * (0.65 if crouching else 1.0)

func heal() -> bool:
	if not world.playing or heal_time > 0 or reload_time > 0: return false
	if medkits <= 0:
		Game.hud.notify("Đã hết túi cứu thương", 1.3)
		return false
	if health >= MAX_HEALTH:
		Game.hud.notify("Máu đã đầy", 1.1)
		return false
	if move_input.length() > 0.2 or fire_held:
		Game.hud.notify("Đứng yên để dùng cứu thương", 1.3)
		return false
	aiming = false
	running = false
	heal_time = HEAL_DURATION
	return true

func _heal_step(delta: float) -> void :
	if heal_time <= 0: return
	if fire_held or aiming or running or move_input.length() > 0.2:
		heal_time = 0
		Game.hud.notify("Đã hủy hồi phục", 1.0)
		return
	heal_time = maxf(0, heal_time - delta)
	if heal_time <= 0:
		health = minf(MAX_HEALTH, health + 45)
		medkits -= 1
		Game.hud.notify("+45 máu", 1.2)

func reset_mobile_state() -> void :
	crouching = false
	lean_direction = 0
	lean_amount = 0.0
	_apply_stance()
	camera.position.x = 0.0
	camera.position.y = 1.65
	camera.fov = 75
	camera.rotation = Vector3.ZERO
	recoil = 0
	recoil_pitch = 0
	recoil_yaw = 0
	shots_fired = 0
	look_sway = Vector2.ZERO
	medkits = 0
	heal_time = 0
	cooldown = 0
	hurt_time = 0

func jump() -> void :
	if crouching:
		toggle_crouch()
		return
	if world.playing and is_on_floor():
		velocity.y = 6.3

func reload_weapon() -> void :
	if not world.playing or reload_time > 0 or ammo == MAG_SIZE or reserve == 0:
		return
	aiming = false
	heal_time = 0
	reload_time = RELOAD_DURATION
	weapon_rig.start_reload()

func shoot() -> void :
	if not world.playing or cooldown > 0 or reload_time > 0:
		return
	if ammo <= 0:
		reload_weapon()
		return
	ammo -= 1
	world.heard_player_shot(global_position)
	heal_time = 0
	shots_fired += 1
	cooldown = 0.09
	recoil = minf(recoil + 0.24, 0.9)
	flash_time = 0.022
	weapon_rig.trigger_flash()
	sound.pitch_scale = randf_range(0.94, 1.06)
	sound.play()
	var origin: = camera.global_position
	var spread: = shot_spread()
	var direction: = - camera.global_basis.z + camera.global_basis.x * randf_range( - spread, spread) + camera.global_basis.y * randf_range( - spread, spread)
	var query: = PhysicsRayQueryParameters3D.create(origin, origin + direction * 85, 1 | 4)
	query.exclude = [get_rid()]
	var hit: = get_world_3d().direct_space_state.intersect_ray(query)
	var endpoint = hit.position if not hit.is_empty() else origin + direction * 60
	if weapon_rig.muzzle_socket: world.tracer(weapon_rig.muzzle_socket.global_position, endpoint, false)
	if not hit.is_empty():
		if hit.collider.has_method("take_hit"):
			var headshot: bool = hit.position.y - hit.collider.global_position.y > 1.35
			hit.collider.take_hit(HEADSHOT_DAMAGE if headshot else int(BULLET_DAMAGE), headshot)
			Game.hud.show_hit(headshot)
		world.impact(hit.position, hit.normal)

	recoil_pitch = minf(recoil_pitch + (0.012 if aiming else 0.017) * (0.72 if crouching else 1.0), 0.13)
	recoil_yaw = clampf(recoil_yaw + [0.0012, -0.0008, 0.0015, -0.001][shots_fired % 4], -0.015, 0.015)

func take_damage(_amount: float, source: Vector3 = Vector3.INF, killer: String = "ĐỘI ĐỎ") -> void :
	if health <= 0 or not world.playing:
		return
	health = maxf(0.0, health - maxf(_amount, 0.0))
	hurt_time = 0.6
	heal_time = 0
	Game.hud.damage_flash()
	if source.is_finite(): Game.hud.show_damage_from(source)
	if health <= 0:
		world.player_killed(killer)
