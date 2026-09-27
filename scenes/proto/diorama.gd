extends Node3D
## Visual prototype (phase 1): diorama to find camera (50), sprite sizes (49)
## and base palette (51) by looking at them.
##
## Command-line user arguments (after "--"):
##   settings=<path.json>  start from these settings instead of the saved ones
##   perf=<seconds>        measure frame times with vsync off, print, quit
##   panel=1               open the tuning panel at start

const USER_SETTINGS_PATH: String = "user://proto_settings.json"
const PERF_WARMUP_SECONDS: float = 2.0
const CAPTURE_DIR: String = "res://docs/screenshots"

@onready var ottavia: OttaviaProto = $Ottavia
@onready var camera_rig: FollowCameraRig = $CameraRig
@onready var sun: DirectionalLight3D = $Sun
@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var zone_palette: ZonePalette = $ZonePalette

var settings: ProtoSettings = ProtoSettings.new()
var tuning_panel: TuningPanel

var _perf_seconds: float = 0.0
var _perf_elapsed: float = 0.0
var _perf_frame_times: PackedFloat32Array = []
var _perf_gpu_times: PackedFloat32Array = []
var _perf_cpu_times: PackedFloat32Array = []


func _ready() -> void:
	var settings_path: String = USER_SETTINGS_PATH
	var open_panel: bool = false
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("settings="):
			settings_path = argument.trim_prefix("settings=")
		elif argument.begins_with("perf="):
			_perf_seconds = argument.trim_prefix("perf=").to_float()
		elif argument == "panel=1":
			open_panel = true
	var error: Error = settings.load_json(settings_path)
	if error != OK and error != ERR_FILE_NOT_FOUND:
		push_warning("Cannot read settings %s (error %d)" % [settings_path, error])
	ottavia.global_position = settings.player_position
	ZonePalette.retint_models($Props)
	ZonePalette.retint_models($Vegetation)
	camera_rig.target = ottavia
	apply_settings()
	camera_rig.snap_to_target()
	tuning_panel = TuningPanel.new(settings)
	add_child(tuning_panel)
	tuning_panel.set_panel_visible(open_panel)
	tuning_panel.settings_changed.connect(apply_settings)
	tuning_panel.save_requested.connect(_save_capture)
	if _perf_seconds > 0.0:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		# Render times do not depend on vsync, which macOS may enforce anyway.
		RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)


func _process(delta: float) -> void:
	RenderingServer.global_shader_parameter_set(&"player_position", ottavia.global_position + Vector3.UP * 0.8)
	if _perf_seconds > 0.0:
		_measure_performance(delta)


func apply_settings() -> void:
	camera_rig.pitch_degrees = settings.camera_pitch
	camera_rig.distance = settings.camera_distance
	camera_rig.fov_degrees = settings.camera_fov
	camera_rig.orthographic = settings.camera_orthographic
	camera_rig.dof_near_offset = settings.dof_near_offset
	camera_rig.dof_far_offset = settings.dof_far_offset
	camera_rig.dof_amount = settings.dof_amount
	camera_rig.apply()
	ottavia.set_pixel_size(settings.sprite_pixel_size)
	ottavia.set_billboard_fixed_y(settings.sprite_billboard_fixed_y)
	ottavia.set_upright_depth(settings.sprite_upright_depth)
	ottavia.set_shaded(settings.sprite_shaded)
	ottavia.set_sun_azimuth(settings.sun_azimuth)
	RenderingServer.global_shader_parameter_set(&"world_texels_per_meter", settings.world_texels_per_meter)
	zone_palette.strength = settings.palette_strength
	zone_palette.apply()
	for plant: Node in get_tree().get_nodes_in_group(&"foreground_plants"):
		(plant as ForegroundPlant).pixel_size = 1.0 / settings.world_texels_per_meter
	# The light points along its -Z: at azimuth A the sun sits toward
	# (sin A, 0, cos A); 300 degrees puts it west-south-west, on the Day side (100).
	sun.rotation_degrees = Vector3(-settings.sun_elevation, settings.sun_azimuth, 0.0)
	sun.light_color = settings.sun_color
	sun.light_energy = settings.sun_energy
	world_environment.environment.volumetric_fog_density = settings.fog_density


func save_user_settings() -> void:
	settings.player_position = ottavia.global_position
	settings.save_json(USER_SETTINGS_PATH)


## Saves the current settings and a screenshot without the panel, both in
## docs/screenshots/ with the same timestamped name.
func _save_capture() -> void:
	save_user_settings()
	var was_visible: bool = tuning_panel.is_panel_visible()
	tuning_panel.set_panel_visible(false)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	tuning_panel.set_panel_visible(was_visible)
	var directory: String = ProjectSettings.globalize_path(CAPTURE_DIR)
	DirAccess.make_dir_recursive_absolute(directory)
	var base_name: String = "proto-" + Time.get_datetime_string_from_system().replace(":", "").replace("T", "-")
	image.save_png(directory.path_join(base_name + ".png"))
	settings.save_json(directory.path_join(base_name + ".json"))
	tuning_panel.show_saved(base_name)


func _measure_performance(delta: float) -> void:
	_perf_elapsed += delta
	if _perf_elapsed < PERF_WARMUP_SECONDS:
		return
	_perf_frame_times.append(delta * 1000.0)
	var viewport_rid: RID = get_viewport().get_viewport_rid()
	_perf_gpu_times.append(RenderingServer.viewport_get_measured_render_time_gpu(viewport_rid))
	_perf_cpu_times.append(RenderingServer.viewport_get_measured_render_time_cpu(viewport_rid))
	if _perf_elapsed < PERF_WARMUP_SECONDS + _perf_seconds:
		return
	var sorted: PackedFloat32Array = _perf_frame_times.duplicate()
	sorted.sort()
	var total: float = 0.0
	for frame_time: float in sorted:
		total += frame_time
	var average: float = total / sorted.size()
	var p95: float = sorted[int(sorted.size() * 0.95)]
	var size: Vector2i = get_viewport().get_visible_rect().size
	print("PERF frames=%d avg_ms=%.2f avg_fps=%.1f p95_ms=%.2f max_ms=%.2f gpu_ms=%.2f cpu_ms=%.2f viewport=%dx%d" % [
		sorted.size(), average, 1000.0 / average, p95, sorted[sorted.size() - 1],
		_average(_perf_gpu_times), _average(_perf_cpu_times), size.x, size.y])
	get_tree().quit()


func _average(values: PackedFloat32Array) -> float:
	var total: float = 0.0
	for value: float in values:
		total += value
	return total / maxf(1.0, values.size())
