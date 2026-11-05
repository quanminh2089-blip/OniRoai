extends Node

const VERSION = "1.6.0"
var bot_difficulty = 2
var matches_played = 0
var match_wins = 0
var assets: Dictionary = {}
var quality: int = 1
var sensitivity: float = 0.003
var audio_enabled: bool = true
var best: int = 0
var show_fps: bool = false
var aim_toggle: bool = true
var esp_enabled: bool = false
var head_aim_enabled: bool = false
var control_opacity: float = 0.7
var control_scale: float = 1.05
var ads_sensitivity: float = 0.5
var left_fire: bool = true
var floating_joystick: bool = false
var auto_sprint: bool = true
var camera_motion: float = 0.45
# Vi tri cac nut normalized vao safe area, tuong thich nhieu ti le man hinh.
var custom_controls: Dictionary = {}
var session_kills: int = 0
var session_time: float = 0.0
var hud: CanvasLayer
var settings: = ConfigFile.new()
const ASSET_PATHS: = [
	"res://assets/tactical/models/fp/mp5a5.glb", 
	"res://assets/tactical/models/weapons/optics.glb", 
	"res://assets/tactical/models/characters/soldier.glb", 
	"res://assets/tactical/models/props/old_military_crate/old_military_crate.glb", 
	"res://assets/tactical/models/props/concrete_road_barrier/concrete_road_barrier.glb", 
	"res://assets/tactical/models/props/Barrel_01/Barrel_01.glb", 
	"res://assets/tactical/models/props/portable_generator/portable_generator.glb", 
	"res://assets/tactical/models/props/modular_industrial_pipes_01/modular_industrial_pipes_01.glb", 
	"res://assets/sounds/mp5_shot.ogg", 
	"res://assets/sounds/rifle_magout.ogg", 
	"res://assets/sounds/rifle_magin.ogg", 
	"res://assets/sounds/bolt_fwd.ogg", 
	"res://assets/sounds/walking.ogg", 
	"res://assets/sounds/weapon_change.ogg", 
	"res://assets/sounds/enemy_hurt.ogg", 
	"res://assets/sounds/enemy_destroy.ogg", 
	"res://assets/sounds/enemy_attack.ogg", 
	"res://assets/sounds/outpost_wind.wav", 
	"res://assets/citadel/forest/forest_tree.glb", 
	"res://assets/citadel/rocks/rock_moss_set_01.gltf", 
	"res://assets/citadel/fern/fern_02.gltf"
]

func _ready() -> void :
	settings.load("user://settings.cfg")
	bot_difficulty = clampi(int(settings.get_value("rounds", "difficulty", 2)), 0, 2)
	# Một lần chuyển sang cấu hình EXTREME đã chọn; không ghi đè lựa chọn về sau.
	if int(settings.get_value("rounds", "tactical_ai_version", 0)) < 16:
		bot_difficulty = 2
		settings.set_value("rounds", "tactical_ai_version", 16)
	matches_played = int(settings.get_value("rounds", "played", 0))
	match_wins = int(settings.get_value("rounds", "wins", 0))
	quality = int(settings.get_value("game", "quality", 1))
	sensitivity = float(settings.get_value("game", "sensitivity", 0.003))
	audio_enabled = bool(settings.get_value("game", "audio", true))
	best = int(settings.get_value("game", "best", 0))
	show_fps = bool(settings.get_value("game", "show_fps", false))
	aim_toggle = bool(settings.get_value("game", "aim_toggle", true))
	esp_enabled = bool(settings.get_value("assist", "esp_enabled", false))
	head_aim_enabled = bool(settings.get_value("assist", "head_aim_enabled", false))
	control_opacity = float(settings.get_value("game", "control_opacity", 0.7))
	control_scale = clampf(float(settings.get_value("mobile", "scale", 1.05)), 0.85, 1.2)
	ads_sensitivity = clampf(float(settings.get_value("mobile", "ads_sensitivity", 0.5)), 0.2, 0.85)
	left_fire = bool(settings.get_value("mobile", "left_fire", true))
	floating_joystick = bool(settings.get_value("mobile", "floating_joystick", false))
	auto_sprint = bool(settings.get_value("mobile", "auto_sprint", true))
	camera_motion = clampf(float(settings.get_value("mobile", "camera_motion", 0.45)), 0, 1)
	var saved_positions: Variant = settings.get_value("mobile", "control_positions", {})
	if saved_positions is Dictionary:
		custom_controls = saved_positions.duplicate(true)
	if int(settings.get_value("game", "settings_version", 0)) < 2:
		quality = 1
		control_opacity = 0.82
		settings.set_value("game", "settings_version", 2)
	Engine.max_fps = 60
	Input.use_accumulated_input = false
	apply_settings()

func apply_settings() -> void :
	quality = clampi(quality, 0, 2)
	AudioServer.set_bus_mute(0, not audio_enabled)
	settings.set_value("game", "quality", quality)
	settings.set_value("game", "sensitivity", sensitivity)
	settings.set_value("game", "audio", audio_enabled)
	settings.set_value("game", "best", best)
	settings.set_value("game", "show_fps", show_fps)
	settings.set_value("game", "aim_toggle", aim_toggle)
	settings.set_value("assist", "esp_enabled", esp_enabled)
	settings.set_value("assist", "head_aim_enabled", head_aim_enabled)
	settings.set_value("game", "control_opacity", control_opacity)
	settings.set_value("mobile", "scale", control_scale)
	settings.set_value("mobile", "ads_sensitivity", ads_sensitivity)
	settings.set_value("mobile", "left_fire", left_fire)
	settings.set_value("mobile", "floating_joystick", floating_joystick)
	settings.set_value("mobile", "auto_sprint", auto_sprint)
	settings.set_value("mobile", "camera_motion", camera_motion)
	settings.set_value("mobile", "control_positions", custom_controls)
	settings.set_value("rounds", "difficulty", bot_difficulty)
	settings.set_value("rounds", "played", matches_played)
	settings.set_value("rounds", "wins", match_wins)
	settings.save("user://settings.cfg")

func asset(file: String) -> Resource:
	return assets.get(file.get_file(), null)

func model(file: String) -> Node3D:
	var scene: = asset(file) as PackedScene
	if scene == null:
		push_error("Thiếu model: " + file)
		return Node3D.new()
	return scene.instantiate() as Node3D

func finish_run(kills: int, seconds: float) -> void :
	session_kills = kills
	session_time = seconds
	best = maxi(best, kills)
	apply_settings()

func material(color: Color, emissive: bool = false) -> StandardMaterial3D:
	var mat: = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	if emissive:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 1.4
	return mat
