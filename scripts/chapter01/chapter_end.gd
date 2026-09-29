class_name ChapterOneEnd
extends Node3D
## The end of chapter 1 (107, docs/livelli/capitolo-01.md section 5), in
## its placeholder form (phase 4b step 2):
## 1. at the caravan the terraces are locked for the journey, Pia is back
##    with Iole, Ruggero weaves the wick from the bent ears' fibres;
## 2. the Meridian: «The shadow grows long! We're moving on!»;
## 3. about a minute of the caravan on the march (103): Ottavia reaches the
##    back of Anselmo's truck and gives him the wick; in the menu the
##    lantern fills with its first piece (88);
## 4. the end-of-chapter screen: loses the long sprint, learns the timed
##    step (34); from chapter 2 the run lasts less;
## 5. the title «Nine Remain».

signal finished

const RUGGERO_TEXTURE: Texture2D = preload("res://assets/sprites/capitolo01/ruggero/weave_s.png")
const IOLE_TEXTURE: Texture2D = preload("res://assets/sprites/capitolo01/iole/idle_s.png")
const PIA_TEXTURE: Texture2D = preload("res://assets/sprites/capitolo01/pia/pot_s.png")
const ANSELMO_TEXTURE: Texture2D = preload("res://assets/sprites/comparse/anselmo_south.png")
const FIELD_CART: String = "res://assets/models/vehicles/carro_campo_prova.glb"
const CONDOMINIO: String = "res://assets/models/vehicles/camion_condominio_prova.glb"
const TITLE_MUSIC: AudioStream = preload("res://assets/audio/music/m4_titolo.ogg")
## The column walks west at this pace; Ottavia starts at its tail.
const MARCH_SPEED: float = 1.2
const START: Vector3 = Vector3(30.0, 0.05, 6.0)
## The back of Anselmo's truck, at the start of the march (it moves).
const TRUCK_START: Vector3 = Vector3(-46.0, 0.0, 2.0)
const HANDOVER_METERS: float = 2.2

## Seconds each line stays when it has no voice; tests shorten it.
@export var line_seconds: float = 3.4
@export var title_seconds: float = 4.0

@onready var ottavia: OttaviaProto = $Ottavia
@onready var camera_rig: FollowCameraRig = $CameraRig
@onready var dialogue: DialogueBox = $DialogueBox
@onready var hints: HintBanner = $HintBanner
@onready var title: ChapterTitle = $ChapterTitle
@onready var screen: ChapterScreen = $ChapterScreen
@onready var level: Node3D = $Level

var marching: bool = false
var truck: Node3D
var anselmo: NpcSprite
var marker: ObjectiveMarker
var delivered: bool = false
var _column: Array[Node3D] = []


func _ready() -> void:
	GameOptions.load_options()
	InputRemap.load_controls()
	($Sun as DirectionalLight3D).add_to_group(&"sun")
	NpcSprite.sun_azimuth_degrees = ($Sun as DirectionalLight3D).rotation_degrees.y
	GameState.at_caravan = false
	# The Twilight a little toward the Day (section 1, 51).
	var palette: ZonePalette = ZonePalette.new()
	palette.name = "ZonePalette"
	palette.night_proximity = TrucePlain.ZONE_VALUE
	palette.gradient_width = 120.0
	add_child(palette)
	C01Kit.ground(level, Vector3(-60.0, -0.5, 0.0), Vector3(260.0, 1.0, 40.0), 1079)
	# The column's track: the dirt road of the prologue plain (106).
	LevelBlocks.box(level, Vector3(-60.0, 0.01, 0.0), Vector3(260.0, 0.02, 6.0), LevelBlocks.material(CampScenery.TEX_ROAD), false)
	# The column: the field-carts with their terraces locked, the
	# camion-condominio, Anselmo's truck last in the line ahead of Ottavia.
	for index: int in 3:
		_column.append(_vehicle(_load(FIELD_CART), Vector3(16.0 - index * 16.0, 0.0, -8.0)))
	_column.append(_vehicle(_load(CONDOMINIO), Vector3(-30.0, 0.0, -6.0)))
	truck = _vehicle(VehicleKit.build(VehicleKit.load_recipes()[0]), TRUCK_START + Vector3(-5.0, 0.0, 0.0))
	_column.append(truck)
	anselmo = C01Kit.person(truck, TRUCK_START + Vector3(0.6, 0.0, 0.0), ANSELMO_TEXTURE)
	# Ruggero with the wick, Iole with Pia back beside her.
	C01Kit.person(level, START + Vector3(-2.5, 0.0, -2.0), RUGGERO_TEXTURE)
	C01Kit.person(level, START + Vector3(-5.0, 0.0, 1.0), IOLE_TEXTURE)
	C01Kit.person(level, START + Vector3(-4.2, 0.0, 1.5), PIA_TEXTURE)
	ottavia.global_position = START
	ottavia.face_toward(Vector3.LEFT)
	camera_rig.target = ottavia
	camera_rig.snap_to_target()
	marker = ObjectiveMarker.new()
	level.add_child(marker)
	var menu: OptionsMenu = OptionsMenu.new()
	menu.name = "OptionsMenu"
	add_child(menu)
	($CombatHud as CombatHud).bind(ottavia)
	# F1: the values of the chapter, to tune while playing (phase 4b).
	TuningPanel.for_chapter(self, ottavia.combat.tuning, preload("res://assets/combat/creature_tuning.tres"), preload("res://assets/combat/chapter_01_tuning.tres"))
	_play.call_deferred()


func _play() -> void:
	ottavia.controls_enabled = false
	await _line(&"SPEAKER_RUGGERO", &"C01_RUGGERO_WICK")
	SoundBank.play_sound(get_tree(), &"tromba_gnomone", 0.0)
	await _line(&"SPEAKER_GNOMONE", &"C01_MERIDIAN_LEAVE")
	dialogue.hide_box()
	ottavia.controls_enabled = true
	marching = true
	marker.point_to_node(anselmo, Vector3.UP * 2.2)
	hints.show_goal(&"C01_GOAL_ANSELMO")


func _physics_process(delta: float) -> void:
	if not marching:
		return
	for vehicle: Node3D in _column:
		vehicle.global_position.x -= MARCH_SPEED * delta
	if not delivered and anselmo.global_position.distance_to(ottavia.global_position) <= HANDOVER_METERS:
		delivered = true
		_hand_over()


## At the back of Anselmo's truck: the wick, the first piece (88).
func _hand_over() -> void:
	ottavia.controls_enabled = false
	ottavia.auto_move = Vector3.LEFT * MARCH_SPEED
	hints.hide_goal()
	marker.clear()
	await _line(&"SPEAKER_ANSELMO", &"C01_ANSELMO_01")
	await _line(&"SPEAKER_ANSELMO", &"C01_ANSELMO_02")
	dialogue.hide_box()
	LanternProgress.revealed = true
	LanternProgress.pieces = maxi(LanternProgress.pieces, 1)
	GameState.set_flag(&"c01_done")
	await title.fade_to_black(1.2)
	marching = false
	ottavia.auto_move = Vector3.ZERO
	# The end-of-chapter screen (34): what she loses and what she learns.
	GameState.chapter = 2
	ottavia.combat.set_chapter(GameState.chapter)
	screen.show_chapter(GameState.chapter)
	await screen.closed
	GameAudio.play_music(TITLE_MUSIC, 0.5, -3.0)
	title.title_leaving.connect(func(seconds: float) -> void: GameAudio.stop_music(seconds), CONNECT_ONE_SHOT)
	await title.show_title(&"C01_TITLE", title_seconds)
	finished.emit()


func _line(speaker: StringName, line: StringName) -> void:
	var voice: float = dialogue.show_line(speaker, line)
	await get_tree().create_timer(DialogueBox.line_wait(line_seconds, voice)).timeout


func _load(path: String) -> Node3D:
	return (load(path) as PackedScene).instantiate()


func _vehicle(vehicle: Node3D, center: Vector3) -> Node3D:
	var holder: Node3D = Node3D.new()
	level.add_child(holder)
	holder.global_position = center
	holder.add_child(vehicle)
	var box: AABB = VehicleKit.bounds(vehicle)
	vehicle.position = -Vector3(box.get_center().x, box.position.y, box.get_center().z)
	return holder
