extends Node3D
enum Phase{LOBBY, COUNTDOWN, LIVE, ROUND_OVER, MATCH_OVER}
const TARGET_SCORE = 4
const PLAYER_SPAWN = Vector3(-12, 0.15, 18)
const BOT_SPAWNS = [Vector3(-13, 0.15, -20), Vector3(-5, 0.15, -22), Vector3(5, 0.15, -22), Vector3(13, 0.15, -20), Vector3(0, 0.15, -24)]
const ROUTES = [
	[Vector3(-13, 0, -12), Vector3(-14, 0, -3), Vector3(-12, 0, 10), Vector3(-12, 0, 18)], 
	[Vector3(-5, 0, -13), Vector3(-7, 0, -3), Vector3(-5, 0, 7), Vector3(-10, 0, 17)], 
	[Vector3(4, 0, -12), Vector3(5, 0, -2), Vector3(5, 0, 10), Vector3(-8, 0, 18)], 
	[Vector3(16, 0, -12), Vector3(16, 0, 0), Vector3(15, 0, 16), Vector3(-10, 0, 18)],
	[Vector3(0, 0, -16), Vector3(0, 0, -7), Vector3(3, 0, 4), Vector3(0, 0, 15)]]
# Tactical AI v1.6: thông tin liên lạc dựa trên quan sát, không nhìn xuyên tường.
var squad_last_known := Vector3.INF
var squad_memory := 0.0
var squad_commander_alive := true
var squad_order_age := 0.0
var squad_focus := Vector3.INF
var squad_plan := "crossfire"
var squad_damage_pressure := 0.0
var squad_last_reporter := -1
var squad_progress_age := 0.0

func squad_report(at: Vector3, reporter: int) -> void:
	if not at.is_finite(): return
	squad_last_known = at
	squad_memory = 7.0
	squad_last_reporter = reporter
	if squad_order_age <= 0.0:
		_refresh_squad_plan()

func squad_under_fire(at: Vector3, reporter: int) -> void:
	squad_report(at, reporter)
	squad_damage_pressure = minf(1.0, squad_damage_pressure + 0.22)
	squad_order_age = 0.0

func _refresh_squad_plan() -> void:
	if not squad_last_known.is_finite(): return
	squad_focus = squad_last_known
	# Chỉ huy thay đổi thế trận; cả đội nhận lệnh từ dữ liệu quan sát chung.
	var cycle := int(floor(elapsed / 8.0))
	var plans := ["crossfire", "pinch", "pressure", "reposition"]
	squad_plan = "pressure" if squad_progress_age > 13.0 else plans[(cycle + round_number) % plans.size()]
	squad_order_age = 2.5 if squad_commander_alive else 4.5

func squad_goal(bot_id: int) -> Vector3:
	if not squad_focus.is_finite(): return Vector3.INF
	var enemy_home := Vector3(0, 0, -19)
	var forward := enemy_home - squad_focus
	forward.y = 0.0
	if forward.length_squared() < 0.1: forward = Vector3.FORWARD
	forward = forward.normalized()
	var side := Vector3(-forward.z, 0.0, forward.x)
	var depth := [13.0, 6.5, 17.0, -1.5, 11.0][bot_id]
	var lateral := [-2.0, 3.5, -9.0, 12.5, 8.0][bot_id]
	if squad_plan == "pinch":
		lateral *= 1.3
	elif squad_plan == "pressure":
		depth -= 3.0
	elif squad_plan == "reposition":
		lateral = -lateral
	var raw := squad_focus + forward * depth + side * lateral
	raw.x = clampf(raw.x, -20.0, 20.0)
	raw.z = clampf(raw.z, -24.0, 24.0)
	var cell := free_cell(raw)
	return Vector3(cell.x, 0.0, cell.y)

func squad_peek_window(bot_id: int) -> bool:
	# Cửa sổ bắn lệch pha: giữ áp lực trong khi đồng đội di chuyển.
	var offset := [0.0, 1.1, 2.1, 3.0, 4.0][bot_id]
	var window := fposmod(elapsed + offset, 5.3)
	return window < (2.7 if bot_id == 2 or bot_id == 4 else 2.1)

func point_exposed(at: Vector3, threat: Vector3, low: bool = false) -> bool:
	if not at.is_finite() or not threat.is_finite(): return false
	var origin := threat + Vector3.UP * 1.4
	var target := at + Vector3.UP * (0.85 if low else 1.45)
	var query := PhysicsRayQueryParameters3D.create(origin, target, 1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func find_cover(from: Vector3, threat: Vector3, bot_id: int) -> Vector3:
	if not threat.is_finite(): return Vector3.INF
	var best := Vector3.INF
	var best_score := -100000.0
	var desired := [12.0, 7.0, 18.0, 10.0, 13.0][bot_id]
	# Chỉ kiểm tra các ô ở rìa vật chắn thật có collider + đường đi hợp lệ.
	for rect in blocked:
		var cx := rect.position.x + rect.size.x * 0.5
		var cz := rect.position.y + rect.size.y * 0.5
		if Vector2(cx - from.x, cz - from.z).length() > 14.0: continue
		var margin := 1.2
		var positions := [
			Vector3(rect.position.x - margin, 0, cz),
			Vector3(rect.end.x + margin, 0, cz),
			Vector3(cx, 0, rect.position.y - margin),
			Vector3(cx, 0, rect.end.y + margin)
		]
		for candidate in positions:
			var cell := Vector2i(roundi(candidate.x), roundi(candidate.z))
			if not astar.is_in_boundsv(cell) or astar.is_point_solid(cell): continue
			var dist_from := Vector2(candidate.x - from.x, candidate.z - from.z).length()
			var dist_threat := Vector2(candidate.x - threat.x, candidate.z - threat.z).length()
			if dist_from > 15.0 or dist_threat < 3.2 or dist_threat > 34.0: continue
			if point_exposed(candidate, threat, true): continue
			var path_to := path_between(from, candidate)
			if path_to.size() == 0: continue
			var crowded := false
			for mate in enemies.get_children():
				if mate.dead or mate.bot_id == bot_id: continue
				if mate.global_position.distance_to(candidate) < 1.8:
					crowded = true
					break
				if mate.cover_goal.is_finite() and mate.cover_goal.distance_to(candidate) < 1.8:
					crowded = true
					break
			if crowded: continue
			var score := 15.0 - dist_from * 0.82 - absf(dist_threat - desired) * 0.42 - float(path_to.size()) * 0.09
			if score > best_score:
				best_score = score
				best = candidate
	return best

func find_peek(cover: Vector3, threat: Vector3, side_preference: float) -> Vector3:
	if not cover.is_finite() or not threat.is_finite(): return Vector3.INF
	var radial := threat - cover
	radial.y = 0
	if radial.length_squared() < 0.1: return Vector3.INF
	radial = radial.normalized()
	var side := Vector3(-radial.z, 0, radial.x)
	for sign_dir in [side_preference, -side_preference]:
		for distance in [1.7, 2.7, 3.8]:
			var at := cover + side * distance * sign_dir + radial * 0.4
			var cell := Vector2i(roundi(at.x), roundi(at.z))
			if not astar.is_in_boundsv(cell) or astar.is_point_solid(cell): continue
			if point_exposed(at, threat) and path_between(cover, at).size() > 0:
				return at
	return Vector3.INF

func _update_squad(delta: float) -> void:
	squad_memory = maxf(0.0, squad_memory - delta)
	squad_order_age -= delta
	squad_damage_pressure = maxf(0.0, squad_damage_pressure - delta * 0.06)
	squad_progress_age += delta
	if squad_memory <= 0.0:
		squad_last_known = Vector3.INF
		squad_focus = Vector3.INF
	elif squad_order_age <= 0.0:
		_refresh_squad_plan()
	if is_instance_valid(enemies) and enemies.get_child_count() > 0:
		squad_commander_alive = not enemies.get_child(0).dead

var player: CharacterBody3D
var sun: DirectionalLight3D
var preview: Camera3D
var playing = false
var paused = false
var in_match = false
var phase = Phase.LOBBY
var phase_time = 0.0
var round_number = 0
var score: Array[int] = [0, 0]
var round_winner = -1
var match_winner = -1
var round_kills = 0
var kills = 0
var elapsed = 0.0
var total_elapsed = 0.0
var cores = 0
var pickups: Array[Node3D] = []
var enemies: Node3D
var map: Node3D
var effects: Node3D
var blocked: Array[Rect2] = []
var astar = AStarGrid2D.new()
var ambient: AudioStreamPlayer
var tracer_count = 0
var shots_from_bots = 0
var round_history: Array[int] = []
func _ready() -> void :
	name = "Arena"
	_environment()
	effects = Node3D.new();effects.name = "Effects";add_child(effects)
	map = Node3D.new();map.set_script(preload("res://scripts/round_map.gd"));add_child(map);map.build(self)
	_navigation()
	enemies = Node3D.new();enemies.name = "Enemies";add_child(enemies)
	player = CharacterBody3D.new();player.set_script(preload("res://scripts/player.gd"));player.world = self;player.position = PLAYER_SPAWN;add_child(player)
	preview = Camera3D.new();preview.position = Vector3(25, 14, 27);preview.far = 160;preview.cull_mask = 1;add_child(preview);preview.look_at(Vector3(0, 1, -2));preview.current = true
	var hud = CanvasLayer.new();hud.set_script(preload("res://scripts/tactical_hud.gd"));hud.world = self;add_child(hud);Game.hud = hud
	_spawn_team()
	apply_quality()
	ambient = AudioStreamPlayer.new()
	var wind = Game.asset("outpost_wind.wav") as AudioStreamWAV
	if wind:
		wind.loop_mode = AudioStreamWAV.LOOP_FORWARD;wind.loop_begin = 0;wind.loop_end = wind.data.size() / 2
		ambient.stream = wind;ambient.volume_db = -22;add_child(ambient);ambient.play()
func _environment() -> void :
	var env = Environment.new();env.background_mode = Environment.BG_SKY
	var sky = Sky.new(); var sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("436f8c");sky_mat.sky_horizon_color = Color("c4d4d5");sky_mat.ground_horizon_color = Color("8b9380");sky_mat.ground_bottom_color = Color("3b473a");sky_mat.sky_curve = 0.3;sky.sky_material = sky_mat;env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color = Color("c3d0c8");env.ambient_light_energy = 0.36;env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.fog_enabled = true;env.fog_light_color = Color("b2c6cb");env.fog_density = 0.002;env.fog_sky_affect = 0.12
	var node = WorldEnvironment.new();node.environment = env;add_child(node)
	sun = DirectionalLight3D.new();sun.rotation_degrees = Vector3(-49, -35, 0);sun.light_color = Color("fff0cf");sun.light_energy = 0.78;sun.shadow_enabled = true;sun.directional_shadow_max_distance = 45;sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS;add_child(sun)
func _collider(at: Vector3, size: Vector3, navigation: bool = true) -> void :
	var body = StaticBody3D.new();body.position = at
	var col = CollisionShape3D.new(); var shape = BoxShape3D.new();shape.size = size;col.shape = shape;body.add_child(col);add_child(body)
	if navigation: blocked.append(Rect2(Vector2(at.x - size.x / 2 - 0.4, at.z - size.z / 2 - 0.4), Vector2(size.x + 0.8, size.z + 0.8)))
func _navigation() -> void :
	astar.region = Rect2i(-22, -26, 45, 53);astar.cell_size = Vector2.ONE;astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES;astar.update()
	for rect in blocked:
		for x in range(floori(rect.position.x), ceili(rect.end.x) + 1):
			for z in range(floori(rect.position.y), ceili(rect.end.y) + 1):
				var cell = Vector2i(x, z)
				if astar.is_in_boundsv(cell): astar.set_point_solid(cell)
func free_cell(at: Vector3) -> Vector2i:
	var cell = Vector2i(roundi(at.x), roundi(at.z))
	if astar.is_in_boundsv(cell) and not astar.is_point_solid(cell): return cell
	for radius in range(1, 5):
		for x in range( - radius, radius + 1):
			for z in range( - radius, radius + 1):
				var next = cell + Vector2i(x, z)
				if astar.is_in_boundsv(next) and not astar.is_point_solid(next): return next
	return Vector2i(-12, 18)
func path_between(from: Vector3, to: Vector3) -> PackedVector3Array:
	var result = PackedVector3Array()
	for cell in astar.get_id_path(free_cell(from), free_cell(to)): result.append(Vector3(cell.x, 0, cell.y))
	return result
func apply_quality() -> void :
	get_viewport().scaling_3d_scale = [0.65, 0.8, 1.0][Game.quality]
	get_viewport().msaa_3d = Viewport.MSAA_2X if Game.quality == 2 else Viewport.MSAA_DISABLED
	sun.shadow_enabled = Game.quality > 0;sun.directional_shadow_max_distance = 36 if Game.quality < 2 else 55;Game.apply_settings()
func _spawn_team() -> void :
	squad_last_known = Vector3.INF;squad_memory = 0.0;squad_focus = Vector3.INF;squad_order_age = 0.0;squad_damage_pressure = 0.0;squad_progress_age = 0.0
	for enemy in enemies.get_children(): enemies.remove_child(enemy);enemy.queue_free()
	for i in range(5):
		var enemy = CharacterBody3D.new();enemy.set_script(preload("res://scripts/enemy.gd"));enemy.world = self;enemy.player = player;enemy.bot_id = i;enemy.position = BOT_SPAWNS[i];enemies.add_child(enemy)
func alive_bots() -> int:
	var count = 0
	for enemy in enemies.get_children():
		if not enemy.dead: count += 1
	return count
func start_run() -> void :
	score = [0, 0];round_history.clear();round_number = 0;kills = 0;total_elapsed = 0;shots_from_bots = 0;match_winner = -1;paused = false;in_match = true;_next_round()
func _next_round() -> void :
	playing = false;round_number += 1;elapsed = 0;round_kills = 0;round_winner = -1
	for effect in effects.get_children(): effect.queue_free()
	player.position = PLAYER_SPAWN;player.rotation = Vector3.ZERO;player.pitch = 0;player.velocity = Vector3.ZERO;player.health = player.MAX_HEALTH;player.ammo = player.MAG_SIZE;player.reserve = 900;player.reload_time = 0
	player.reset_mobile_state();player.medkits = 0;player.weapon_rig.reset_parts();player.camera.current = true
	_spawn_team();phase = Phase.COUNTDOWN;phase_time = 3.0;Game.hud.start_game();Game.hud.notify("500 HP mỗi bên • Thân -10 HP • Đầu -250 HP.", 3)
func begin_live() -> void :
	if phase != Phase.COUNTDOWN or paused: return
	phase = Phase.LIVE;phase_time = 0;playing = true;Game.hud.clear_controls()
	for enemy in enemies.get_children(): enemy.prepare_live()
func _process(delta: float) -> void :
	if playing and not paused: _update_squad(delta)
	if not in_match or paused: return
	if phase == Phase.COUNTDOWN:
		phase_time = maxf(0, phase_time - delta)
		if phase_time <= 0: begin_live()
	elif phase == Phase.ROUND_OVER:
		phase_time = maxf(0, phase_time - delta)
		if phase_time <= 0:
			if score[0] >= TARGET_SCORE or score[1] >= TARGET_SCORE: _finish_match()
			else: _next_round()
	elif phase == Phase.LIVE:
		elapsed += delta;total_elapsed += delta
		if player.global_position.y < -5: player.take_damage(player.MAX_HEALTH)
func end_round(winner: int) -> void :
	if phase != Phase.LIVE or not playing: return
	playing = false;phase = Phase.ROUND_OVER;round_winner = winner;score[winner] += 1;round_history.append(winner);phase_time = 3.0;Game.hud.clear_controls()
	for enemy in enemies.get_children(): enemy.halt()
	if winner == 1:
		preview.position = player.global_position + Vector3(2.4, 2.2, 2.8)
		var target = player.global_position + Vector3.UP
		for enemy in enemies.get_children():
			if not enemy.dead: target = enemy.global_position + Vector3.UP;break
		preview.look_at(target);preview.current = true
func enemy_killed(_at: Vector3, headshot: bool = false, bot_name: String = "ĐỎ") -> void :
	if phase != Phase.LIVE or not playing: return
	kills += 1;round_kills += 1;Game.hud.report_kill(headshot, bot_name)
	squad_progress_age = 0.0
	if alive_bots() == 0: end_round(0)
func player_killed(killer: String = "ĐỘI ĐỎ") -> void :
	if phase != Phase.LIVE or not playing: return
	Game.hud.notify("Bị loại bởi " + killer, 2);end_round(1)
func _finish_match() -> void :
	if phase != Phase.ROUND_OVER: return
	phase = Phase.MATCH_OVER;in_match = false;playing = false;match_winner = 0 if score[0] >= TARGET_SCORE else 1
	Game.finish_run(kills, total_elapsed);Game.matches_played += 1
	if match_winner == 0: Game.match_wins += 1
	Game.apply_settings();Game.hud.show_match_result(match_winner == 0)
func set_paused(value: bool) -> void :
	if not in_match: return
	paused = value;playing = not value and phase == Phase.LIVE;Game.hud.clear_controls()
	for enemy in enemies.get_children():
		if value: enemy.halt()
		else: enemy.resume_animation()
	if value: Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if ambient: ambient.volume_db = -28 if value else -22
func return_to_menu() -> void :
	in_match = false;playing = false;paused = false;phase = Phase.LOBBY;Game.hud.clear_controls();preview.position = Vector3(25, 14, 27);preview.look_at(Vector3(0, 1, -2));preview.current = true;Game.hud.was_playing = false;Game.hud._main_menu()
func heard_player_shot(at: Vector3) -> void :
	var reporter := -1
	for enemy in enemies.get_children():
		if not enemy.dead and enemy.global_position.distance_to(at) < 22.0:
			enemy.hear(at)
			if reporter == -1: reporter = enemy.bot_id
	# Liên lạc 100%: tiếng súng nghe được được chia sẻ, không tạo mục tiêu xuyên tường.
	if reporter >= 0:
		squad_report(at + Vector3(1.5, 0, -1.5), reporter)
func heard_player_footstep(at: Vector3, crouched: bool) -> void :
	for enemy in enemies.get_children():
		if not enemy.dead and enemy.global_position.distance_to(at) < (3.0 if crouched else 9.0): enemy.hear(at)
func impact(at: Vector3, normal: Vector3) -> void :
	var node = MeshInstance3D.new(); var mesh = SphereMesh.new();mesh.radius = 0.035;mesh.height = 0.07;mesh.radial_segments = 8;mesh.rings = 4;node.mesh = mesh;node.material_override = Game.material(Color("ffcf86"), true);node.position = at + normal * 0.025;effects.add_child(node)
	var tween = create_tween();tween.tween_property(node, "scale", Vector3.ONE * 0.05, 0.15);tween.tween_callback(node.queue_free)
func tracer(from: Vector3, to: Vector3, red: bool) -> void :
	var length = from.distance_to(to)
	if length < 0.05: return
	var line = MeshInstance3D.new(); var mesh = CylinderMesh.new();mesh.top_radius = 0.008;mesh.bottom_radius = 0.008;mesh.height = length;mesh.radial_segments = 4;line.mesh = mesh
	var mat = Game.material(Color("ffb575") if red else Color("ffe2a1"), true);mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED;line.material_override = mat;line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;effects.add_child(line);line.global_position = (from + to) * 0.5
	var direction = (to - from).normalized(); var right = direction.cross(Vector3.UP).normalized()
	if right.length() < 0.01: right = Vector3.RIGHT
	line.global_basis = Basis(right, direction, right.cross(direction)).orthonormalized();tracer_count += 1
	var tween = create_tween();tween.tween_interval(0.055);tween.tween_callback(line.queue_free)
