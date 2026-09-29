class_name FieldCarts
extends Node3D
## The dungeon of chapter 1 (107, 83, docs/livelli/capitolo-01.md section
## 4) in its placeholder form (phase 4b step 2): plain shapes at the sizes
## of the document, creatures with their values, the boss.
##
## The rooms are closed dioramas (102), each at its own place in the world,
## joined by passages with a fade; a ramp or a bridge leads to the next
## room only while its terrace is turned the right way (decided 29
## September 2026). The first cart holds rooms 1 and 2 together, as they
## touch for real. Layout and sequence in docs/livelli/capitolo-01-forma.md.
##
## Command-line user arguments (after "--"):
##   room=<id>        start in a room (s1 ... s7) instead of the entry
##   difficulty=<0-2> easy, medium, hard for this run
##   boss_hits=<n>    a weaker boss (captures, tests)

signal chapter_won

const CHAPTER_TUNING: ChapterTuning = preload("res://assets/combat/chapter_01_tuning.tres")
const VOLTAFACCIA_SCENE: PackedScene = preload("res://scenes/creatures/voltafaccia.tscn")
const RASPAGELO_SCENE: PackedScene = preload("res://scenes/creatures/raspagelo.tscn")
const IOLE_TEXTURE: Texture2D = preload("res://assets/sprites/capitolo01/iole/idle_s.png")
const RUGGERO_TEXTURE: Texture2D = preload("res://assets/sprites/comparse/ruggero_south.png")
const PIA_TEXTURE: Texture2D = preload("res://assets/sprites/folla/bambina_south.png")
const END_SCENE: String = "res://scenes/capitolo01/fine.tscn"

## Where each diorama sits in the world: far apart, never seen together.
const A: Vector3 = Vector3(0.0, 0.0, 0.0)
const B: Vector3 = Vector3(100.0, 0.0, 0.0)
const C: Vector3 = Vector3(200.0, 0.0, 0.0)
const D: Vector3 = Vector3(300.0, 0.0, 0.0)
const E: Vector3 = Vector3(400.0, 0.0, 0.0)
const F: Vector3 = Vector3(500.0, 0.0, 0.0)
const LOW: float = 2.0
const HIGH: float = 4.5
const TOP: float = 5.0
const SLAB: float = 0.4

## Light of each room (section 1): warmest on the first cart, colder to
## the east; room 6 the coldest; the top back in full sun.
## "zone" is the colour drift of the world palette (51): the Twilight a
## little toward the Day, growing toward the Night from west to east.
const ROOM_LIGHT: Dictionary = {
	&"s1": {"color": Color(1.0, 0.76, 0.5), "energy": 1.7, "zone": -0.25},
	&"s2": {"color": Color(1.0, 0.76, 0.5), "energy": 1.7, "zone": -0.25},
	&"s3": {"color": Color(1.0, 0.74, 0.52), "energy": 1.5, "zone": -0.15},
	&"s4": {"color": Color(1.0, 0.8, 0.58), "energy": 1.8, "zone": -0.1},
	&"s5": {"color": Color(0.9, 0.72, 0.62), "energy": 1.2, "zone": 0.0},
	&"s6": {"color": Color(0.62, 0.62, 0.9), "energy": 0.8, "zone": 0.35},
	&"s7": {"color": Color(1.0, 0.82, 0.6), "energy": 1.9, "zone": -0.3},
}
## Metres along world x, inside a room, for a full step of drift: each
## diorama shades gently from west to east, never jumps.
const ROOM_GRADIENT: float = 90.0
const RUGGERO_LINES: Array[Array] = [
	[&"SPEAKER_RUGGERO", &"C01_RUGGERO_01"],
	[&"SPEAKER_OTTAVIA", &"C01_OTTAVIA_03"],
	[&"SPEAKER_RUGGERO", &"C01_RUGGERO_02"],
]
const PIA_LINES: Array[Array] = [
	[&"SPEAKER_PIA", &"C01_PIA_01"],
	[&"SPEAKER_OTTAVIA", &"C01_OTTAVIA_04"],
	[&"SPEAKER_PIA", &"C01_PIA_02"],
]

## Seconds each line stays when it has no voice; tests shorten it.
@export var line_seconds: float = 3.2
## False in tests: the victory does everything but load the ending.
@export var leave_scene: bool = true

@onready var ottavia: OttaviaProto = $Ottavia
@onready var camera_rig: FollowCameraRig = $CameraRig
@onready var manager: RoomManager = $RoomManager
@onready var dialogue: DialogueBox = $DialogueBox
@onready var hints: HintBanner = $HintBanner
@onready var sun: DirectionalLight3D = $Sun
@onready var level: Node3D = $Level

var rooms: Dictionary = {}
var terrace_1: TurningPlatform
var terrace_2: TurningPlatform
var terrace_3: TurningPlatform
var terrace_4: TurningPlatform
var arena: TurningPlatform
var lever_s1: TurnLever
var lever_s6: TurnLever
var ice_crust: Breakable
var stems: Array[Breakable] = []
var palette: ZonePalette
var pia_cage: Node3D
var ruggero: RescuedPerson
var pia: RescuedPerson
var boss: RootedFoglione
var arena_levers: Array[TurnLever] = []
var arena_node: SummitArena
var bonus_hedge: Array[Breakable] = []
var ladder_to_top: ClimbSpot
var won: bool = false
var _bridge_high_look: Node3D
var _bridge_low_look: Node3D
var _hinted_rooms: Dictionary = {}


func _ready() -> void:
	GameOptions.load_options()
	InputRemap.load_controls()
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("difficulty="):
			GameOptions.difficulty = clampi(argument.trim_prefix("difficulty=").to_int(), 0, 2)
	sun.add_to_group(&"sun")
	NpcSprite.sun_azimuth_degrees = sun.rotation_degrees.y
	GameState.at_caravan = false
	palette = ZonePalette.new()
	palette.name = "ZonePalette"
	palette.gradient_width = ROOM_GRADIENT
	add_child(palette)
	_build_cart_1()
	_build_grass()
	_build_high_terrace()
	_build_low_terrace_2()
	_build_frozen_terrace()
	_build_top()
	camera_rig.target = ottavia
	manager.room_changed.connect(_on_room_changed)
	var menu: OptionsMenu = OptionsMenu.new()
	menu.name = "OptionsMenu"
	add_child(menu)
	var hud: CombatHud = $CombatHud
	hud.bind(ottavia)
	# F1: the values of the chapter, to tune while playing (phase 4b).
	TuningPanel.for_chapter(self, ottavia.combat.tuning, preload("res://assets/combat/creature_tuning.tres"), preload("res://assets/combat/chapter_01_tuning.tres"))
	var start_room: StringName = &"s1"
	var start_entry: StringName = &"ingresso"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("room="):
			start_room = StringName(argument.trim_prefix("room="))
			start_entry = (rooms[start_room] as Room).default_entry if rooms.has(start_room) else start_entry
		elif argument.begins_with("boss_hits="):
			boss.max_health = CreatureTuning.health_for_hits(argument.trim_prefix("boss_hits=").to_float())
			boss.health = boss.max_health
	var checkpoint: Dictionary = SaveGame.take_pending(scene_file_path)
	if not checkpoint.is_empty():
		start_room = StringName(str(checkpoint.get("room", "s1")))
		start_entry = StringName(str(checkpoint.get("entry", "ingresso")))
	_start.call_deferred(start_room, start_entry)


func _start(room_id: StringName, entry_id: StringName) -> void:
	manager.restore_checkpoint({"room": String(room_id), "entry": String(entry_id)})
	camera_rig.snap_to_target()
	# The entry of the dungeon is a checkpoint (95); not with dev arguments
	# (captures, tests), so they never write over the player's save.
	if room_id == &"s1" and entry_id == &"ingresso" and OS.get_cmdline_user_args().is_empty() and get_tree().get_script() == null:
		SaveGame.autosave(get_tree(), room_id, entry_id, &"dungeon")


# --- Room 1 and room 2: the first cart ---------------------------------------

func _build_cart_1() -> void:
	var cart: Node3D = _group(&"Cart1")
	# Ground of the diorama: the foot of the cart (room 1) and a strip east.
	C01Kit.ground(cart, A + Vector3(-7.0, -0.5, 0.0), Vector3(46.0, 1.0, 22.0), 1071)
	# The chassis, under the turning terrace, and the big wheels.
	C01Kit.box(cart, A + Vector3(0.0, 0.8, 0.0), Vector3(24.0, 1.6, 10.0), C01Kit.WOOD_DARK)
	for x: float in [-9.0, 9.0]:
		for z: float in [-5.4, 5.4]:
			C01Kit.wheel(cart, A + Vector3(x, 1.4, z), 1.4)
	# Room 1 (14 x 10): gear housings, a broken ladder, patched sacks, a tank.
	var r1: Room = _room(&"s1", A + Vector3(-19.0, 2.0, 0.0), Vector3(14.0, 4.0, 10.0), &"ingresso")
	C01Kit.entry(r1, &"ingresso", A + Vector3(-24.5, 0.05, 1.0))
	C01Kit.entry(r1, &"da_scorciatoia", A + Vector3(-22.0, 0.05, -3.0))
	_bounds(cart, Rect2(A.x - 26.0, A.z - 5.0, 14.0, 10.0), [Rect2(A.x - 12.5, A.z - 5.0, 1.0, 10.0)])
	C01Kit.box(cart, A + Vector3(-13.0, 0.6, -4.0), Vector3(1.6, 1.2, 1.2), C01Kit.IRON)
	C01Kit.box(cart, A + Vector3(-13.0, 0.6, 3.8), Vector3(1.6, 1.2, 1.4), C01Kit.IRON)
	C01Kit.box(cart, A + Vector3(-18.0, 0.4, -4.3), Vector3(1.2, 0.8, 0.8), C01Kit.CLOTH)
	C01Kit.box(cart, A + Vector3(-19.4, 0.35, -4.4), Vector3(1.0, 0.7, 0.7), C01Kit.CLOTH.darkened(0.1))
	C01Kit.box(cart, A + Vector3(-25.0, 0.9, -3.6), Vector3(1.6, 1.8, 1.6), C01Kit.IRON.lightened(0.2))
	C01Kit.visual(cart, A + Vector3(-12.6, 1.2, 1.0), Vector3(0.2, 2.4, 0.6), C01Kit.WOOD, Vector3(0.0, 0.0, deg_to_rad(15.0)))
	C01Kit.person(cart, A + Vector3(-21.0, 0.0, 2.6), IOLE_TEXTURE)
	# Room 2: the low terrace (20 x 9) on its turntable. Its ramp is on the
	# local east end, south half; the other end has a fence. At the start
	# the ramp points south (quarter 1): one pull brings it down into room 1
	# (quarter 2), two more toward room 3 (quarter 0).
	terrace_1 = _terrace(&"Terrace1", A + Vector3(0.0, LOW - SLAB, 0.0), Vector2(20.0, 9.0), 1)
	C01Kit.slope_on(terrace_1, Vector3(10.0, SLAB, 2.25), Vector3(16.0, SLAB - LOW, 2.25), 4.4, C01Kit.WOOD)
	C01Kit.rails_around(terrace_1, Vector3(0.0, SLAB, 0.0), Vector2(20.0, 9.0), [["e", -4.5, 4.5]])
	C01Kit.ears(terrace_1, Rect2(-8.5, -3.8, 12.0, 7.6), SLAB)
	for x: float in range(-6, 6, 2):
		C01Kit.visual(terrace_1, Vector3(float(x), SLAB + 0.35, -4.0), Vector3(0.12, 0.7, 0.12), C01Kit.WOOD_DARK)
	var r2: Room = _room(&"s2", A + Vector3(0.0, LOW + 1.3, 0.0), Vector3(22.0, 3.6, 22.0), &"da_rampa")
	_terrace_entry(terrace_1, &"s2", &"da_rampa", Vector3(7.5, SLAB + 0.05, 2.25))
	_terrace_entry(terrace_1, &"s2", &"da_erba", Vector3(7.5, SLAB + 0.05, 2.25))
	_terrace_entry(terrace_1, &"s2", &"da_ponte", Vector3(8.4, SLAB + 0.05, -2.2))
	r2.default_entry = &"da_rampa"
	# The ramp's foot in the strip east of the cart: toward room 3.
	C01Kit.exit(level, A + Vector3(15.0, 0.6, 2.25), Vector3(2.0, 1.2, 4.4), &"s3", &"da_rampa", func() -> bool: return terrace_1.quarter == 0 and not terrace_1.turning)
	# The high plank bridge toward room 4, from the east end of the terrace
	# when it is turned toward it: down at easy from the start, lowered from
	# above once Ruggero is saved.
	C01Kit.exit(level, A + Vector3(10.4, LOW + 0.6, -2.2), Vector3(1.0, 1.2, 4.2), &"s4", &"da_ponte", func() -> bool: return terrace_1.quarter == 0 and not terrace_1.turning and bridge_high_down())
	_bridge_high_look = Node3D.new()
	level.add_child(_bridge_high_look)
	C01Kit.visual(_bridge_high_look, A + Vector3(14.0, LOW + 1.25, -2.2), Vector3(8.2, 0.15, 2.0), C01Kit.WOOD.lightened(0.2), Vector3(0.0, 0.0, atan2(2.5, 8.0)))
	# Room 1: the first lever, on the ground, with «Use the lever».
	lever_s1 = _lever(level, A + Vector3(-14.5, 0.0, 3.0), terrace_1)
	lever_s1.hint_when_near = true
	# Room 2: its own lever, on the terrace (it turns with it).
	var lever_s2: TurnLever = _lever(terrace_1, Vector3.ZERO, terrace_1)
	lever_s2.position = Vector3(-3.0, SLAB, 3.0)
	# Creatures: 5 Voltafaccia grazing toward the sun, 3 Cocci in the rows.
	for spot: Vector3 in [Vector3(-6.0, 0.0, -1.5), Vector3(-4.5, 0.0, 1.8), Vector3(-2.0, 0.0, -0.6), Vector3(0.5, 0.0, 1.6), Vector3(2.5, 0.0, -1.4)]:
		_creature(VOLTAFACCIA_SCENE.instantiate() as CombatEnemy, terrace_1.to_global(spot + Vector3.UP * (SLAB + 0.05)))
	for spot: Vector3 in [Vector3(4.5, 0.0, -2.8), Vector3(6.0, 0.0, 0.5), Vector3(-7.5, 0.0, 3.0)]:
		_creature(Coccio.new(), terrace_1.to_global(spot + Vector3.UP * (SLAB + 0.05)))


# --- Room 3: the tall grass between the carts -----------------------------------

func _build_grass() -> void:
	var grass: Node3D = _group(&"Grass")
	C01Kit.ground(grass, B + Vector3(0.0, -0.5, 0.0), Vector3(30.0, 1.0, 24.0), 1073)
	# The ends of the first and second carts, as scenery on both sides.
	C01Kit.box(grass, B + Vector3(-12.0, 1.6, 0.0), Vector3(8.0, 3.2, 12.0), C01Kit.WOOD_DARK)
	C01Kit.box(grass, B + Vector3(12.0, 2.25, 0.0), Vector3(8.0, 4.5, 12.0), C01Kit.WOOD_DARK)
	# The raised plank bridge passes overhead.
	C01Kit.visual(grass, B + Vector3(0.0, 6.0, -2.2), Vector3(16.0, 0.15, 2.0), C01Kit.WOOD.lightened(0.2), Vector3(0.0, 0.0, deg_to_rad(8.0)))
	var r3: Room = _room(&"s3", B + Vector3(0.0, 2.0, 0.0), Vector3(16.0, 4.0, 12.0), &"da_rampa")
	C01Kit.entry(r3, &"da_rampa", B + Vector3(-6.0, 0.05, 2.25))
	_bounds(grass, Rect2(B.x - 8.0, B.z - 6.0, 16.0, 12.0), [])
	C01Kit.tall_grass(grass, Rect2(B.x - 7.8, B.z - 5.8, 15.6, 11.6), [Rect2(B.x - 7.8, B.z + 1.0, 3.0, 3.0), Rect2(B.x - 1.5, B.z - 2.0, 4.0, 4.0), Rect2(B.x + 5.0, B.z - 5.8, 2.8, 3.5)])
	# Back to room 2, up the ramp, while it points here.
	C01Kit.exit(level, B + Vector3(-7.5, 0.6, 2.25), Vector3(0.8, 1.2, 3.0), &"s2", &"da_erba", func() -> bool: return terrace_1.quarter == 0 and not terrace_1.turning)
	# A ladder up the end of the second cart to room 4.
	C01Kit.box(grass, B + Vector3(7.8, 2.25, -4.5), Vector3(0.4, 4.5, 2.0), C01Kit.WOOD)
	for y: float in [0.6, 1.4, 2.2, 3.0, 3.8]:
		C01Kit.visual(grass, B + Vector3(7.5, y, -4.5), Vector3(0.1, 0.1, 1.6), C01Kit.WOOD_DARK)
	C01Kit.box(grass, B + Vector3(8.0, HIGH - 0.1, -4.5), Vector3(1.6, 0.2, 2.0), C01Kit.WOOD)
	ClimbSpot.create(grass, B + Vector3(7.3, 1.0, -4.5), Vector3(0.6, 2.0, 1.8), B + Vector3(8.0, HIGH + 0.05, -4.5), Vector3.LEFT)
	C01Kit.exit(level, B + Vector3(8.2, HIGH + 0.6, -4.5), Vector3(1.2, 1.2, 1.8), &"s4", &"da_scala")
	# Creatures: a Frinitore swarm and four Raspageli waiting in the grass.
	_creature(Frinitore.new(), B + Vector3(-1.0, 0.05, 1.0))
	for spot: Vector3 in [Vector3(-3.5, 0.05, -3.0), Vector3(2.0, 0.05, 3.5), Vector3(4.0, 0.05, -1.5), Vector3(5.5, 0.05, 2.5)]:
		var rodent: Raspagelo = RASPAGELO_SCENE.instantiate() as Raspagelo
		rodent.hidden_start = true
		_creature(rodent, B + spot)


# --- Room 4: the high terrace of the second cart --------------------------------

func _build_high_terrace() -> void:
	var cart: Node3D = _group(&"Cart2High")
	C01Kit.ground(cart, C + Vector3(0.0, -0.5, 0.0), Vector3(40.0, 1.0, 30.0), 1074)
	# The second cart below: chassis and the low terrace, as scenery.
	C01Kit.box(cart, C + Vector3(0.0, 0.8, 0.0), Vector3(24.0, 1.6, 10.0), C01Kit.WOOD_DARK)
	C01Kit.visual(cart, C + Vector3(0.0, LOW - SLAB * 0.5, 0.0), Vector3(20.0, SLAB, 9.0), C01Kit.SOIL)
	C01Kit.box(cart, C + Vector3(0.0, (LOW + HIGH) * 0.5, 0.0), Vector3(1.6, HIGH - LOW, 1.6), C01Kit.WOOD_DARK)
	# The landing at the west end, where the ladder and the bridge arrive.
	C01Kit.box(cart, C + Vector3(-10.5, HIGH - 0.25, 1.5), Vector3(3.0, 0.5, 6.0), C01Kit.WOOD)
	var r4: Room = _room(&"s4", C + Vector3(-1.0, HIGH + 1.1, 0.0), Vector3(26.0, 3.4, 22.0), &"da_scala")
	C01Kit.entry(r4, &"da_scala", C + Vector3(-11.0, HIGH + 0.05, 3.0))
	C01Kit.entry(r4, &"da_ponte", C + Vector3(-11.0, HIGH + 0.05, 0.0))
	# The terrace (18 x 9), aligned at the start; its ramp on the local
	# north side: after two turns it points south and comes down onto the
	# low terrace (room 5).
	terrace_2 = _terrace(&"Terrace2", C + Vector3(0.0, HIGH - SLAB, 0.0), Vector2(18.0, 9.0), 0)
	C01Kit.slope_on(terrace_2, Vector3(2.0, SLAB, -4.5), Vector3(2.0, SLAB - (HIGH - LOW), -9.5), 3.0, C01Kit.WOOD)
	C01Kit.rails_around(terrace_2, Vector3(0.0, SLAB, 0.0), Vector2(18.0, 9.0), [["w", -4.5, 4.5], ["n", 0.5, 3.5]])
	# Warm flat stones where the Specchietti bask, and a row of fan cabbages
	# on the south edge: after one turn the cabbages stand west of the
	# stones and shade them (the sun is low in the west).
	for spot: Vector3 in [Vector3(2.0, 0.0, 0.5), Vector3(3.5, 0.0, 1.8), Vector3(5.0, 0.0, 0.2), Vector3(6.2, 0.0, 1.6)]:
		C01Kit.visual(terrace_2, spot + Vector3.UP * (SLAB + 0.08), Vector3(1.2, 0.16, 1.0), C01Kit.STONE)
		_creature(Specchietto.new(), terrace_2.to_global(spot + Vector3.UP * (SLAB + 0.2)))
	for x: float in [1.0, 2.4, 3.8, 5.2, 6.6]:
		C01Kit.cabbage_on(terrace_2, Vector3(x, SLAB, 3.7))
	C01Kit.shape_on(terrace_2, Vector3(-3.0, SLAB + 0.6, 3.8), Vector3(3.0, 1.2, 0.15), C01Kit.WOOD_DARK)
	# Ruggero, on the east edge, bent over the plants.
	var shortcut: RescueShortcut = RescueShortcut.new()
	shortcut.name = "RuggeroShortcut"
	shortcut.shortcut_id = &"c01_shortcut_ruggero"
	shortcut.reveal = "unroll"
	level.add_child(shortcut)
	shortcut.global_position = C + Vector3(-10.2, HIGH, 4.6)
	C01Kit.visual(shortcut, Vector3(0.0, -HIGH * 0.5, 0.0), Vector3(0.6, HIGH, 0.08), C01Kit.CLOTH.lightened(0.2))
	for point: Vector3 in [C + Vector3(-9.5, HIGH, 3.0), C + Vector3(-10.2, HIGH, 4.3), C + Vector3(-10.2, 0.05, 4.9), C + Vector3(-16.0, 0.05, 8.0)]:
		var marker: Marker3D = Marker3D.new()
		shortcut.add_child(marker)
		marker.global_position = point
	C01Kit.exit(level, C + Vector3(-10.2, HIGH + 0.6, 4.25), Vector3(1.0, 1.2, 0.5), &"s1", &"da_scorciatoia", func() -> bool: return GameState.has_flag(&"c01_shortcut_ruggero"))
	ruggero = _saved(terrace_2, Vector3(7.8, SLAB, -1.5), &"c01_saved_ruggero", RUGGERO_TEXTURE, shortcut)
	ruggero.tied.connect(_on_ruggero_tied)
	_lever(terrace_2, Vector3(-6.5, SLAB, -2.5), terrace_2).position = Vector3(-6.5, SLAB, -2.5)
	# The ramp's foot, toward room 5, while it points south.
	C01Kit.exit(level, C + Vector3(-2.0, LOW + 0.6, 9.2), Vector3(3.2, 1.2, 1.0), &"s5", &"da_rampa", func() -> bool: return terrace_2.quarter == 2 and not terrace_2.turning)
	# Down the ladder to room 3, and across the bridge to room 2.
	C01Kit.exit(level, C + Vector3(-11.9, HIGH + 0.6, 3.9), Vector3(1.0, 1.2, 1.2), &"s3", &"da_rampa")
	C01Kit.exit(level, C + Vector3(-11.9, HIGH + 0.6, -1.0), Vector3(1.0, 1.2, 2.0), &"s2", &"da_ponte", bridge_high_down)
	_build_bonus(cart)


## The bonus branch at medium and hard (40): behind a hedge of stems to
## break, a small hidden terrace (6 x 5) with a patch, a warm stone and a
## memory. At easy the hedge is a wall of wood.
func _build_bonus(cart: Node3D) -> void:
	var hedge_x: float = C.x - 10.5
	if Difficulty.is_easy():
		C01Kit.box(cart, Vector3(hedge_x, HIGH + 0.7, C.z - 1.8), Vector3(3.0, 1.4, 0.3), C01Kit.WOOD_DARK)
		return
	C01Kit.box(cart, Vector3(hedge_x, HIGH - 0.25, C.z - 5.5), Vector3(6.0, 0.5, 5.0), C01Kit.WOOD)
	for index: int in 3:
		var look: MeshInstance3D = C01Kit.card_look(C01Kit.STEM_CARD, 0.8)
		var stem: Breakable = Breakable.create(level, Vector3(hedge_x - 1.0 + index, HIGH, C.z - 2.0), look, CreatureTuning.health_for_hits(3.0), C01Kit.EAR)
		bonus_hedge.append(stem)
	_pickup(&"patch_oiled_leather", &"c01_bonus_leather", Vector3(hedge_x - 1.5, HIGH, C.z - 6.5))
	_pickup(&"warm_stone", &"c01_bonus_stone", Vector3(hedge_x + 1.5, HIGH, C.z - 6.5))
	_pickup(&"memory_carved_stake", &"c01_bonus_stake", Vector3(hedge_x, HIGH, C.z - 7.4))
	C01Kit.visual(cart, Vector3(hedge_x, HIGH + 0.6, C.z - 7.8), Vector3(0.12, 1.2, 0.12), C01Kit.WOOD)


# --- Room 5: the low terrace of the second cart ---------------------------------

func _build_low_terrace_2() -> void:
	var cart: Node3D = _group(&"Cart2Low")
	C01Kit.ground(cart, D + Vector3(4.0, -0.5, 0.0), Vector3(48.0, 1.0, 30.0), 1075)
	C01Kit.box(cart, D + Vector3(0.0, 0.8, 0.0), Vector3(24.0, 1.6, 10.0), C01Kit.WOOD_DARK)
	# The column of the high terrace (the terrace itself is left out: it
	# would hide the room from the camera), and the first cart to the west
	# casting shade.
	C01Kit.box(cart, D + Vector3(0.0, (LOW + HIGH) * 0.5 - SLAB, 0.0), Vector3(1.6, HIGH - LOW - SLAB, 1.6), C01Kit.WOOD_DARK)
	C01Kit.visual(cart, D + Vector3(-22.0, 3.5, -2.0), Vector3(12.0, 7.0, 12.0), C01Kit.WOOD_DARK)
	# The deck at the east end of the cart and the low plank bridge.
	C01Kit.box(cart, D + Vector3(11.0, LOW - 0.25, 0.0), Vector3(2.0, 0.5, 4.0), C01Kit.WOOD)
	var r5: Room = _room(&"s5", D + Vector3(4.0, LOW + 1.2, 0.0), Vector3(36.0, 3.4, 22.0), &"da_rampa")
	# The terrace (20 x 9), aligned. Its lever lowers the bridge at the
	# second turn (quarter 2, aligned again: its east end meets the deck).
	terrace_3 = _terrace(&"Terrace3", D + Vector3(0.0, LOW - SLAB, 0.0), Vector2(20.0, 9.0), 0)
	C01Kit.rails_around(terrace_3, Vector3(0.0, SLAB, 0.0), Vector2(20.0, 9.0), [["e", -2.0, 2.0], ["w", -2.0, 2.0], ["s", -4.0, 0.0]])
	_terrace_entry(terrace_3, &"s5", &"da_rampa", Vector3(-2.0, SLAB + 0.05, 3.3))
	var from_bridge: RoomEntry = C01Kit.entry(r5, &"da_ponte", D + Vector3(11.0, LOW + 0.05, 0.0))
	from_bridge.name = "Entry_da_ponte"
	for x: float in [-7.0, -5.5, -4.0, 5.0, 6.5]:
		C01Kit.cabbage_on(terrace_3, Vector3(x, SLAB, -3.0))
	C01Kit.ears(terrace_3, Rect2(-8.5, -1.5, 6.0, 4.0), SLAB)
	for spot: Vector3 in [Vector3(7.5, 0.0, 2.8), Vector3(8.5, 0.0, 2.8), Vector3(8.0, 0.0, 1.8)]:
		C01Kit.shape_on(terrace_3, spot + Vector3.UP * (SLAB + 0.4), Vector3(0.8, 0.8, 0.8), C01Kit.WOOD.lightened(0.1))
	var lever: TurnLever = _lever(terrace_3, Vector3.ZERO, terrace_3)
	lever.position = Vector3(0.0, SLAB, 3.2)
	terrace_3.turn_finished.connect(func(quarter: int) -> void:
		if quarter == 2 and not GameState.has_flag(&"c01_bridge_low"):
			GameState.set_flag(&"c01_bridge_low")
			_show_bridges())
	_bridge_low_look = Node3D.new()
	level.add_child(_bridge_low_look)
	C01Kit.visual(_bridge_low_look, D + Vector3(16.0, LOW - 0.1, 0.0), Vector3(8.0, 0.15, 2.0), C01Kit.WOOD.lightened(0.2))
	C01Kit.exit(level, D + Vector3(12.2, LOW + 0.6, 0.0), Vector3(0.6, 1.2, 2.0), &"s6", &"da_ponte", func() -> bool: return GameState.has_flag(&"c01_bridge_low"))
	# Back up the ramp of room 4 (it points here only after two turns).
	C01Kit.exit(level, D + Vector3(-2.0, LOW + 0.6, 4.4), Vector3(2.4, 1.2, 0.6), &"s4", &"da_scala", func() -> bool: return terrace_2.quarter == 2)
	# 3 Foglioni feeding on light, 3 Voltafaccia.
	for spot: Vector3 in [Vector3(-6.0, 0.0, 1.0), Vector3(-1.0, 0.0, -1.5), Vector3(4.0, 0.0, 1.2)]:
		_creature(Foglione.new(), terrace_3.to_global(spot + Vector3.UP * (SLAB + 0.05)))
	for spot: Vector3 in [Vector3(1.5, 0.0, 2.5), Vector3(6.0, 0.0, -1.0), Vector3(-3.5, 0.0, 2.8)]:
		_creature(VOLTAFACCIA_SCENE.instantiate() as CombatEnemy, terrace_3.to_global(spot + Vector3.UP * (SLAB + 0.05)))


# --- Room 6: the upturned terrace of the third cart -------------------------------

func _build_frozen_terrace() -> void:
	var cart: Node3D = _group(&"Cart3Low")
	C01Kit.ground(cart, E + Vector3(0.0, -0.5, 0.0), Vector3(40.0, 1.0, 30.0), 1076)
	C01Kit.box(cart, E + Vector3(0.0, 0.8, 0.0), Vector3(24.0, 1.6, 10.0), C01Kit.WOOD_DARK)
	# The second cart to the west throws its shadow over the whole room.
	C01Kit.visual(cart, E + Vector3(-20.0, 4.0, 0.0), Vector3(10.0, 8.0, 14.0), C01Kit.WOOD_DARK)
	C01Kit.box(cart, E + Vector3(-10.0, LOW - 0.25, 0.0), Vector3(4.0, 0.5, 4.0), C01Kit.WOOD)
	var r6: Room = _room(&"s6", E + Vector3(0.0, LOW + 1.3, 0.0), Vector3(24.0, 3.6, 22.0), &"da_ponte")
	C01Kit.entry(r6, &"da_ponte", E + Vector3(-11.0, LOW + 0.05, 0.0))
	# The terrace (16 x 9) left turned and tilted for so long that the plants
	# grew into a cage. Its opening toward the ladder faces away (south).
	# The lever is locked by ice; its first pull turns the terrace crosswise
	# and brings it back level, the second turns its opening to the ladder.
	terrace_4 = _terrace(&"Terrace4", E + Vector3(0.0, LOW - SLAB, 0.0), Vector2(16.0, 9.0), 0)
	terrace_4.rotation.x = deg_to_rad(6.0)
	C01Kit.rails_around(terrace_4, Vector3(0.0, SLAB, 0.0), Vector2(16.0, 9.0), [["w", -2.0, 2.0], ["e", -2.0, 2.0], ["s", -1.5, 1.5]])
	C01Kit.tubers(terrace_4, Rect2(-7.5, -4.0, 15.0, 8.0), SLAB)
	C01Kit.visual(terrace_4, Vector3(0.0, SLAB + 0.02, 0.0), Vector3(16.0, 0.04, 9.0), Color(0.86, 0.9, 1.0))
	# Pia asleep in the cage of plants: six stems, three strikes each.
	pia = _saved(terrace_4, Vector3(3.0, SLAB, 0.0), &"c01_saved_pia", PIA_TEXTURE, null)
	pia.locked = true
	pia.tied.connect(_on_pia_tied)
	pia_cage = C01Kit.cage(terrace_4, Vector3(3.0, SLAB, 0.0))
	for index: int in 6:
		var angle: float = TAU * index / 6.0
		var look: MeshInstance3D = C01Kit.card_look(C01Kit.STEM_CARD)
		var stem: Breakable = Breakable.create(level, terrace_4.to_global(Vector3(3.0 + cos(angle) * 1.3, SLAB, sin(angle) * 1.3)), look, CreatureTuning.health_for_hits(3.0), Color(0.5, 0.62, 0.42))
		stem.broken.connect(_on_stem_broken)
		stems.append(stem)
	# The lever, under a crust of ice.
	var crust_look: MeshInstance3D = MeshInstance3D.new()
	var crust_mesh: BoxMesh = BoxMesh.new()
	crust_mesh.size = Vector3(1.0, 1.0, 0.9)
	crust_look.mesh = crust_mesh
	crust_look.material_override = C01Kit.material(Color(0.72, 0.86, 0.98))
	crust_look.position = Vector3.UP * 0.5
	ice_crust = Breakable.create(level, E + Vector3(-9.8, LOW, -1.2), crust_look, CreatureTuning.health_for_hits(2.0), Color(0.8, 0.9, 1.0))
	lever_s6 = _lever(level, E + Vector3(-10.4, LOW, -1.6), terrace_4)
	lever_s6.locked = true
	ice_crust.broken.connect(lever_s6.unlock)
	# Every turn changes something one can see: the first brings it back
	# level (the cage stands upright), the second its opening to the ladder.
	lever_s6.pulled.connect(func() -> void:
		if terrace_4.quarter == 0:
			var tween: Tween = create_tween()
			tween.tween_property(terrace_4, "rotation:x", 0.0, terrace_4.turn_seconds()))
	# Pia's shortcut: a rope tied to a post, down to the entry of the dungeon.
	var shortcut: RescueShortcut = RescueShortcut.new()
	shortcut.name = "PiaShortcut"
	shortcut.shortcut_id = &"c01_shortcut_pia"
	shortcut.reveal = "unroll"
	level.add_child(shortcut)
	shortcut.global_position = E + Vector3(-11.6, LOW + 1.0, 1.7)
	C01Kit.visual(shortcut, Vector3(0.0, -1.5, 0.0), Vector3(0.12, 3.0, 0.12), C01Kit.CLOTH.lightened(0.3))
	for point: Vector3 in [E + Vector3(-10.5, LOW, 1.2), E + Vector3(-11.6, LOW, 1.7), E + Vector3(-12.4, 0.05, 1.7), E + Vector3(-16.0, 0.05, 6.0)]:
		var marker: Marker3D = Marker3D.new()
		shortcut.add_child(marker)
		marker.global_position = point
	pia.shortcut = shortcut
	C01Kit.exit(level, E + Vector3(-11.7, LOW + 0.6, 1.7), Vector3(0.6, 1.2, 0.6), &"s1", &"da_scorciatoia", func() -> bool: return GameState.has_flag(&"c01_shortcut_pia"))
	# The ladder up to the top, usable once Pia is saved and the terrace is
	# level and aligned (its north side opening meets the ladder).
	C01Kit.box(cart, E + Vector3(0.0, (LOW + TOP) * 0.5 + 0.3, -5.0), Vector3(2.0, TOP - LOW - 0.6, 0.3), C01Kit.WOOD)
	ladder_to_top = ClimbSpot.create(level, E + Vector3(0.0, LOW + 1.0, -4.5), Vector3(1.8, 2.0, 0.6), E + Vector3(0.0, TOP + 0.05, -5.5), Vector3.BACK)
	ladder_to_top.monitoring = false
	C01Kit.box(cart, E + Vector3(0.0, TOP - 0.1, -5.6), Vector3(2.0, 0.2, 1.4), C01Kit.WOOD)
	C01Kit.exit(level, E + Vector3(0.0, TOP + 0.6, -5.8), Vector3(1.8, 1.2, 0.8), &"s7", &"da_scala")
	C01Kit.exit(level, E + Vector3(-12.0, LOW + 0.6, -0.4), Vector3(0.6, 1.2, 1.6), &"s5", &"da_ponte")
	# 2 Raspageli in the soft soil, 2 Cocci.
	for spot: Vector3 in [Vector3(-4.0, 0.0, 2.0), Vector3(-1.0, 0.0, -2.5)]:
		var rodent: Raspagelo = RASPAGELO_SCENE.instantiate() as Raspagelo
		rodent.hidden_start = true
		_creature(rodent, terrace_4.to_global(spot + Vector3.UP * (SLAB + 0.05)))
	for spot: Vector3 in [Vector3(-5.5, 0.0, -1.0), Vector3(-2.5, 0.0, 3.2)]:
		_creature(Coccio.new(), terrace_4.to_global(spot + Vector3.UP * (SLAB + 0.05)))
	terrace_4.turn_finished.connect(func(_quarter: int) -> void: _update_ladder())


# --- Room 7: the top and the boss --------------------------------------------

func _build_top() -> void:
	var top: Node3D = _group(&"Top")
	C01Kit.ground(top, F + Vector3(0.0, -0.5, 0.0), Vector3(40.0, 1.0, 40.0), 1077)
	C01Kit.box(top, F + Vector3(0.0, TOP * 0.5 - 0.3, 0.0), Vector3(3.0, TOP - 0.6, 3.0), C01Kit.WOOD_DARK)
	# The fixed rim round the turning top, with four levers, one per side.
	for index: int in 16:
		var angle: float = TAU * index / 16.0
		var at: Vector3 = F + Vector3(cos(angle), 0.0, sin(angle)) * 8.9 + Vector3.UP * (TOP - 0.25)
		C01Kit.box(top, at, Vector3(1.8, 0.5, 3.6), C01Kit.WOOD, Vector3(0.0, -angle, 0.0))
		C01Kit.box(top, F + Vector3(cos(angle), 0.0, sin(angle)) * 9.7 + Vector3.UP * (TOP + 0.45), Vector3(0.15, 0.9, 3.8), C01Kit.WOOD_DARK, Vector3(0.0, -angle, 0.0))
	var r7: Room = _room(&"s7", F + Vector3(0.0, TOP + 1.2, 0.0), Vector3(22.0, 3.6, 22.0), &"da_scala")
	r7.camera_distance = 24.0
	C01Kit.entry(r7, &"da_scala", F + Vector3(0.0, TOP + 0.05, 8.9))
	arena = TurningPlatform.new()
	arena.name = "Arena"
	arena.tuning = CHAPTER_TUNING
	arena.carry_size = Vector3(16.0, 3.0, 16.0)
	arena.carry_offset = Vector3(0.0, 1.8, 0.0)
	level.add_child(arena)
	arena.global_position = F + Vector3(0.0, TOP - SLAB, 0.0)
	var disc: CollisionShape3D = CollisionShape3D.new()
	var cylinder: CylinderShape3D = CylinderShape3D.new()
	cylinder.radius = 8.0
	cylinder.height = SLAB
	disc.shape = cylinder
	disc.position = Vector3.UP * SLAB * 0.5
	arena.add_child(disc)
	var disc_look: MeshInstance3D = MeshInstance3D.new()
	var disc_mesh: CylinderMesh = CylinderMesh.new()
	disc_mesh.top_radius = 8.0
	disc_mesh.bottom_radius = 8.0
	disc_mesh.height = SLAB
	disc_mesh.radial_segments = 32
	disc_look.mesh = disc_mesh
	disc_look.material_override = C01Kit.material(C01Kit.WOOD.lightened(0.1))
	disc_look.position = Vector3.UP * SLAB * 0.5
	arena.add_child(disc_look)
	# Plank lines, so the turn can be seen.
	for x: float in range(-7, 8, 2):
		C01Kit.visual(arena, Vector3(float(x), SLAB + 0.01, 0.0), Vector3(0.08, 0.02, 2.0 * sqrt(64.0 - x * x)), C01Kit.WOOD_DARK)
	boss = RootedFoglione.new()
	boss.name = "RootedFoglione"
	boss.position = F + Vector3(0.0, TOP + 0.02, 0.0)
	level.add_child(boss)
	for index: int in 4:
		var angle: float = TAU * index / 4.0 + PI * 0.5
		var lever: TurnLever = _lever(level, F + Vector3(cos(angle), 0.0, sin(angle)) * 9.3 + Vector3.UP * TOP + Vector3(sin(angle), 0.0, -cos(angle)) * 1.2, arena)
		arena_levers.append(lever)
	arena_node = SummitArena.new()
	arena_node.name = "SummitArena"
	arena_node.room_path = NodePath()
	add_child(arena_node)
	arena_node.setup(r7, boss, arena, arena_levers)
	arena_node.won_fight.connect(_on_boss_gone)


# --- Events ------------------------------------------------------------------

func bridge_high_down() -> bool:
	return Difficulty.is_easy() or GameState.has_flag(&"c01_bridge_high")


func _show_bridges() -> void:
	_bridge_high_look.visible = bridge_high_down()
	_bridge_low_look.visible = GameState.has_flag(&"c01_bridge_low")


func _on_room_changed(room: Room) -> void:
	_show_bridges()
	var light: Dictionary = ROOM_LIGHT.get(room.room_id, {})
	if not light.is_empty():
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(sun, "light_color", light["color"], 0.4)
		tween.tween_property(sun, "light_energy", light["energy"], 0.4)
		# Each diorama sits far from the others in the world: its palette is
		# centred on it (51), with its own value of the zone.
		palette.night_proximity = float(light["zone"])
		palette.center_x = room.global_position.x
		palette.apply()
	var hint: StringName = &""
	match room.room_id:
		&"s2":
			hint = &"HINT_C01_DAY_BEASTS"
		&"s3":
			hint = &"HINT_C01_TALL_GRASS"
	if hint != &"" and not GameState.has_flag(StringName("hint_" + String(room.room_id))):
		GameState.set_flag(StringName("hint_" + String(room.room_id)))
		hints.show_hint(hint, &"")
		get_tree().create_timer(6.0).timeout.connect(func() -> void:
			if hints.current_hint() == hint:
				hints.hide_hint())


func _on_ruggero_tied() -> void:
	await _lines(RUGGERO_LINES)
	# From above, the bridge toward room 2 comes down too (room 4).
	GameState.set_flag(&"c01_bridge_high")
	_show_bridges()
	ruggero.go_home()


func _on_stem_broken() -> void:
	for stem: Breakable in stems:
		if stem.is_alive():
			return
	pia.locked = false
	# Without its six stems the cage of crops falls apart.
	var tween: Tween = create_tween()
	tween.tween_property(pia_cage, "scale", Vector3(1.3, 0.05, 1.3), 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void: pia_cage.visible = false)


func _on_pia_tied() -> void:
	await _lines(PIA_LINES)
	pia.go_home()
	_update_ladder()


func _update_ladder() -> void:
	ladder_to_top.monitoring = pia.saved and terrace_4.quarter == 2 and not terrace_4.turning


func _on_boss_gone() -> void:
	won = true
	GameState.set_flag(&"c01_boss_beaten")
	chapter_won.emit()
	if not leave_scene:
		return
	await get_tree().create_timer(1.0).timeout
	var fade: ColorRect = ColorRect.new()
	fade.color = Color(0.0, 0.0, 0.0, 0.0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 45
	layer.add_child(fade)
	add_child(layer)
	var tween: Tween = create_tween()
	tween.tween_property(fade, "color:a", 1.0, 1.2)
	await tween.finished
	get_tree().change_scene_to_file(END_SCENE)


func _lines(lines: Array[Array]) -> void:
	ottavia.controls_enabled = false
	for line: Array in lines:
		var voice: float = dialogue.show_line(line[0], line[1])
		await get_tree().create_timer(DialogueBox.line_wait(line_seconds, voice)).timeout
	dialogue.hide_box()
	ottavia.controls_enabled = true


# --- Helpers -------------------------------------------------------------------

func _group(group_name: StringName) -> Node3D:
	var node: Node3D = Node3D.new()
	node.name = group_name
	level.add_child(node)
	return node


func _room(id: StringName, center: Vector3, size: Vector3, default_entry: StringName) -> Room:
	var made: Room = C01Kit.room(level, id, center, size, default_entry)
	rooms[id] = made
	return made


## Invisible walls round a rectangle (x, z) of a ground room, with gaps.
func _bounds(parent: Node3D, area: Rect2, gaps: Array[Rect2]) -> void:
	var body: StaticBody3D = StaticBody3D.new()
	parent.add_child(body)
	for side: Array in [
		[Vector3(area.get_center().x, 1.5, area.position.y - 0.25), Vector3(area.size.x + 1.0, 3.0, 0.5)],
		[Vector3(area.get_center().x, 1.5, area.end.y + 0.25), Vector3(area.size.x + 1.0, 3.0, 0.5)],
		[Vector3(area.position.x - 0.25, 1.5, area.get_center().y), Vector3(0.5, 3.0, area.size.y + 1.0)],
		[Vector3(area.end.x + 0.25, 1.5, area.get_center().y), Vector3(0.5, 3.0, area.size.y + 1.0)],
	]:
		var at: Vector3 = side[0]
		var skip: bool = false
		for gap: Rect2 in gaps:
			skip = skip or gap.has_point(Vector2(at.x, at.z))
		if skip:
			continue
		var shape: CollisionShape3D = CollisionShape3D.new()
		var box: BoxShape3D = BoxShape3D.new()
		box.size = side[1]
		shape.shape = box
		shape.position = at
		body.add_child(shape)


## An entry on a turning terrace: it turns with it and belongs to `room_id`.
func _terrace_entry(terrace: TurningPlatform, room_id: StringName, id: StringName, local: Vector3) -> RoomEntry:
	var entry: RoomEntry = RoomEntry.new()
	entry.entry_id = id
	entry.room_id = room_id
	entry.name = "Entry_" + String(id)
	terrace.add_child(entry)
	entry.position = local
	return entry


## A terrace on a turntable: `size` (x, z) slab whose top is at the node's
## height plus SLAB.
func _terrace(node_name: StringName, at: Vector3, size: Vector2, start_quarter: int) -> TurningPlatform:
	var terrace: TurningPlatform = TurningPlatform.new()
	terrace.name = node_name
	terrace.tuning = CHAPTER_TUNING
	terrace.start_quarter = start_quarter
	var reach: float = maxf(size.x, size.y)
	terrace.carry_size = Vector3(reach + 1.0, 3.0, reach + 1.0)
	terrace.carry_offset = Vector3(0.0, 1.6, 0.0)
	level.add_child(terrace)
	terrace.global_position = at
	C01Kit.shape_on(terrace, Vector3(0.0, SLAB * 0.5, 0.0), Vector3(size.x, SLAB, size.y), C01Kit.SOIL)
	return terrace


func _lever(parent: Node3D, at: Vector3, platform: TurningPlatform) -> TurnLever:
	var lever: TurnLever = TurnLever.new()
	lever.platform = platform
	parent.add_child(lever)
	if parent == level:
		lever.global_position = at
	lever.platform = platform
	return lever


## A creature placed at `at` (world) before it enters the tree, so its
## start point (105) is right.
func _creature(creature: CombatEnemy, at: Vector3) -> CombatEnemy:
	creature.position = at
	level.add_child(creature)
	return creature


func _saved(parent: Node3D, at: Vector3, id: StringName, texture: Texture2D, shortcut: RescueShortcut) -> RescuedPerson:
	var person: RescuedPerson = RescuedPerson.new()
	person.person_id = id
	person.radius = 1.8
	person.wait_for_level = true
	person.shortcut = shortcut
	var sprite: NpcSprite = NpcSprite.new()
	sprite.sprite_texture = texture
	person.add_child(sprite)
	parent.add_child(person)
	person.position = at
	return person


func _pickup(item: StringName, id: StringName, at: Vector3) -> void:
	var pickup: WorldPickup = WorldPickup.new()
	pickup.item_id = item
	pickup.pickup_id = id
	level.add_child(pickup)
	pickup.global_position = at
