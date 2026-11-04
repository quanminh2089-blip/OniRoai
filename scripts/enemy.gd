extends CharacterBody3D
var world: Node3D
var player: CharacterBody3D
var bot_id = 0
var bot_name = ""
const MAX_HEALTH: int = 500
const BULLET_DAMAGE: int = 10
var health: int = MAX_HEALTH
var dead = false
var visual: Node3D
var anim: AnimationPlayer
var skeleton: Skeleton3D
var aim_pivot: Node3D
var gun: Node3D
var sound: AudioStreamPlayer3D
var steps: AudioStreamPlayer3D
var ik_solvers: Array[SkeletonIK3D] = []
var path = PackedVector3Array()
var waypoint = 0
var repath = 0.0
var scan_clock = 0.0
var cooldown = 0.0
var reaction = 0.0
var visible_target = false
var last_known = Vector3.INF
var memory = 0.0
var ammo = 30
var reserve = 180
var reload_time = 0.0
var burst_left = 3
var shots_fired = 0
var last_hit_player = false
var stride_clock = 0.0
var recoil = 0.0
var rng = RandomNumberGenerator.new()
const MAG_SIZE = 30
const RELOAD_DURATION = 2.45
var walk_name = "aim_walk"
func _ready() -> void :
	name = "Red_" + str(bot_id + 1);bot_name = ["BÁO", "SÓI", "ƯNG", "CÁO"][bot_id];rng.seed = 4900 + bot_id * 71 + world.round_number * 313;collision_layer = 4;collision_mask = 1 | 4
	var col = CollisionShape3D.new(); var capsule = CapsuleShape3D.new();capsule.height = 1.8;capsule.radius = 0.3;col.shape = capsule;col.position.y = 0.9;add_child(col)
	visual = Game.model("soldier.glb");visual.scale = Vector3.ONE * 0.85;add_child(visual)
	anim = visual.find_children("*", "AnimationPlayer", true, false)[0];skeleton = visual.find_children("*", "Skeleton3D", true, false)[0]
	for clip in ["idle", "aim_idle", "aim_walk", "aim_run", "ready_idle", "ready_walk"]:
		if anim.has_animation(clip): anim.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	aim_pivot = Node3D.new();aim_pivot.position = Vector3(-0.16, 1.2, 0.2);aim_pivot.rotation.y = PI;add_child(aim_pivot)
	gun = Node3D.new();gun.set_script(preload("res://scripts/npc_weapon.gd"));gun.scale = Vector3.ONE * 0.55;aim_pivot.add_child(gun)
	for entry in [["RightArm", "RightHand", Vector3(0, 0.02, 0.11)], ["LeftArm", "LeftHand", Vector3(-0.0166, 0.0675, -0.43)]]:
		var root_bone = _bone(entry[0]); var tip_bone = _bone(entry[1])
		if root_bone.is_empty() or tip_bone.is_empty(): continue
		var target = Marker3D.new();target.position = entry[2] * 0.55;aim_pivot.add_child(target)
		var ik = SkeletonIK3D.new();ik.root_bone = root_bone;ik.tip_bone = tip_bone;ik.influence = 1;ik.override_tip_basis = false;skeleton.add_child(ik);ik.target_node = ik.get_path_to(target);ik_solvers.append(ik)
	sound = AudioStreamPlayer3D.new();sound.max_distance = 52;sound.unit_size = 3;sound.volume_db = -17;sound.max_polyphony = 3;add_child(sound)
	steps = AudioStreamPlayer3D.new();steps.max_distance = 16;steps.unit_size = 2;steps.volume_db = -23;steps.stream = Game.asset("walking.ogg");add_child(steps)
	rotation.y = atan2(player.position.x - position.x, player.position.z - position.z);_animation("idle");call_deferred("_start_ik")
func _bone(suffix: String) -> String:
	for i in range(skeleton.get_bone_count()):
		var label = skeleton.get_bone_name(i)
		if label.ends_with(suffix): return label
	return ""
func _start_ik() -> void :
	if not dead:
		for ik in ik_solvers: ik.start()
func _animation(clip: String) -> void :
	if anim and anim.has_animation(clip) and (anim.current_animation != clip or not anim.is_playing()): anim.play(clip, 0.16)
func prepare_live() -> void :
	visible_target = false;reaction = [1.25, 0.95, 0.55][Game.bot_difficulty] + bot_id * 0.06;cooldown = 0.15 + bot_id * 0.08;scan_clock = 0;resume_animation()
func halt() -> void :
	velocity.x = 0;velocity.z = 0
	if anim and not dead: anim.pause()
func resume_animation() -> void :
	if not dead: _animation("idle")
func hear(at: Vector3) -> void :
	if not dead: last_known = at;memory = 6;repath = 0
func target_point() -> Vector3: return player.global_position + Vector3.UP * (0.76 if player.crouching else 1.2)
func can_see_player() -> bool:
	if dead or player.health <= 0: return false
	var at = global_position + Vector3.UP * 1.52; var target = target_point()
	if at.distance_to(target) > [22.0, 26.0, 30.0][Game.bot_difficulty]: return false
	var query = PhysicsRayQueryParameters3D.create(at, target, 1 | 2);query.exclude = [get_rid()]
	var hit = get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.collider == player
func _physics_process(delta: float) -> void :
	if dead or not world.playing: return
	cooldown = maxf(0, cooldown - delta);repath -= delta;memory = maxf(0, memory - delta);scan_clock -= delta
	if scan_clock <= 0:
		scan_clock = 0.11
		var sees = can_see_player()
		if sees and not visible_target: reaction = [1.25, 0.95, 0.55][Game.bot_difficulty] + rng.randf_range(0, 0.2)
		visible_target = sees
		if sees: last_known = player.global_position;memory = 7
	if reload_time > 0:
		reload_time = maxf(0, reload_time - delta);gun.reload(1 - reload_time / RELOAD_DURATION)
		if reload_time <= 0:
			var rounds = mini(MAG_SIZE - ammo, reserve);ammo += rounds;reserve -= rounds;gun.reload(0);_animation("idle")
		velocity.x = move_toward(velocity.x, 0, delta * 12);velocity.z = move_toward(velocity.z, 0, delta * 12)
	else: _decide(delta)
	if not is_on_floor(): velocity.y -= 20 * delta
	move_and_slide();recoil = move_toward(recoil, 0, delta * 4);aim_pivot.position.z = 0.2 - recoil * 0.025
	var moving = Vector2(velocity.x, velocity.z).length() > 0.3
	if reload_time <= 0: _animation("aim_walk" if moving else "idle")
	if moving and is_on_floor():
		stride_clock -= delta
		if stride_clock <= 0: steps.pitch_scale = rng.randf_range(0.9, 1.07);steps.play();stride_clock = 0.44
func _decide(delta: float) -> void :
	var direction = Vector3.ZERO
	if visible_target:
		var toward = target_point() - global_position; var horizontal = Vector3(toward.x, 0, toward.z)
		rotation.y = lerp_angle(rotation.y, atan2(toward.x, toward.z), 1 - exp( - delta * 10))
		aim_pivot.rotation.x = lerpf(aim_pivot.rotation.x, atan2(target_point().y - aim_pivot.global_position.y, maxf(horizontal.length(), 0.1)), 1 - exp( - delta * 12))
		reaction = maxf(0, reaction - delta)
		if horizontal.length() > 17: direction = _path_direction(last_known)
		elif horizontal.length() < 5: direction = - horizontal.normalized() * 0.55
		elif cooldown > 0.3 and burst_left == 3: direction = horizontal.normalized().cross(Vector3.UP) * (0.35 if bot_id % 2 == 0 else -0.35)
		if reaction <= 0 and cooldown <= 0:
			if ammo <= 0: reload_weapon()
			else: fire_at(target_point())
	else:
		var goal = last_known if memory > 0 and last_known.is_finite() else _route_goal();direction = _path_direction(goal)
		if direction.length_squared() > 0.01: rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), 1 - exp( - delta * 7))
		aim_pivot.rotation.x = lerpf(aim_pivot.rotation.x, 0, 1 - exp( - delta * 5))
	var speed = 2.3 if visible_target else 2.65
	velocity.x = move_toward(velocity.x, direction.x * speed, delta * 14);velocity.z = move_toward(velocity.z, direction.z * speed, delta * 14)
func _route_goal() -> Vector3:
	var route: Array = world.ROUTES[bot_id]
	if waypoint < route.size():
		if global_position.distance_to(route[waypoint]) < 1.7: waypoint += 1;repath = 0
		if waypoint < route.size(): return route[waypoint]
	var search = [Vector3(-13, 0, 16), Vector3(15, 0, 16), Vector3(15, 0, -18), Vector3(-13, 0, -18)]
	var target: Vector3 = search[(waypoint - route.size() + bot_id) % search.size()]
	if global_position.distance_to(target) < 1.8: waypoint += 1;repath = 0
	return target
func _path_direction(goal: Vector3) -> Vector3:
	if repath <= 0: path = world.path_between(global_position, goal);repath = 0.55 + rng.randf() * 0.2
	while path.size() > 1 and Vector2(path[0].x - global_position.x, path[0].z - global_position.z).length() < 0.55: path.remove_at(0)
	if path.is_empty(): return Vector3.ZERO
	var direction = path[0] - global_position;direction.y = 0;return direction.normalized()
func fire_at(target: Vector3, spread_override: float = -1) -> bool:
	if dead or not world.playing or reload_time > 0 or ammo <= 0: return false
	ammo -= 1;shots_fired += 1;world.shots_from_bots += 1;burst_left -= 1
	cooldown = 0.13 if burst_left > 0 else [1.15, 0.85, 0.58][Game.bot_difficulty]
	if burst_left <= 0: burst_left = 3
	recoil = 1;gun.fire();sound.stream = Game.asset("mp5_shot.ogg");sound.pitch_scale = rng.randf_range(0.88, 1.07);sound.play()
	var from: Vector3 = gun.muzzle.global_position; var direction = (target - from).normalized(); var right = direction.cross(Vector3.UP).normalized()
	var spread = spread_override if spread_override >= 0 else [0.065, 0.042, 0.023][Game.bot_difficulty]
	direction = (direction + right * rng.randf_range( - spread, spread) + Vector3.UP * rng.randf_range( - spread, spread)).normalized()
	var query = PhysicsRayQueryParameters3D.create(from, from + direction * 70, 1 | 2);query.exclude = [get_rid()]
	var hit = get_world_3d().direct_space_state.intersect_ray(query); var end = hit.position if not hit.is_empty() else from + direction * 45
	world.tracer(from, end, true);last_hit_player = not hit.is_empty() and hit.collider == player
	if not hit.is_empty():
		world.impact(hit.position, hit.normal)
		if last_hit_player: player.take_damage(BULLET_DAMAGE, global_position, bot_name)
	return last_hit_player
func reload_weapon() -> void :
	if dead or reload_time > 0 or reserve <= 0 or ammo == MAG_SIZE: return
	reload_time = RELOAD_DURATION;_animation("reload");sound.stream = Game.asset("rifle_magout.ogg");sound.play()
func take_hit(_amount: int, headshot: bool = false) -> void :
	if dead or not world.playing: return
	health = maxi(0, health - maxi(_amount, 0))
	if health > 0:
		# Không biến mất ở phát bắn đầu tiên; chỉ chết khi hết 500 HP.
		if sound:
			sound.stream = Game.asset("enemy_hurt.ogg")
			sound.play()
		return
	dead = true;collision_layer = 0;collision_mask = 0;velocity = Vector3.ZERO
	for ik in ik_solvers: ik.stop()
	_animation("death");sound.stream = Game.asset("enemy_destroy.ogg");sound.play();gun.hide();world.enemy_killed(global_position, headshot, bot_name)
