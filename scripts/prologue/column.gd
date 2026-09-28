extends Node3D
## Spaces 4 and 5 of the prologue (106, docs/livelli/prologo.md): the tail
## of the caravan on the march (103) and the verdict.
## The column moves west (toward the Day, left) with three or four vehicles
## in view; Mirco has stayed behind looking at the dark to the east. Ottavia
## goes back for him against the column, drives off a couple of Brinacchi,
## ties him to her rope (a knot is added) and runs back: halfway, her breath
## runs out faster than usual. Past the limit she reaches the column, the
## verdict comes back from voice to voice, a cut to the head (Arold does not
## turn, Enea does), Anselmo is the last voice and takes her measure; the
## empty lantern appears in the menu (88); black, «Ne restano dieci».

enum Step { INTRO, GO_BACK, MEET, FIGHT, TIE, RETURN, VERDICT, DONE }

const COLUMN_SPEED: float = 1.2
const COLUMN_Z: float = -3.0
const COLUMN_START_X: Array[float] = [-7.0, -31.0, -55.0, -79.0]
const COLUMN_RECIPES: Array[String] = ["casa_due_piani", "tenda_e_carico", "orto_e_serbatoio", "casa_torre"]
const HEAD_X: float = -330.0
const MIRCO_START: Vector3 = Vector3(52.0, 0.0, 7.0)
const OTTAVIA_START: Vector3 = Vector3(0.0, 0.0, 2.5)
const MEET_RADIUS: float = 3.0
const FOLLOW_DISTANCE: float = 1.3
## Past this share of the way back, the breath drains faster (106).
const HALFWAY_SHARE: float = 0.5
const TIRED_DRAIN: float = 2.2
const CATCH_DISTANCE: float = 4.0
const LINE_SECONDS: float = 3.2
const CHAIN_SECONDS: float = 2.3
const CROWD_TYPES: Array[String] = ["uomo_giovane", "uomo_adulto", "uomo_anziano", "donna_giovane", "donna_adulta", "donna_anziana", "bambino", "bambina"]
const ROADS: Array[Dictionary] = [{"points": [Vector2(-450.0, 0.0), Vector2(200.0, -1.0)], "half_width": 4.0}]
const BRINACCHIO: PackedScene = preload("res://scenes/creatures/brinacchio.tscn")
const ANSELMO_WALK: String = "res://assets/sprites/comparse/anselmo_walk_west.png"
const ANSELMO_FACING_NORTH: Texture2D = preload("res://assets/sprites/comparse/anselmo_north.png")
const SUN_ELEVATION_DEGREES: float = 14.0
const SUN_AZIMUTH_DEGREES: float = 300.0

## Seconds each verdict line stays; tests shorten it.
@export var line_seconds: float = LINE_SECONDS
@export var chain_seconds: float = CHAIN_SECONDS

signal prologue_finished

var step: Step = Step.INTRO
var column: Array[Node3D] = []
var walkers: Array[NpcSprite] = []
var mirco: NpcSprite
var brinacchi: Array[CombatEnemy] = []
var column_moving: bool = true

@onready var ottavia: OttaviaProto = $Ottavia
@onready var camera_rig: FollowCameraRig = $CameraRig
@onready var cinema_camera: Camera3D = $CinemaCamera
@onready var dialogue: DialogueBox = $DialogueBox
@onready var hints: HintBanner = $HintBanner
@onready var rope: RopeCounter = $RopeCounter
@onready var title: ChapterTitle = $ChapterTitle
@onready var level: Node3D = $Level

var _random: RandomNumberGenerator = RandomNumberGenerator.new()
var _mirco_idle: Dictionary = {}
var _mirco_walk: Dictionary = {}
var _return_start_x: float = 0.0
var _anselmo: NpcSprite
var _head: Node3D
var _anselmo_walking: bool = false
var _head_shot: bool = false


func _ready() -> void:
	GameOptions.load_options()
	InputRemap.load_controls()
	_random.seed = 103
	NpcSprite.sun_azimuth_degrees = SUN_AZIMUTH_DEGREES
	CampScenery.build_ground(level, _random, ROADS)
	CampScenery.build_mountains(level, _random)
	CampScenery.place_ruins(level)
	CampScenery.place_nature(level, _random, func(point: Vector3) -> bool: return absf(point.z - COLUMN_Z) > 7.0)
	_build_column()
	_build_head()
	_build_mirco()
	ZonePalette.retint_models(level)
	var sun: DirectionalLight3D = $Sun
	sun.rotation_degrees = Vector3(-SUN_ELEVATION_DEGREES, SUN_AZIMUTH_DEGREES, 0.0)
	ottavia.set_shaded(true)
	ottavia.set_sun_azimuth(SUN_AZIMUTH_DEGREES)
	ottavia.global_position = OTTAVIA_START
	ottavia.face_toward(Vector3.RIGHT)
	ottavia.set_lantern_open(PrologueState.lantern_open)
	ottavia.defeated.connect(_on_defeated)
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("start_x="):
			ottavia.global_position.x = argument.trim_prefix("start_x=").to_float()
	camera_rig.target = ottavia
	camera_rig.limits = Rect2(Vector2(-460.0, -30.0), Vector2(560.0, 60.0))
	camera_rig.snap_to_target()
	var hud: CombatHud = CombatHud.new()
	add_child(hud)
	hud.bind(ottavia)
	if "verdict=1" in OS.get_cmdline_user_args():
		_verdict.call_deferred()
	else:
		_intro.call_deferred()


## A short look at Mirco, left behind, then back to Ottavia.
func _intro() -> void:
	ottavia.controls_enabled = false
	var start: Transform3D = camera_rig.camera.global_transform
	var toward: Transform3D = start.translated(Vector3(MIRCO_START.x - OTTAVIA_START.x - 4.0, 0.0, 0.0))
	cinema_camera.global_transform = start
	cinema_camera.current = true
	var tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(func(t: float) -> void: cinema_camera.global_transform = start.interpolate_with(toward, t), 0.0, 1.0, 2.2)
	tween.tween_interval(1.4)
	tween.tween_method(func(t: float) -> void: cinema_camera.global_transform = toward.interpolate_with(start, t), 0.0, 1.0, 1.6)
	await tween.finished
	camera_rig.camera.current = true
	ottavia.controls_enabled = true
	step = Step.GO_BACK


func _physics_process(delta: float) -> void:
	if column_moving:
		for node: Node3D in column:
			node.position.x -= COLUMN_SPEED * delta
		for walker: NpcSprite in walkers:
			walker.position.x -= COLUMN_SPEED * delta
		_head.position.x -= COLUMN_SPEED * delta
	var here: Vector3 = ottavia.global_position
	match step:
		Step.GO_BACK:
			if _flat(here, mirco.global_position) < MEET_RADIUS:
				_meet()
		Step.FIGHT:
			if brinacchi.all(func(enemy: CombatEnemy) -> bool: return not enemy.is_alive()):
				step = Step.TIE
				hints.show_hint(&"INPUT_INTERACT", &"interact")
		Step.VERDICT:
			_follow(delta)
			if _anselmo_walking:
				_anselmo.global_position.x -= COLUMN_SPEED * delta
			if _head_shot:
				var head_point: Vector3 = _head.global_position + Vector3(4.0, 1.2, 0.0)
				cinema_camera.global_transform = Transform3D.IDENTITY.translated(head_point + Vector3(-2.0, 7.0, 14.0)).looking_at(head_point, Vector3.UP)
		Step.RETURN:
			_follow(delta)
			var way: float = _return_start_x - _last_vehicle_back()
			var done: float = _return_start_x - here.x
			ottavia.combat.run_drain_multiplier = TIRED_DRAIN if way > 0.0 and done / way > HALFWAY_SHARE else 1.0
			if here.x - _last_vehicle_back() < CATCH_DISTANCE:
				_verdict()


func _meet() -> void:
	step = Step.MEET
	ottavia.controls_enabled = false
	ottavia.face_toward(mirco.global_position - ottavia.global_position)
	await _say(&"SPEAKER_MIRCO", &"PRO_MIRCO_01")
	await _say(&"SPEAKER_OTTAVIA", &"PRO_OTTAVIA_01")
	ottavia.controls_enabled = true
	# A couple of Brinacchi drawn by the two of them in the frost.
	step = Step.FIGHT
	for index: int in 2:
		var creature: CombatEnemy = BRINACCHIO.instantiate()
		creature.position = mirco.global_position + Vector3(4.0 + index * 1.5, 0.0, -2.0 + index * 4.0)
		level.add_child(creature)
		brinacchi.append(creature)


## Tying Mirco to the rope: the animation, and a knot on the rope (125).
func _on_mirco_used() -> void:
	if step != Step.TIE:
		return
	step = Step.RETURN
	hints.hide_hint()
	ottavia.controls_enabled = false
	ottavia.face_toward(mirco.global_position - ottavia.global_position)
	await ottavia.play_scripted("tie_rope")
	ottavia.stop_scripted()
	PrologueState.knots += 1
	rope.add_knot()
	ottavia.controls_enabled = true
	_return_start_x = ottavia.global_position.x


## Mirco, tied to the rope, walks after Ottavia.
func _follow(delta: float) -> void:
	var target: Vector3 = ottavia.global_position
	var offset: Vector3 = mirco.global_position - target
	offset.y = 0.0
	var moving: bool = offset.length() > FOLLOW_DISTANCE
	if moving:
		var speed: float = maxf(ottavia.velocity.length(), 2.0)
		mirco.global_position -= offset.normalized() * minf(speed * delta, offset.length() - FOLLOW_DISTANCE)
	var facing: Facing.Direction = Facing.nearest_direction(Vector2(-offset.x, -offset.z), Facing.Direction.WEST)
	_set_mirco_look(facing, moving)


func _set_mirco_look(facing: Facing.Direction, moving: bool) -> void:
	var textures: Dictionary = _mirco_walk if moving else _mirco_idle
	var texture: Texture2D = textures.get(Facing.suffix(facing))
	if texture != null:
		mirco.set_strip(texture, 9.0 if moving else 5.0)


func _last_vehicle_back() -> float:
	var last: Node3D = column[0]
	var box: AABB = VehicleKit.bounds(last)
	return last.position.x + box.end.x


## Space 5: the verdict, from voice to voice, the head of the column,
## Anselmo. The column never stops: Ottavia, Mirco and Anselmo walk with it.
func _verdict() -> void:
	step = Step.VERDICT
	ottavia.controls_enabled = false
	ottavia.combat.run_drain_multiplier = 1.0
	ottavia.auto_move = Vector3(-COLUMN_SPEED, 0.0, 0.0)
	hints.hide_hint()
	_place_anselmo()
	for line: StringName in [&"PRO_CHAIN_01", &"PRO_CHAIN_02", &"PRO_CHAIN_03", &"PRO_CHAIN_04"]:
		dialogue.show_line(&"", line)
		await get_tree().create_timer(chain_seconds).timeout
	dialogue.hide_box()
	# Cut to the head of the column: Arold walks on without turning, Enea turns.
	_head_shot = true
	cinema_camera.current = true
	await get_tree().create_timer(line_seconds * 1.5).timeout
	_head_shot = false
	camera_rig.snap_to_target()
	camera_rig.camera.current = true
	await _say(&"SPEAKER_ANSELMO", &"PRO_ANSELMO_01")
	await get_tree().create_timer(0.8).timeout
	# For the hand they stop, face to face; the column walks on.
	ottavia.auto_move = Vector3.ZERO
	_anselmo_walking = false
	_anselmo.set_strip(ANSELMO_FACING_NORTH)
	_anselmo.global_position = ottavia.global_position + Vector3(0.0, 0.0, 1.3)
	ottavia.face_toward(Vector3.BACK)
	dialogue.show_line(&"SPEAKER_ANSELMO", &"PRO_ANSELMO_02")
	await ottavia.play_scripted("give_hand")
	await get_tree().create_timer(line_seconds * 0.6).timeout
	dialogue.hide_box()
	await title.show_lantern_silhouette(line_seconds)
	await title.fade_to_black(1.2)
	await title.show_title(&"PRO_TITLE_CH1", line_seconds)
	step = Step.DONE
	prologue_finished.emit()


## Anselmo walks at Ottavia's side, toward the Day, as the last voice.
func _place_anselmo() -> void:
	_anselmo.global_position = Vector3(ottavia.global_position.x - 0.4, 0.0, ottavia.global_position.z + 1.3)
	if ResourceLoader.exists(ANSELMO_WALK):
		_anselmo.set_strip(load(ANSELMO_WALK), 7.0)
	_anselmo.visible = true
	_anselmo_walking = true


func _say(speaker: StringName, line: StringName) -> void:
	dialogue.show_line(speaker, line)
	await get_tree().create_timer(line_seconds).timeout
	if dialogue.current_line() == String(line):
		dialogue.hide_box()


func _on_defeated() -> void:
	ottavia.controls_enabled = false
	await get_tree().create_timer(0.8).timeout
	ottavia.global_position = mirco.global_position + Vector3(-5.0, 0.0, 0.0)
	ottavia.velocity = Vector3.ZERO
	ottavia.restore_health()
	for enemy: CombatEnemy in brinacchi:
		enemy.reset_enemy()
	ottavia.controls_enabled = true


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _build_column() -> void:
	var recipes: Dictionary = {}
	for recipe: Variant in VehicleKit.load_recipes():
		recipes[recipe["name"]] = recipe
	for index: int in COLUMN_START_X.size():
		var vehicle: Node3D = VehicleKit.build(recipes[COLUMN_RECIPES[index]])
		level.add_child(vehicle)
		VehicleWheels.attach(vehicle)
		var box: AABB = VehicleKit.bounds(vehicle)
		vehicle.position = Vector3(COLUMN_START_X[index], 0.0, COLUMN_Z) - Vector3(box.get_center().x, box.position.y, box.get_center().z)
		column.append(vehicle)
	# The people walk beside the vehicles (76: whoever can walk, walks).
	for index: int in 22:
		var kind: String = CROWD_TYPES[_random.randi() % CROWD_TYPES.size()]
		var view: String = "west" if _random.randf() < 0.6 else "south-west"
		var walker: NpcSprite = NpcSprite.new()
		var strip: String = "res://assets/sprites/folla/%s_walk_%s.png" % [kind, view]
		if ResourceLoader.exists(strip):
			walker.sprite_texture = load(strip)
			walker.frame_count = 8
			walker.frames_per_second = 8.0
		else:
			walker.sprite_texture = load("res://assets/sprites/folla/%s_%s.png" % [kind, view])
		var side: float = -1.0 if _random.randf() < 0.5 else 1.0
		walker.position = Vector3(_random.randf_range(-95.0, -4.0), 0.0, COLUMN_Z + side * _random.randf_range(3.6, 6.0))
		level.add_child(walker)
		walkers.append(walker)


## The head of the column, far to the west: the lead vehicle with the Gnomon
## on the sundial, Arold walking ahead, Enea beside him looking back.
func _build_head() -> void:
	_head = Node3D.new()
	_head.position = Vector3(HEAD_X, 0.0, COLUMN_Z)
	level.add_child(_head)
	var lead: Node3D = (load("res://assets/models/vehicles/mezzo_di_testa_prova.glb") as PackedScene).instantiate()
	_head.add_child(lead)
	VehicleWheels.attach(lead)
	var box: AABB = VehicleKit.bounds(lead)
	lead.position = Vector3(8.0, 0.0, 0.0) - Vector3(box.get_center().x, box.position.y, box.get_center().z)
	var gnomone: NpcSprite = NpcSprite.new()
	gnomone.sprite_texture = load("res://assets/sprites/comparse/gnomone_south.png")
	gnomone.position = Vector3(8.0, box.size.y + 0.05, 0.0)
	_head.add_child(gnomone)
	var arold: NpcSprite = NpcSprite.new()
	if ResourceLoader.exists("res://assets/sprites/comparse/arold_walk_west.png"):
		arold.sprite_texture = load("res://assets/sprites/comparse/arold_walk_west.png")
		arold.frame_count = 8
		arold.frames_per_second = 7.0
	else:
		arold.sprite_texture = load("res://assets/sprites/comparse/arold_south.png")
	arold.position = Vector3(0.0, 0.0, 2.2)
	_head.add_child(arold)
	var enea: NpcSprite = NpcSprite.new()
	enea.sprite_texture = load("res://assets/sprites/comparse/enea_east.png")
	enea.position = Vector3(1.4, 0.0, 3.4)
	_head.add_child(enea)
	_anselmo = NpcSprite.new()
	_anselmo.sprite_texture = load("res://assets/sprites/comparse/anselmo_east.png")
	_anselmo.visible = false
	level.add_child(_anselmo)


func _build_mirco() -> void:
	for suffix: String in ["s", "se", "e", "ne", "n", "nw", "w", "sw"]:
		var idle: String = "res://assets/sprites/comparse/mirco_idle_%s.png" % suffix
		var walk: String = "res://assets/sprites/comparse/mirco_walk_%s.png" % suffix
		if ResourceLoader.exists(idle):
			_mirco_idle[suffix] = load(idle)
		if ResourceLoader.exists(walk):
			_mirco_walk[suffix] = load(walk)
	mirco = NpcSprite.new()
	mirco.sprite_texture = _mirco_idle.get("e", load("res://assets/sprites/comparse/mirco_south.png"))
	mirco.frames_per_second = 5.0
	mirco.position = MIRCO_START
	level.add_child(mirco)
	var talk: Interactable = Interactable.new()
	talk.radius = 2.0
	mirco.add_child(talk)
	talk.used.connect(_on_mirco_used)
