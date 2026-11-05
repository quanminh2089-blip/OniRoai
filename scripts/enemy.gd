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
# ESP là hiệu ứng trực tiếp trên model NPC nên không phụ thuộc HUD 2D.
const ESP_SHADER := preload("res://assets/oniroai/esp_enemy_green.gdshader")
var esp_material: ShaderMaterial
var esp_meshes: Array[MeshInstance3D] = []
var esp_original_overlays: Dictionary = {}
var esp_active: bool = false
var esp_update_clock: float = 0.0
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
# Tactical AI Extreme: 500 ms perception, 70% nominal aim, full squad coordination.
const EXTREME_REACTION := 0.5
const EXTREME_ACCURACY := 0.70
const SQUAD_COORDINATION := 1.0
var role: String = ""
var stance_clock := 0.0
var dodge_clock := 0.0
var strafe_sign := 1.0
var crouch_amount := 0.0
var lean_amount := 0.0
var tactical_goal := Vector3.INF
var last_seen_age := 99.0
# v1.6: chiến thuật theo trạng thái, dùng vật chắn và chia góc tấn công.
var cover_goal := Vector3.INF
var peek_goal := Vector3.INF
var cover_refresh := 0.0
var peek_refresh := 0.0
var threatened_time := 0.0
var dodge_time := 0.0
var tactical_state := "ADVANCE"
var combat_motion_time := 0.0
var combat_motion_sign := 1.0
var hit_count := 0
var body_collision: CollisionShape3D
var body_capsule: CapsuleShape3D
var peek_side := 1.0
var safe_last_known := Vector3.INF
var recent_exposure := 0.0

func _ready() -> void :
	name = "Red_" + str(bot_id + 1);bot_name = ["CHỈ HUY", "TIÊN PHONG", "THIỆN XẠ", "ĐÁNH VÒNG", "HỖ TRỢ"][bot_id];role = ["commander", "assault", "marksman", "flanker", "support"][bot_id];rng.seed = 4900 + bot_id * 71 + world.round_number * 313;collision_layer = 4;collision_mask = 1 | 4
	var col = CollisionShape3D.new(); var capsule = CapsuleShape3D.new();capsule.height = 1.8;capsule.radius = 0.3;col.shape = capsule;col.position.y = 0.9;add_child(col);body_collision = col;body_capsule = capsule
	visual = Game.model("soldier.glb");visual.scale = Vector3.ONE * 0.85;add_child(visual)
	_setup_esp_visuals()
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
# Giữ nguyên vật liệu gốc để khi TẮT ESP, NPC trở lại bình thường.
# Overlay dùng chính các MeshInstance3D của mẫu nhân vật, theo chuyển động xương.
func _setup_esp_visuals() -> void:
    esp_material = ShaderMaterial.new()
    esp_material.shader = ESP_SHADER
    for child in visual.find_children("*", "MeshInstance3D", true, false):
        var mesh: MeshInstance3D = child as MeshInstance3D
        if mesh == null:
            continue
        esp_meshes.append(mesh)
        esp_original_overlays[mesh] = mesh.material_overlay

func _set_esp_active(enabled: bool) -> void:
    if esp_active == enabled:
        return
    esp_active = enabled
    for mesh in esp_meshes:
        if is_instance_valid(mesh):
            mesh.material_overlay = esp_material if enabled else esp_original_overlays.get(mesh)
    esp_update_clock = 0.0

func _process(_delta: float) -> void:
    var enabled: bool = Game.esp_enabled and not dead and is_instance_valid(world) and world.playing and not world.paused
    if enabled != esp_active:
        _set_esp_active(enabled)
    if not enabled:
        return

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
func prepare_live() -> void:
	visible_target = false
	reaction = EXTREME_REACTION
	cooldown = 0.15 + bot_id * 0.08
	scan_clock = 0.0
	cover_refresh = 0.0
	peek_refresh = 0.0
	threatened_time = 0.0
	dodge_time = 0.0
	combat_motion_time = 0.0
	cover_goal = Vector3.INF
	peek_goal = Vector3.INF
	recent_exposure = 0.0
	resume_animation()
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
	var at := global_position + Vector3.UP * (1.05 if crouch_amount < -0.2 else 1.52)
	var target := target_point()
	var detection := [29.0, 34.0, 40.0][Game.bot_difficulty]
	if role == "marksman": detection += 6.0
	if at.distance_to(target) > detection: return false
	var query := PhysicsRayQueryParameters3D.create(at, target, 1 | 2)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.collider == player
func _physics_process(delta: float) -> void:
	if dead or not world.playing: return
	cooldown = maxf(0.0, cooldown - delta)
	repath -= delta
	memory = maxf(0.0, memory - delta)
	scan_clock -= delta
	last_seen_age += delta
	stance_clock -= delta
	dodge_clock -= delta
	cover_refresh -= delta
	peek_refresh -= delta
	threatened_time = maxf(0.0, threatened_time - delta)
	dodge_time = maxf(0.0, dodge_time - delta)
	combat_motion_time -= delta
	if scan_clock <= 0.0:
		scan_clock = 0.12 + float(bot_id) * 0.013
		var sees := can_see_player()
		if sees and not visible_target: reaction = EXTREME_REACTION
		visible_target = sees
		if sees:
			last_known = player.global_position
			memory = 7.0
			last_seen_age = 0.0
			world.squad_report(player.global_position, bot_id)
	if reload_time > 0.0:
		reload_time = maxf(0.0, reload_time - delta)
		gun.reload(1.0 - reload_time / RELOAD_DURATION)
		if reload_time <= 0.0:
			var rounds := mini(MAG_SIZE - ammo, reserve)
			ammo += rounds
			reserve -= rounds
			gun.reload(0)
			_animation("idle")
		# Không quay lưng bỏ chạy khi nạp: tìm chỗ che hoặc di chuyển ngang.
		_reload_movement(delta)
	else:
		_decide(delta)
	if not is_on_floor(): velocity.y -= 20.0 * delta
	move_and_slide()
	# Hitbox thật đi theo tư thế NPC, tránh kiểu ngồi chỉ dịch model.
	var stance_target := -0.34 if stance_clock > 0.0 or tactical_state == "COVER" else 0.0
	crouch_amount = lerpf(crouch_amount, stance_target, minf(1.0, delta * 8.0))
	var crouch_ratio := clampf(-crouch_amount / 0.34, 0.0, 1.0)
	visual.scale.y = 0.85 * (1.0 - crouch_ratio * 0.24)
	body_capsule.height = 1.8 - crouch_ratio * 0.43
	body_collision.position.y = body_capsule.height * 0.5
	lean_amount = lerpf(lean_amount, combat_motion_sign * 0.12 if dodge_time > 0.0 else 0.0, minf(1.0, delta * 9.0))
	visual.rotation.z = lean_amount
	aim_pivot.position.y = 1.2 + crouch_amount
	recoil = move_toward(recoil, 0.0, delta * 4.0)
	aim_pivot.position.z = 0.2 - recoil * 0.025
	var moving := Vector2(velocity.x, velocity.z).length() > 0.3
	if reload_time <= 0.0: _animation("aim_walk" if moving else "idle")
	if moving and is_on_floor():
		stride_clock -= delta
		if stride_clock <= 0.0:
			steps.pitch_scale = rng.randf_range(0.9, 1.07)
			steps.play()
			stride_clock = 0.44
func _cover_direction() -> Vector3:
	if not is_instance_valid(player): return Vector3.ZERO
	var away = global_position - player.global_position
	away.y = 0
	return away.normalized() if away.length_squared() > 0.01 else Vector3.ZERO

func _role_goal() -> Vector3:
	if world.squad_memory > 0.0:
		return world.squad_goal(bot_id)
	return _route_goal()
func _reload_movement(delta: float) -> void:
	var goal := cover_goal
	if not goal.is_finite() and world.squad_memory > 0.0:
		goal = _role_goal()
	var direction := _path_direction(goal) if goal.is_finite() else _cover_direction()
	if direction.length_squared() < 0.01: direction = _cover_direction()
	velocity.x = move_toward(velocity.x, direction.x * 2.5, delta * 14.0)
	velocity.z = move_toward(velocity.z, direction.z * 2.5, delta * 14.0)
	stance_clock = maxf(stance_clock, 0.28)

func _pick_cover(threat: Vector3) -> void:
	if cover_refresh > 0.0: return
	cover_refresh = rng.randf_range(1.5, 2.4)
	var selected: Vector3 = world.find_cover(global_position, threat, bot_id)
	if selected.is_finite():
		cover_goal = selected
		repath = 0.0
		peek_goal = Vector3.INF
		peek_refresh = 0.0

func _peek_target(threat: Vector3) -> Vector3:
	if peek_refresh > 0.0 and peek_goal.is_finite(): return peek_goal
	peek_refresh = rng.randf_range(1.0, 1.6)
	peek_side = -peek_side if rng.randf() < 0.4 else peek_side
	peek_goal = world.find_peek(cover_goal, threat, peek_side)
	repath = 0.0
	return peek_goal

func _combat_dodge(delta: float, toward: Vector3) -> Vector3:
	if combat_motion_time <= 0.0:
		combat_motion_time = rng.randf_range(0.45, 1.0)
		combat_motion_sign = -combat_motion_sign if rng.randf() < 0.8 else combat_motion_sign
		if rng.randf() < 0.35 or threatened_time > 1.5:
			stance_clock = rng.randf_range(0.35, 0.7)
		elif is_on_floor() and rng.randf() < 0.12:
			velocity.y = 5.5
	var lateral := Vector3(-toward.z, 0.0, toward.x) * combat_motion_sign
	var length_h := Vector2(player.position.x - position.x, player.position.z - position.z).length()
	var desired := [11.0, 6.5, 17.0, 9.0, 12.0][bot_id]
	var radial := toward * (0.6 if length_h > desired + 2.0 else (-0.6 if length_h < desired - 2.0 else 0.0))
	return (lateral * 0.8 + radial).normalized()

func _decide(delta: float) -> void:
	var threat: Vector3 = world.squad_last_known if world.squad_memory > 0.0 else last_known
	var has_contact := threat.is_finite() and (world.squad_memory > 0.0 or memory > 0.0)
	var direction := Vector3.ZERO
	var goal := Vector3.INF
	tactical_state = "ADVANCE"
	if visible_target:
		var toward := target_point() - global_position
		var planar := Vector3(toward.x, 0.0, toward.z)
		rotation.y = lerp_angle(rotation.y, atan2(toward.x, toward.z), 1.0 - exp(-delta * 10.0))
		aim_pivot.rotation.x = lerpf(aim_pivot.rotation.x, atan2(target_point().y - aim_pivot.global_position.y, maxf(planar.length(), 0.1)), 1.0 - exp(-delta * 12.0))
		reaction = maxf(0.0, reaction - delta)
	else:
		aim_pivot.rotation.x = lerpf(aim_pivot.rotation.x, 0.0, 1.0 - exp(-delta * 5.0))
	# Người bị bắn phải tìm vật chắn. Các vai trò giữ vị trí hỗ trợ khi có giao tranh.
	var force_push := world.squad_progress_age > 13.0 and threatened_time <= 0.0
	var prefer_cover := (role in ["commander", "marksman", "support"] and not force_push) or threatened_time > 0.0 or health < 220
	if has_contact and prefer_cover:
		_pick_cover(threat)
	if has_contact and cover_goal.is_finite() and prefer_cover:
		var distance_to_cover := Vector2(cover_goal.x - global_position.x, cover_goal.z - global_position.z).length()
		if distance_to_cover > 1.2:
			tactical_state = "RELOCATE"
			goal = cover_goal
		else:
			var is_hidden := not world.point_exposed(global_position, threat, true)
			var do_peek := world.squad_peek_window(bot_id) and threatened_time < 0.65
			if is_hidden and not do_peek:
				tactical_state = "COVER"
				stance_clock = maxf(stance_clock, 0.3)
			elif is_hidden and do_peek:
				var peek := _peek_target(threat)
				if peek.is_finite():
					tactical_state = "PEEK"
					goal = peek
				else:
					goal = _role_goal()
			else:
				tactical_state = "EXPOSED"
				goal = cover_goal if threatened_time > 0.0 else _role_goal()
	elif has_contact:
		tactical_state = "FLANK" if role == "flanker" else "PRESSURE"
		goal = _role_goal()
	else:
		goal = _route_goal()
	# Không chạy xuyên tường: tất cả mục tiêu chiến thuật đi qua A*.
	if goal.is_finite() and tactical_state != "COVER":
		direction = _path_direction(goal)
	elif visible_target and tactical_state != "COVER":
		var toward_player := player.global_position - global_position
		toward_player.y = 0.0
		if toward_player.length_squared() > 0.01:
			direction = _combat_dodge(delta, toward_player.normalized())
	if visible_target and tactical_state in ["PRESSURE", "FLANK", "EXPOSED"]:
		var toward_player := player.global_position - global_position
		toward_player.y = 0.0
		if toward_player.length_squared() > 0.1:
			var evasive := _combat_dodge(delta, toward_player.normalized())
			# Va chạm vật cản trong lối né để không tự chạy vào tường.
			var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP, global_position + Vector3.UP + evasive * 1.4, 1)
			if get_world_3d().direct_space_state.intersect_ray(query).is_empty():
				direction = (direction * 0.8 + evasive * (0.7 if threatened_time > 0.0 else 0.35)).normalized()
	if visible_target and tactical_state == "EXPOSED" and threatened_time > 0.0:
		var away := _cover_direction()
		direction = (direction + away * 0.65).normalized()
	if not visible_target and direction.length_squared() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), 1.0 - exp(-delta * 7.0))
	var speed := 3.8 if role == "flanker" else (3.4 if role == "assault" else 3.0)
	if tactical_state == "RELOCATE" or tactical_state == "FLANK": speed *= 1.25
	if tactical_state == "COVER": speed = 0.0
	velocity.x = move_toward(velocity.x, direction.x * speed, delta * 14.0)
	velocity.z = move_toward(velocity.z, direction.z * speed, delta * 14.0)
	# Chỉ bắn khi nhìn thấy mục tiêu thật, đã phản ứng đủ 500 ms.
	# Từ điểm nấp không xả đạn xuyên tường; khi thay đạn tiếp tục giữ đội hình.
	if visible_target and tactical_state != "COVER" and reaction <= 0.0 and cooldown <= 0.0:
		if ammo <= 0: reload_weapon()
		else: fire_at(target_point())
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
	# 70% nominal hit probability: deliberately offset 30% of shots.
	var spread = spread_override if spread_override >= 0 else (0.012 if rng.randf() < EXTREME_ACCURACY else 0.16)
	direction = (direction + right * rng.randf_range( - spread, spread) + Vector3.UP * rng.randf_range( - spread, spread)).normalized()
	var query = PhysicsRayQueryParameters3D.create(from, from + direction * 70, 1 | 2);query.exclude = [get_rid()]
	var hit = get_world_3d().direct_space_state.intersect_ray(query); var end = hit.position if not hit.is_empty() else from + direction * 45
	world.tracer(from, end, true);last_hit_player = not hit.is_empty() and hit.collider == player
	if not hit.is_empty():
		world.impact(hit.position, hit.normal)
		if last_hit_player:
			world.squad_progress_age = 0.0
			player.take_damage(BULLET_DAMAGE, global_position, bot_name)
	return last_hit_player
func reload_weapon() -> void :
	if dead or reload_time > 0 or reserve <= 0 or ammo == MAG_SIZE: return
	reload_time = RELOAD_DURATION;_animation("reload");sound.stream = Game.asset("rifle_magout.ogg");sound.play()
func take_hit(_amount: int, headshot: bool = false) -> void :
	if dead or not world.playing: return
	health = maxi(0, health - maxi(_amount, 0))
	hit_count += 1
	world.squad_progress_age = 0.0
	threatened_time = 3.5
	cover_refresh = 0.0
	dodge_time = 0.65
	combat_motion_time = 0.0
	if health > 0:
		stance_clock = 0.6
		dodge_clock = 0.0
		world.squad_under_fire(player.global_position + Vector3(rng.randf_range(-1.5, 1.5), 0, rng.randf_range(-1.5, 1.5)), bot_id)
		# Không biến mất ở phát bắn đầu tiên; chỉ chết khi hết 500 HP.
		if sound:
			sound.stream = Game.asset("enemy_hurt.ogg")
			sound.play()
		return
	_set_esp_active(false)
	dead = true;collision_layer = 0;collision_mask = 0;velocity = Vector3.ZERO
	for ik in ik_solvers: ik.stop()
	_animation("death");sound.stream = Game.asset("enemy_destroy.ogg");sound.play();gun.hide();world.enemy_killed(global_position, headshot, bot_name)
