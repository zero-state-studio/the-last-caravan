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
const WIDE_CENTER: Vector3 = Vector3(-14.0, 9.0, -18.0)
const WIDE_DISTANCE: float = 100.0
const WIDE_PITCH_DEGREES: float = 13.0
const RISE_SECONDS: float = 6.0
## Height of the first leg of the rise, above the tallest vehicles.
const RISE_HEIGHT: float = 30.0
const RETURN_SECONDS: float = 3.5
const GLARE_SECONDS: float = 1.6
## Same sun as the approved diorama (phase 2): low, from the west-south-west.
const SUN_ELEVATION_DEGREES: float = 14.0
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
		elif argument == "wide=1":
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
	tasks.finished.connect(_leave_for_column)
	if play_intro or PrologueState.entered_from_door:
		intro_finished.connect(tasks.begin, CONNECT_ONE_SHOT)
		_intro.call_deferred()
	elif not "tasks=0" in OS.get_cmdline_user_args():
		tasks.begin.call_deferred()


## The glare of the sunset, the rise over the caravan with the narration,
## and the way back to Ottavia (space 2).
func _intro() -> void:
	intro_running = true
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
	out.tween_method(func(t: float) -> void: cinema_camera.global_transform = above.interpolate_with(wide, t), 0.0, 1.0, RISE_SECONDS * 0.6)
	await out.finished
	# A slow drift toward the Night while Ottavia speaks.
	var drift_end: Transform3D = wide.translated(Vector3(6.0, 0.0, 0.0))
	var drift: Tween = create_tween()
	drift.tween_method(func(t: float) -> void: cinema_camera.global_transform = wide.interpolate_with(drift_end, t), 0.0, 1.0, line_seconds * NARRATION.size())
	for line: StringName in NARRATION:
		dialogue.show_line(&"SPEAKER_OTTAVIA", line)
		await get_tree().create_timer(line_seconds).timeout
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


func wide_shot_transform() -> Transform3D:
	var pitch: float = deg_to_rad(WIDE_PITCH_DEGREES)
	var eye: Vector3 = WIDE_CENTER + Vector3(0.0, sin(pitch), cos(pitch)) * WIDE_DISTANCE
	return Transform3D.IDENTITY.translated(eye).looking_at(WIDE_CENTER, Vector3.UP)


## Dev capture: the wide shot without the intro.
func _show_wide_still() -> void:
	cinema_camera.global_transform = wide_shot_transform()
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


## The people of the caravan getting ready (121): generic types, standing.
func _place_crowd() -> void:
	var placed: int = 0
	var tries: int = 0
	while placed < 46 and tries < 600:
		tries += 1
		var point: Vector3 = Vector3(_random.randf_range(-70.0, 50.0), 0.0, _random.randf_range(-30.0, 30.0))
		if _near_vehicle(point) or in_task_area(point):
			continue
		var person: NpcSprite = NpcSprite.new()
		var kind: String = CROWD_TYPES[_random.randi() % CROWD_TYPES.size()]
		var view: String = CROWD_VIEWS[_random.randi() % CROWD_VIEWS.size()]
		person.sprite_texture = load("res://assets/sprites/folla/%s_%s.png" % [kind, view])
		person.position = point
		level.add_child(person)
		placed += 1


## The east end of the camp, kept clear for the tasks of step 4.
static func in_task_area(point: Vector3) -> bool:
	return point.x > TASK_AREA.position.x and point.x < TASK_AREA.end.x and point.z > TASK_AREA.position.y and point.z < TASK_AREA.end.y


func _near_vehicle(point: Vector3) -> bool:
	for vehicle: Node3D in vehicles:
		var box: AABB = VehicleKit.bounds(vehicle)
		box.position += vehicle.position
		box = box.grow(1.2)
		if point.x > box.position.x and point.x < box.end.x and point.z > box.position.z and point.z < box.end.z:
			return true
	return point.distance_to(DOOR_EXIT) < 3.0


func _load(path: String) -> Node3D:
	return (load(path) as PackedScene).instantiate()
