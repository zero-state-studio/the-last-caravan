extends Node3D
## Space 3 of the prologue (106, docs/livelli/prologo.md): the camp on a
## plain of the Twilight, the Day to the west (left, dry ground), the Night
## to the east (right, frost). The caravan is a small town of 20-25
## vehicles (16) with their Wings toward the sun and their Tails trailing
## east. Coming out of the back door of the camion-condominio (space 2) the
## glare fades, the camera rises and shows the whole caravan while Ottavia
## tells the world (narration), then comes back to her.
## The tasks of the camp (step 4) are not here yet.

const MAIN_VEHICLES: Dictionary = {
	&"camion_condominio": "res://assets/models/vehicles/camion_condominio_prova.glb",
	&"carro_campo": "res://assets/models/vehicles/carro_campo_prova.glb",
	&"mezzo_di_testa": "res://assets/models/vehicles/mezzo_di_testa_prova.glb",
}
const CROWD_TYPES: Array[String] = [
	"uomo_giovane", "uomo_adulto", "uomo_anziano", "donna_giovane",
	"donna_adulta", "donna_anziana", "bambino", "bambina",
]
const CROWD_VIEWS: Array[String] = ["south", "west", "south-west", "north-west"]
## The camion-condominio stands at the origin, 20 m long, front to the west:
## its back door is at the east end.
const DOOR_EXIT: Vector3 = Vector3(11.2, 0.0, 2.2)
## x, z rectangle of the tasks (sprint, jump, climb, break, fight).
const TASK_AREA: Rect2 = Rect2(16.0, -15.0, 70.0, 37.0)
const NARRATION: Array[StringName] = [
	&"PRO_NARRATION_01", &"PRO_NARRATION_02", &"PRO_NARRATION_03", &"PRO_NARRATION_04",
	&"PRO_NARRATION_05", &"PRO_NARRATION_06", &"PRO_NARRATION_07",
]
## Where the wide shot looks and from how far (the whole camp in frame).
const WIDE_CENTER: Vector3 = Vector3(-10.0, 4.0, -8.0)
const WIDE_DISTANCE: float = 92.0
const WIDE_PITCH_DEGREES: float = 18.0
## The narration opens looking up at the mountains, then tilts down onto
## the caravan over this share of it.
const WIDE_HIGH_PITCH_DEGREES: float = 5.0
const WIDE_TILT_SHARE: float = 0.4
const RISE_SECONDS: float = 6.0
## Height of the first leg of the rise, above the tallest vehicles.
const RISE_HEIGHT: float = 30.0
const RETURN_SECONDS: float = 3.5
const GLARE_SECONDS: float = 1.6
## Same sun as the approved diorama (phase 2): low, from the west-south-west.
const SUN_ELEVATION_DEGREES: float = 14.0
## Music (126): the theme at the door, a light version while the camp packs.
const THEME_MUSIC: AudioStream = preload("res://assets/audio/music/m1_porta_narrazione.ogg")
const CAMP_MUSIC: AudioStream = preload("res://assets/audio/music/m2_accampamento.ogg")
const CAMP_MUSIC_DB: float = -3.0
## The theme at full voice; GameAudio pulls it down under every line.
const THEME_MUSIC_DB: float = -1.0
## Silence between narration lines, where the theme rises again.
const NARRATION_PAUSE: float = 1.5
const GENERATOR_DB: float = -14.0
const CROWD_DB: float = -12.0
const SUN_AZIMUTH_DEGREES: float = 300.0

## Seconds each narration line stays on screen; tests shorten it.
@export var line_seconds: float = 4.4
## Plays the door glare and the narration (also when started with intro=1).
@export var play_intro: bool = false
## False in tests: the last call does everything but load the column.
@export var leave_scene: bool = true

signal intro_finished

var intro_running: bool = false
var tasks: CampTasks
var vehicles: Array[Node3D] = []
var crowd: Array[CrowdMember] = []
var barks: CrowdBarks
var _vehicle_boxes: Array[AABB] = []

@onready var ottavia: OttaviaProto = $Ottavia
@onready var camera_rig: FollowCameraRig = $CameraRig
@onready var cinema_camera: Camera3D = $CinemaCamera
@onready var dialogue: DialogueBox = $DialogueBox
@onready var hints: HintBanner = $HintBanner
@onready var level: Node3D = $Level

var _fade: ColorRect
var _random: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	GameOptions.load_options()
	InputRemap.load_controls()
	_random.seed = 106
	for argument: String in OS.get_cmdline_user_args():
		if argument == "intro=1":
			play_intro = true
		elif argument.begins_with("line_seconds="):
			line_seconds = argument.trim_prefix("line_seconds=").to_float()
		elif argument == "wide=1" or argument == "wide=high":
			_show_wide_still.call_deferred()
	NpcSprite.sun_azimuth_degrees = SUN_AZIMUTH_DEGREES
	_build()
	ZonePalette.retint_models(level)
	# Low sunset from the west, a little from the camera side: long shadows
	# to the east (right), faces lit (100).
	var sun: DirectionalLight3D = $Sun
	sun.rotation_degrees = Vector3(-SUN_ELEVATION_DEGREES, SUN_AZIMUTH_DEGREES, 0.0)
	# Lit like every other person, so proportions and light match.
	ottavia.set_shaded(true)
	ottavia.set_sun_azimuth(SUN_AZIMUTH_DEGREES)
	ottavia.global_position = DOOR_EXIT
	# Dev arguments for captures: start_x=<m>, start_z=<m>.
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("start_x="):
			ottavia.global_position.x = argument.trim_prefix("start_x=").to_float()
		elif argument.begins_with("start_z="):
			ottavia.global_position.z = argument.trim_prefix("start_z=").to_float()
	ottavia.face_toward(Vector3.BACK)
	ottavia.set_lantern_open(PrologueState.lantern_open)
	ottavia.footstep_sound = &"passo_erba"
	# The camp packing up: the Generators beat in the open, the crowd (127).
	GameAudio.play_loop(&"generator", GameAudio.load_sfx(&"generatore_fuori"), GENERATOR_DB, 1.5)
	GameAudio.play_loop(&"crowd", GameAudio.load_sfx(&"brusio_folla"), CROWD_DB, 2.0)
	camera_rig.target = ottavia
	camera_rig.limits = Rect2(Vector2(-90.0, -40.0), Vector2(180.0, 70.0))
	camera_rig.snap_to_target()
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 40
	add_child(layer)
	_fade = ColorRect.new()
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.color = Color(0.0, 0.0, 0.0, 0.0)
	layer.add_child(_fade)
	tasks = CampTasks.new()
	tasks.name = "Tasks"
	level.add_child(tasks)
	tasks.setup(ottavia, dialogue, hints)
	ZonePalette.retint_models(tasks)
	var hud: CombatHud = CombatHud.new()
	add_child(hud)
	hud.bind(ottavia)
	# Pause and options (96), with the farewell lantern once revealed (88).
	var menu: OptionsMenu = OptionsMenu.new()
	menu.name = "OptionsMenu"
	add_child(menu)
	# Dev arguments for captures: pause=1 opens the menu, lantern=<pieces>
	# shows the farewell lantern with that many pieces.
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("lantern="):
			LanternProgress.revealed = true
			LanternProgress.pieces = argument.trim_prefix("lantern=").to_int()
		elif argument == "pause=1":
			menu.open.call_deferred()
	PrologueAutoplay.attach_if_requested(get_tree())
	tasks.finished.connect(_leave_for_column)
	barks = CrowdBarks.new()
	barks.ottavia = ottavia
	barks.dialogue = dialogue
	barks.crowd = crowd
	add_child(barks)
	if play_intro or PrologueState.entered_from_door:
		intro_finished.connect(tasks.begin, CONNECT_ONE_SHOT)
		_intro.call_deferred()
	else:
		GameAudio.play_music(CAMP_MUSIC, 1.0, CAMP_MUSIC_DB)
		if not "tasks=0" in OS.get_cmdline_user_args():
			tasks.begin.call_deferred()


## The glare of the sunset, the rise over the caravan with the narration,
## and the way back to Ottavia (space 2).
func _intro() -> void:
	intro_running = true
	# Ottavia's theme, whole, under the door and the narration (126).
	GameAudio.play_music(THEME_MUSIC, 0.0, THEME_MUSIC_DB)
	ottavia.controls_enabled = false
	var glare: Color = Color(1.0, 0.93, 0.8).lerp(Color(0.55, 0.42, 0.32), 1.0 - GameOptions.flash_strength)
	_fade.color = Color(glare, 1.0)
	var start: Transform3D = camera_rig.camera.global_transform
	cinema_camera.global_transform = start
	cinema_camera.current = true
	var fade: Tween = create_tween()
	fade.tween_property(_fade, "color:a", 0.0, GLARE_SECONDS)
	await fade.finished
	var wide: Transform3D = wide_shot_transform()
	# First straight up above Ottavia, clear of the tall vehicles, then out.
	var above: Transform3D = Transform3D.IDENTITY.translated(ottavia.global_position + Vector3(0.0, RISE_HEIGHT, RISE_HEIGHT * 0.45)).looking_at(ottavia.global_position, Vector3.UP)
	var up: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	up.tween_method(func(t: float) -> void: cinema_camera.global_transform = start.interpolate_with(above, t), 0.0, 1.0, RISE_SECONDS * 0.4)
	await up.finished
	var out: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Out to the same place, but looking up at the mountains behind the dead
	# city; while Ottavia speaks the view comes slowly down onto the caravan.
	var high: Transform3D = wide_shot_transform(WIDE_HIGH_PITCH_DEGREES)
	out.tween_method(func(t: float) -> void: cinema_camera.global_transform = above.interpolate_with(high, t), 0.0, 1.0, RISE_SECONDS * 0.6)
	await out.finished
	var drift_end: Transform3D = wide.translated(Vector3(6.0, 0.0, 0.0))
	var narration_seconds: float = 0.0
	for line: StringName in NARRATION:
		var stream: AudioStream = GameAudio.voice_stream(line)
		narration_seconds += DialogueBox.line_wait(line_seconds, stream.get_length() if stream != null else 0.0, NARRATION_PAUSE)
	var drift: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	drift.tween_method(func(t: float) -> void: cinema_camera.global_transform = high.interpolate_with(wide, t), 0.0, 1.0, narration_seconds * WIDE_TILT_SHARE)
	drift.tween_method(func(t: float) -> void: cinema_camera.global_transform = wide.interpolate_with(drift_end, t), 0.0, 1.0, narration_seconds * (1.0 - WIDE_TILT_SHARE))
	for line: StringName in NARRATION:
		var voice: float = dialogue.show_line(&"SPEAKER_OTTAVIA", line)
		await get_tree().create_timer(DialogueBox.line_wait(line_seconds, voice, NARRATION_PAUSE)).timeout
	dialogue.hide_box()
	if drift.is_running():
		drift.kill()
	var from: Transform3D = cinema_camera.global_transform
	camera_rig.snap_to_target()
	var back: Transform3D = camera_rig.camera.global_transform
	var home: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	home.tween_method(func(t: float) -> void: cinema_camera.global_transform = from.interpolate_with(back, t), 0.0, 1.0, RETURN_SECONDS)
	await home.finished
	camera_rig.camera.current = true
	ottavia.controls_enabled = true
	GameAudio.play_music(CAMP_MUSIC, 3.0, CAMP_MUSIC_DB)
	intro_running = false
	PrologueState.entered_from_door = false
	intro_finished.emit()


## After the last call the caravan sets off: space 4, the tail of the column.
func _leave_for_column() -> void:
	ottavia.controls_enabled = false
	PrologueState.lantern_open = ottavia.lantern_open
	_fade.color = Color(0.0, 0.0, 0.0, 0.0)
	var tween: Tween = create_tween()
	tween.tween_property(_fade, "color:a", 1.0, 1.2)
	await tween.finished
	if leave_scene:
		get_tree().change_scene_to_file(PrologueState.COLUMN_SCENE)


## The wide shot of the caravan; with `look_pitch` the same eye looks at
## that angle below the horizon instead (higher: the mountains).
func wide_shot_transform(look_pitch: float = NAN) -> Transform3D:
	var pitch: float = deg_to_rad(WIDE_PITCH_DEGREES)
	var eye: Vector3 = WIDE_CENTER + Vector3(0.0, sin(pitch), cos(pitch)) * WIDE_DISTANCE
	var target: Vector3 = WIDE_CENTER
	if not is_nan(look_pitch):
		target = eye + Vector3(0.0, -tan(deg_to_rad(look_pitch)), -1.0) * 100.0
	return Transform3D.IDENTITY.translated(eye).looking_at(target, Vector3.UP)


## Dev capture: the wide shot without the intro.
func _show_wide_still() -> void:
	cinema_camera.global_transform = wide_shot_transform(WIDE_HIGH_PITCH_DEGREES if "wide=high" in OS.get_cmdline_user_args() else NAN)
	cinema_camera.current = true


func _build() -> void:
	CampScenery.build_ground(level, _random)
	CampScenery.build_mountains(level, _random)
	_place_vehicles()
	_place_tents()
	CampScenery.place_ruins(level)
	CampScenery.place_nature(level, _random, func(point: Vector3) -> bool: return not _near_vehicle(point) and not in_task_area(point))
	_place_crowd()


## The camp: vehicles parked in loose rows, fronts to the west, the
## camion-condominio in the middle and the lead vehicle at the head.
func _place_vehicles() -> void:
	var slots: Array[Vector3] = [
		Vector3(-34.0, 0.0, -16.0), Vector3(-14.0, 0.0, -18.0), Vector3(8.0, 0.0, -20.0), Vector3(28.0, 0.0, -17.0),
		Vector3(-52.0, 0.0, -6.0), Vector3(-30.0, 0.0, 2.0), Vector3(-84.0, 0.0, 14.0),
		Vector3(-46.0, 0.0, 16.0), Vector3(-24.0, 0.0, 18.0), Vector3(-2.0, 0.0, 17.0), Vector3(20.0, 0.0, 22.0), Vector3(-70.0, 0.0, -30.0),
		Vector3(-40.0, 0.0, -32.0), Vector3(-18.0, 0.0, -34.0), Vector3(4.0, 0.0, -35.0), Vector3(24.0, 0.0, -33.0),
		Vector3(-60.0, 0.0, 6.0), Vector3(-58.0, 0.0, -20.0), Vector3(46.0, 0.0, -10.0), Vector3(-64.0, 0.0, 26.0),
		Vector3(-8.0, 0.0, 31.0), Vector3(14.0, 0.0, 33.0),
	]
	_add_vehicle(_load(MAIN_VEHICLES[&"camion_condominio"]), Vector3.ZERO)
	# The field-wagon of the prologue stands in the task area (CampTasks).
	_add_vehicle(_load(MAIN_VEHICLES[&"mezzo_di_testa"]), Vector3(-80.0, 0.0, -2.0))
	var recipes: Array = VehicleKit.load_recipes()
	for index: int in mini(recipes.size(), slots.size()):
		var jitter: Vector3 = Vector3(_random.randf_range(-2.0, 2.0), 0.0, _random.randf_range(-1.5, 1.5))
		_add_vehicle(VehicleKit.build(recipes[index]), slots[index] + jitter)


func _add_vehicle(vehicle: Node3D, center: Vector3) -> void:
	level.add_child(vehicle)
	var box: AABB = VehicleKit.bounds(vehicle)
	vehicle.position = center - Vector3(box.get_center().x, box.position.y, box.get_center().z)
	vehicle.rotation.y += _random.randf_range(-0.05, 0.05)
	vehicles.append(vehicle)
	# A simple block so Ottavia walks around the vehicle.
	var body: StaticBody3D = StaticBody3D.new()
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(box.size.x * 0.92, box.size.y, box.size.z * 0.8)
	shape.shape = box_shape
	body.add_child(shape)
	body.position = center + Vector3(0.0, box.size.y * 0.5, 0.0)
	level.add_child(body)


## Tents of the Tessibuio and the Frost-cutters, pitched between the rows.
func _place_tents() -> void:
	var spots: Array[Vector3] = [
		Vector3(-20.0, 0.0, -6.0), Vector3(-42.0, 0.0, 8.0), Vector3(16.0, 0.0, 9.0), Vector3(36.0, 0.0, 26.0),
		Vector3(-12.0, 0.0, 9.0), Vector3(52.0, 0.0, 6.0), Vector3(-66.0, 0.0, -8.0),
	]
	for spot: Vector3 in spots:
		var tent: Node3D = _load("res://assets/models/vehicles/moduli/tenda.glb")
		level.add_child(tent)
		var box: AABB = VehicleKit.bounds(tent)
		tent.position = spot - Vector3(box.get_center().x, box.position.y, box.get_center().z)
		tent.rotation.y = _random.randf_range(-0.4, 0.4)


## The people of the caravan getting ready (121): generic types going
## about the camp, some saying a line as Ottavia passes.
func _place_crowd() -> void:
	var trades: Array[StringName] = CrowdTrades.names()
	var trade_random: RandomNumberGenerator = RandomNumberGenerator.new()
	trade_random.seed = 121
	var placed: int = 0
	var tries: int = 0
	while placed < 46 and tries < 600:
		tries += 1
		var point: Vector3 = Vector3(_random.randf_range(-70.0, 50.0), 0.0, _random.randf_range(-30.0, 30.0))
		if _near_vehicle(point) or in_task_area(point):
			continue
		var person: CrowdMember = CrowdMember.new()
		var kind: String = CROWD_TYPES[_random.randi() % CROWD_TYPES.size()]
		var view: String = CROWD_VIEWS[_random.randi() % CROWD_VIEWS.size()]
		person.sprite_texture = load("res://assets/sprites/folla/%s_%s.png" % [kind, view])
		# Going about the camp (121), away from the vehicles and the tasks.
		person.setup(kind, 1000 + placed, func(at: Vector3) -> bool: return _near_vehicle(at) or in_task_area(at))
		# Each in the colours of their trade (121); a separate random
		# stream, so the placement stays the same.
		person.trade = trades[trade_random.randi() % trades.size()]
		person.position = point
		level.add_child(person)
		crowd.append(person)
		placed += 1


## The east end of the camp, kept clear for the tasks of step 4.
static func in_task_area(point: Vector3) -> bool:
	return point.x > TASK_AREA.position.x and point.x < TASK_AREA.end.x and point.z > TASK_AREA.position.y and point.z < TASK_AREA.end.y


func _near_vehicle(point: Vector3) -> bool:
	# The camp vehicles stand still: their footprints are measured once.
	if _vehicle_boxes.size() != vehicles.size():
		_vehicle_boxes.clear()
		for vehicle: Node3D in vehicles:
			var measured: AABB = VehicleKit.bounds(vehicle)
			measured.position += vehicle.position
			_vehicle_boxes.append(measured.grow(1.2))
	for box: AABB in _vehicle_boxes:
		if point.x > box.position.x and point.x < box.end.x and point.z > box.position.z and point.z < box.end.z:
			return true
	return point.distance_to(DOOR_EXIT) < 3.0


func _load(path: String) -> Node3D:
	return (load(path) as PackedScene).instantiate()
