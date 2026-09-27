extends Node3D
## Visual prototype (phase 1): diorama to find camera (50), sprite sizes (49)
## and base palette (51) by looking at them.
##
## Command-line user arguments (after "--"):
##   settings=<path.json>  start from these settings instead of the saved ones
##   perf=<seconds>        measure frame times with vsync off, print, quit
##   panel=1               open the tuning panel at start
##   options=1             open the options menu at start
##   lesson=1              start the lesson of the parry (82) at once
##   chapter_end=1         end the current chapter at once (34)
##   lantern_shadows=<0|1> force the lantern shadows off or on (measurements)
##   autowalk=1            walk a fixed path through the 8 directions (video)
##   autocombat=1          fight the training dummy with a fixed sequence (captures)

const USER_SETTINGS_PATH: String = "user://proto_settings.json"
const PERF_WARMUP_SECONDS: float = 2.0
## Path for the demo video: every direction once (19), through the meadow
## and the foreground band (53). Each step holds its actions for some seconds.
## Fixed fight for captures and videos: a combo, a parry held through the
## dummy's swing, a counter-hit, a step. Times in seconds from the start.
const AUTOCOMBAT: Array[Dictionary] = [
	{"at": 0.4, "press": &"attack"}, {"at": 0.62, "press": &"attack"}, {"at": 0.9, "press": &"attack"},
	{"at": 2.72, "press": &"parry"}, {"at": 3.2, "release": &"parry"},
	{"at": 3.25, "press": &"attack"}, {"at": 3.5, "press": &"attack"},
	{"at": 4.6, "press": &"step"},
	{"at": 5.4, "press": &"hook"}, {"at": 5.45, "release": &"hook"},
]
const AUTOWALK: Array[Dictionary] = [
	{"actions": [], "seconds": 1.5},
	{"actions": [&"move_right"], "seconds": 2.0},
	{"actions": [&"move_right", &"move_down"], "seconds": 1.2},
	{"actions": [&"move_down"], "seconds": 1.4},
	{"actions": [&"move_left", &"move_down"], "seconds": 1.0},
	{"actions": [&"move_left"], "seconds": 2.2},
	{"actions": [&"move_left", &"move_up"], "seconds": 1.2},
	{"actions": [&"move_up"], "seconds": 1.6},
	{"actions": [&"move_right", &"move_up"], "seconds": 1.2},
	{"actions": [], "seconds": 10.0},
]
const CAPTURE_DIR: String = "res://docs/screenshots"
const CREATURE_TUNING: CreatureTuning = preload("res://assets/combat/creature_tuning.tres")

@onready var ottavia: OttaviaProto = $Ottavia
@onready var camera_rig: FollowCameraRig = $CameraRig
@onready var sun: DirectionalLight3D = $Sun
@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var zone_palette: ZonePalette = $ZonePalette
@onready var combat_hud: CombatHud = $CombatHud

var settings: ProtoSettings = ProtoSettings.new()
var tuning_panel: TuningPanel

var _perf_seconds: float = 0.0
var _autowalk_step: int = -1
## Sky light color of the scene file, before the zone moves it.
var _base_ambient_color: Color
var _autowalk_elapsed: float = 0.0
var _autocombat_time: float = -1.0
var _autocombat_next: int = 0
var _perf_elapsed: float = 0.0
var _perf_frame_times: PackedFloat32Array = []
var _perf_gpu_times: PackedFloat32Array = []
var _perf_cpu_times: PackedFloat32Array = []


func _ready() -> void:
	GameOptions.load_options()
	InputRemap.load_controls()
	_base_ambient_color = world_environment.environment.ambient_light_color
	var settings_path: String = USER_SETTINGS_PATH
	var open_panel: bool = false
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("settings="):
			settings_path = argument.trim_prefix("settings=")
		elif argument.begins_with("perf="):
			_perf_seconds = argument.trim_prefix("perf=").to_float()
		elif argument == "panel=1":
			open_panel = true
		elif argument == "chapter_end=1":
			end_chapter.call_deferred()
		elif argument == "lesson=1":
			($LessonParry as LessonParry).start.call_deferred()
		elif argument == "options=1":
			($OptionsMenu as OptionsMenu).open.call_deferred()
		elif argument == "autocombat=1":
			_autocombat_time = 0.0
		elif argument == "autowalk=1":
			_autowalk_step = 0
		elif argument.begins_with("lantern_shadows="):
			ottavia.force_lantern_shadows(argument.trim_prefix("lantern_shadows=").to_int())
	var error: Error = settings.load_json(settings_path)
	if error != OK and error != ERR_FILE_NOT_FOUND:
		push_warning("Cannot read settings %s (error %d)" % [settings_path, error])
	ottavia.global_position = settings.player_position
	ZonePalette.retint_models($Props)
	ZonePalette.retint_models($Vegetation)
	camera_rig.target = ottavia
	apply_settings()
	camera_rig.snap_to_target()
	combat_hud.bind(ottavia)
	tuning_panel = TuningPanel.new(settings, ottavia.combat.tuning, CREATURE_TUNING)
	add_child(tuning_panel)
	tuning_panel.set_panel_visible(open_panel)
	tuning_panel.settings_changed.connect(apply_settings)
	tuning_panel.save_requested.connect(_save_capture)
	tuning_panel.combat_save_requested.connect(_save_combat_tuning)
	tuning_panel.creatures_save_requested.connect(func() -> void: _save_resource(CREATURE_TUNING))
	tuning_panel.end_chapter_requested.connect(end_chapter)
	if _perf_seconds > 0.0:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		# Render times do not depend on vsync, which macOS may enforce anyway.
		RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)


func _exit_tree() -> void:
	CombatEffects.clear_cache()
	Engine.time_scale = 1.0


func _physics_process(delta: float) -> void:
	if _autowalk_step >= 0:
		_autowalk(delta)
	if _autocombat_time >= 0.0:
		_autocombat(delta)


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
	zone_palette.night_proximity = settings.zone_night_proximity
	combat_hud.visible = settings.show_combat_hud
	ottavia.combat.set_chapter(roundi(settings.chapter))
	var sewn: Array[StringName] = []
	for patch: String in [settings.patch_slot_1, settings.patch_slot_2, settings.patch_slot_3]:
		if patch != "" and not StringName(patch) in sewn:
			sewn.append(StringName(patch))
	ottavia.combat.patches = sewn
	ottavia.set_lantern_raised(false)
	var tosca: Tosca = get_node_or_null(^"Tosca") as Tosca
	if tosca != null:
		tosca.present = settings.tosca_present
		ottavia.combat.companion = tosca if settings.tosca_present else null
	zone_palette.apply()
	for plant: Node in get_tree().get_nodes_in_group(&"foreground_plants"):
		(plant as ForegroundPlant).pixel_size = 1.0 / settings.world_texels_per_meter
	# The light points along its -Z: at azimuth A the sun sits toward
	# (sin A, 0, cos A); 300 degrees puts it west-south-west, on the Day side (100).
	# The zone value also moves the light (51): colder and lower toward the Night.
	var proximity: float = settings.zone_night_proximity
	sun.rotation_degrees = Vector3(-settings.sun_elevation * ZonePalette.sun_elevation_scale(proximity), settings.sun_azimuth, 0.0)
	sun.light_color = settings.sun_color * ZonePalette.sun_tint(proximity)
	sun.light_energy = settings.sun_energy * ZonePalette.sun_energy_scale(proximity)
	world_environment.environment.ambient_light_color = ZonePalette.ambient_color(_base_ambient_color, proximity)
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


func _autowalk(delta: float) -> void:
	var step: Dictionary = AUTOWALK[_autowalk_step]
	for action: StringName in step["actions"]:
		Input.action_press(action)
	_autowalk_elapsed += delta
	if _autowalk_elapsed < float(step["seconds"]):
		return
	for action: StringName in step["actions"]:
		Input.action_release(action)
	_autowalk_elapsed = 0.0
	_autowalk_step += 1
	if _autowalk_step >= AUTOWALK.size():
		_autowalk_step = -1


## Writes the combat values back to their resource file (phase 3 tuning).
func _save_combat_tuning() -> void:
	_save_resource(ottavia.combat.tuning)


func _save_resource(resource: Resource) -> void:
	var error: Error = ResourceSaver.save(resource, resource.resource_path)
	if error == OK:
		tuning_panel.show_saved(resource.resource_path)
	else:
		push_warning("Cannot save %s (error %d)" % [resource.resource_path, error])


func _autocombat(delta: float) -> void:
	if _autocombat_time == 0.0:
		var dummy: Node3D = get_node_or_null(^"TrainingDummy") as Node3D
		if dummy != null:
			ottavia.face_toward(dummy.global_position - ottavia.global_position)
	_autocombat_time += delta
	while _autocombat_next < AUTOCOMBAT.size() and _autocombat_time >= float(AUTOCOMBAT[_autocombat_next]["at"]):
		var event: Dictionary = AUTOCOMBAT[_autocombat_next]
		if event.has("press"):
			ottavia.combat.press(event["press"])
		else:
			ottavia.combat.release(event["release"])
		_autocombat_next += 1


## Ends the current chapter (34): Ottavia moves to the next one and the
## screen shows what she loses and what she learns.
func end_chapter() -> void:
	if roundi(settings.chapter) >= Progression.LAST_CHAPTER:
		return
	settings.chapter = roundi(settings.chapter) + 1
	apply_settings()
	var screen: ChapterScreen = get_node_or_null(^"ChapterScreen") as ChapterScreen
	if screen != null:
		screen.show_chapter(roundi(settings.chapter))
