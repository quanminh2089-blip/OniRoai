extends Control

const UI = preload("res://scripts/ui_style.gd")
var status: Label
var detail: Label
var progress: ProgressBar
var retry: Button
var asset_index: int = 0
var loading: bool = false
var current_path: String = ""

func _ready() -> void :
	theme = UI.theme()
	var bg: = ColorRect.new()
	bg.color = Color("091e29")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center: = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var col: = VBoxContainer.new()
	col.custom_minimum_size.x = 530
	col.add_theme_constant_override("separation", 16)
	center.add_child(col)
	col.add_child(UI.label("MINHQUAN  /  TÀN SÁT", 16, UI.MINT))
	col.add_child(UI.label("TIỀN ĐỒN", 64))
	col.add_child(UI.label("Thung Lũng — Trạm 04. Một mình đấu bốn.", 19, UI.GOLD))
	status = UI.label("Đang chuẩn bị vào game…", 20)
	col.add_child(status)
	progress = ProgressBar.new()
	progress.show_percentage = false
	progress.custom_minimum_size.y = 10
	col.add_child(progress)
	detail = UI.label("", 15, Color("9db8be"))
	col.add_child(detail)
	retry = Button.new()
	retry.text = "THỬ LẠI"
	retry.visible = false
	retry.pressed.connect(_begin)
	col.add_child(retry)
	call_deferred("_begin")

func _begin() -> void :
	retry.hide()


	_start_preload()

func _start_preload() -> void :
	loading = true
	asset_index = 0
	status.text = "Đang tải cảnh vật…"
	_next_asset()

func _next_asset() -> void :
	if asset_index >= Game.ASSET_PATHS.size():
		loading = false
		status.text = "Sẵn sàng"
		progress.value = 100
		await get_tree().process_frame
		var arena: = Node3D.new()
		arena.set_script(load("res://scripts/arena.gd"))
		get_tree().root.add_child(arena)
		get_tree().current_scene = arena
		queue_free()
		return
	current_path = Game.ASSET_PATHS[asset_index]
	if ResourceLoader.load_threaded_request(current_path) != OK:
		loading = false
		push_error("Missing asset: " + current_path)
		_fail("Không mở được dữ liệu game trong APK.")

func _process(_delta: float) -> void :
	if not loading or current_path.is_empty():
		return
	var state: = ResourceLoader.load_threaded_get_status(current_path)
	if state == ResourceLoader.THREAD_LOAD_LOADED:
		Game.assets[current_path.get_file()] = ResourceLoader.load_threaded_get(current_path)
		asset_index += 1
		progress.value = 100.0 * asset_index / Game.ASSET_PATHS.size()
		detail.text = "%d%%" % int(progress.value)
		_next_asset()
	elif state == ResourceLoader.THREAD_LOAD_FAILED or state == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		loading = false
		push_error("Failed to load: " + current_path)
		_fail("Không mở được dữ liệu game trong APK.")

func _fail(message: String) -> void :
	loading = false
	status.text = "Chưa thể vào game"
	detail.text = message
	retry.show()
