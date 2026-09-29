class_name TrucePlain
extends Node3D
## The Truce of chapter 1 (107, docs/livelli/capitolo-01.md section 3) in
## its placeholder form (phase 4b step 2): the plain round the parked
## caravan, about 80 x 50 m, the Day to the west (dry straw, cracked flat
## stones, burnt shrubs), the Night to the east (frost, a frozen pond about
## 12 m across, a darker sky). The field-carts on the left of the column,
## Anselmo's truck at the far right; by the Generators, vents breathing
## warm air over heaps of reservoir stones.
## The Meridian calls the Truce and the sundial starts (7 minutes). Talking
## to Iole takes Ottavia into the dungeon; if the shadow reaches the end
## first, Iole runs to her. What is not gathered stays here (39).
##
## Command-line user arguments (after "--"):
##   truce_seconds=<s>  a shorter Truce (captures, tests)
##   intro=0            no Meridian line at the start
##   spot=pond          start by the frozen pond (captures)

const CHAPTER_TUNING: ChapterTuning = preload("res://assets/combat/chapter_01_tuning.tres")
const DUNGEON_SCENE: String = "res://scenes/capitolo01/carri_campo.tscn"
const FIELD_CART: String = "res://assets/models/vehicles/carro_campo_prova.glb"
const CONDOMINIO: String = "res://assets/models/vehicles/camion_condominio_prova.glb"
const LEAD_VEHICLE: String = "res://assets/models/vehicles/mezzo_di_testa_prova.glb"
const IOLE_TEXTURE: Texture2D = preload("res://assets/sprites/capitolo01/iole/idle_s.png")
const IOLE_TALK: Texture2D = preload("res://assets/sprites/capitolo01/iole/talk_s.png")
const IOLE_WALK: Texture2D = preload("res://assets/sprites/capitolo01/iole/walk_e.png")
const MERIDIAN_TEXTURE: Texture2D = preload("res://assets/sprites/comparse/gnomone_south.png")
const CAMP_MUSIC: AudioStream = preload("res://assets/audio/music/m2_accampamento.ogg")
const SIZE: Vector2 = Vector2(80.0, 50.0)
## Value of the zone for the world palette (51, section 1).
const ZONE_VALUE: float = -0.15
const START: Vector3 = Vector3(4.0, 0.05, 10.0)
const IOLE_SPOT: Vector3 = Vector3(-10.0, 0.0, 2.0)
const POND_CENTER: Vector3 = Vector3(27.0, 0.0, 8.0)
const POND_RADIUS: float = 6.0
const IOLE_LINES: Array[Array] = [
	[&"SPEAKER_IOLE", &"C01_IOLE_01"],
	[&"SPEAKER_OTTAVIA", &"C01_OTTAVIA_01"],
	[&"SPEAKER_IOLE", &"C01_IOLE_02"],
]
## The three crowd members with a line (121): trade, look, spot, line.
const BARKS: Array[Array] = [
	[&"traslocanti", "uomo_adulto", Vector3(-1.0, 0.0, 8.0), &"SPEAKER_TRASLOCANTE", &"C01_TRASLOCANTE"],
	[&"tessibuio", "donna_giovane", Vector3(6.0, 0.0, -3.0), &"SPEAKER_TESSIBUIO_WOMAN", &"C01_TESSIBUIO"],
	[&"brinaioli", "uomo_anziano", Vector3(21.0, 0.0, 12.0), &"SPEAKER_BRINAIOLO", &"C01_BRINAIOLO"],
]
const BARK_METERS: float = 3.5
const BARK_SECONDS: float = 4.0
## The wheel tracks of the column across the plain, for the ground mask.
const TRACKS: Array[Dictionary] = [
	{"points": [Vector2(-60.0, -12.0), Vector2(-10.0, -6.0), Vector2(20.0, -7.0), Vector2(60.0, -10.0)], "half_width": 2.6},
]
const DAY_ENTRIES: Array[String] = [
	"res://assets/vegetation_kit/erba_alta_01.tres",
	"res://assets/vegetation_kit/ciuffo_erba_01.tres",
	"res://assets/vegetation_kit/ciuffo_erba_02.tres",
	"res://assets/vegetation_kit/sassi_01.tres",
]
## Kept clear of scenery: where the vehicles, the people, the things to
## gather and the pond are (centre x, z and radius).
const CLEAR: Array[Vector3] = [
	Vector3(-14.0, -10.0, 9.0), Vector3(-2.0, -13.0, 9.0), Vector3(10.0, -11.0, 9.0), Vector3(-30.0, -14.0, 8.0),
	Vector3(8.0, 0.0, 12.0), Vector3(-20.0, 4.0, 7.0), Vector3(20.0, -2.0, 7.0), Vector3(-6.0, 14.0, 7.0),
	Vector3(14.0, 16.0, 7.0), Vector3(33.0, -14.0, 7.0), Vector3(-10.0, 2.0, 3.0), Vector3(4.0, 10.0, 3.0),
	Vector3(0.0, 7.0, 3.0), Vector3(-3.0, -18.0, 3.0), Vector3(-31.0, 5.0, 2.0), Vector3(27.0, 8.0, 10.0),
	Vector3(-24.0, -9.0, 2.0),
]

## Seconds each line stays when it has no voice; tests shorten it.
@export var line_seconds: float = 3.4
## False in tests: going into the dungeon does everything but load it.
@export var leave_scene: bool = true

signal left_for_dungeon

@onready var ottavia: OttaviaProto = $Ottavia
@onready var camera_rig: FollowCameraRig = $CameraRig
@onready var dialogue: DialogueBox = $DialogueBox
@onready var hints: HintBanner = $HintBanner
@onready var sun: DirectionalLight3D = $Sun
@onready var level: Node3D = $Level

var clock: TruceClock
var sundial: TruceSundial
var caller: TruceCaller
var iole: Interactable
var iole_sprite: NpcSprite
var pellegrino: Pellegrino
var marker: ObjectiveMarker
var leaving: bool = false
var _barks: Array[Dictionary] = []
var _bubble: SpeechBubble
var _bark_left: float = 0.0


func _ready() -> void:
	GameOptions.load_options()
	InputRemap.load_controls()
	sun.add_to_group(&"sun")
	NpcSprite.sun_azimuth_degrees = sun.rotation_degrees.y
	# «Continue» from the Truce autosave starts the Truce over (95).
	SaveGame.take_pending(scene_file_path)
	var tuning: ChapterTuning = CHAPTER_TUNING
	var intro: bool = true
	var start: Vector3 = START
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("truce_seconds="):
			tuning = CHAPTER_TUNING.duplicate() as ChapterTuning
			tuning.truce_seconds = argument.trim_prefix("truce_seconds=").to_float()
			tuning.truce_warning_seconds = minf(tuning.truce_warning_seconds, tuning.truce_seconds * 0.5)
		elif argument == "intro=0":
			intro = false
		elif argument == "spot=pond":
			start = POND_CENTER + Vector3(-4.0, 0.05, 10.0)
	# The Twilight a little toward the Day (section 1); the plain drifts to
	# the Day on the west and to the Night on the east (51).
	var palette: ZonePalette = ZonePalette.new()
	palette.name = "ZonePalette"
	palette.night_proximity = ZONE_VALUE
	palette.gradient_width = 60.0
	add_child(palette)
	_build_ground()
	_build_caravan()
	_build_things()
	_build_people()
	ottavia.global_position = start
	ottavia.face_toward(Vector3.FORWARD)
	camera_rig.target = ottavia
	camera_rig.limits = Rect2(Vector2(-SIZE.x * 0.5 + 6.0, -SIZE.y * 0.5 + 4.0), SIZE - Vector2(12.0, 6.0))
	camera_rig.snap_to_target()
	var menu: OptionsMenu = OptionsMenu.new()
	menu.name = "OptionsMenu"
	add_child(menu)
	($CombatHud as CombatHud).bind(ottavia)
	# F1: the values of the chapter, to tune while playing (phase 4b).
	TuningPanel.for_chapter(self, ottavia.combat.tuning, preload("res://assets/combat/creature_tuning.tres"), preload("res://assets/combat/chapter_01_tuning.tres"))
	clock = TruceClock.new()
	clock.name = "TruceClock"
	clock.tuning = tuning
	add_child(clock)
	clock.warning.connect(_on_warning)
	clock.expired.connect(_on_expired)
	sundial = TruceSundial.new()
	add_child(sundial)
	sundial.bind(clock)
	_bubble = SpeechBubble.new()
	add_child(_bubble)
	marker = ObjectiveMarker.new()
	level.add_child(marker)
	GameAudio.play_music(CAMP_MUSIC, 2.0, -6.0)
	_begin.call_deferred(intro)


## The Meridian calls the Truce; the sundial starts; autosave (95).
func _begin(intro: bool) -> void:
	if intro:
		ottavia.controls_enabled = false
		SoundBank.play_sound(get_tree(), &"tromba_gnomone", 0.0)
		var voice: float = dialogue.show_line(&"SPEAKER_GNOMONE", &"C01_MERIDIAN_TRUCE")
		await get_tree().create_timer(DialogueBox.line_wait(line_seconds, voice)).timeout
		dialogue.hide_box()
		ottavia.controls_enabled = true
	clock.start(ottavia.combat.tuning.warm_stone_max)
	if OS.get_cmdline_user_args().is_empty() and get_tree().get_script() == null:
		SaveGame.autosave(get_tree(), &"", &"", &"truce")
	marker.point_to_node(iole_sprite, Vector3.UP * 2.2)
	hints.show_goal(&"C01_GOAL_IOLE")


func _process(delta: float) -> void:
	_update_barks(delta)


# --- The place ---------------------------------------------------------------

func _build_ground() -> void:
	var half: Vector2 = SIZE * 0.5
	# The ground of the prologue plain (106): meadows blended with roads,
	# gravel and frost toward the Night, so it never shows one repeated
	# pattern; flat where one plays.
	CampScenery.flat_rects = [Rect2(-half.x - 6.0, -half.y - 6.0, SIZE.x + 12.0, SIZE.y + 12.0)]
	CampScenery.hollow_meters = CampScenery.HOLLOW_METERS
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = 107
	CampScenery.build_ground(level, random, TRACKS)
	# More of the second meadow than in the camp: the tile does not repeat
	# in a grid under the camera (phase 4b step 3 review).
	var ground: MeshInstance3D = level.get_node("Ground") as MeshInstance3D
	(ground.material_override as ShaderMaterial).set_shader_parameter(&"alt_amount", 0.5)
	(ground.material_override as ShaderMaterial).set_shader_parameter(&"alt_patch_meters", 6.0)
	var tufts: VegetationScatter = VegetationScatter.new()
	var tuft_entries: Array[VegetationEntry] = []
	for path: String in CampScenery.GRASS_ENTRIES:
		tuft_entries.append(load(path) as VegetationEntry)
	tufts.entries = tuft_entries
	tufts.extents = half + Vector2(8.0, 8.0)
	tufts.density = 0.35
	tufts.random_seed = 1072
	level.add_child(tufts)
	# The Day side: dry tall grass, burnt shrubs, cracked flat stones.
	var dry: VegetationScatter = VegetationScatter.new()
	var entries: Array[VegetationEntry] = []
	for path: String in DAY_ENTRIES:
		entries.append(load(path) as VegetationEntry)
	dry.entries = entries
	dry.extents = Vector2(24.0, half.y)
	dry.density = 0.5
	dry.random_seed = 1071
	dry.position = Vector3(-half.x + 18.0, 0.0, 0.0)
	level.add_child(dry)
	for index: int in 18:
		var at: Vector3 = Vector3(random.randf_range(-half.x + 2.0, -18.0), 0.06, random.randf_range(-half.y + 3.0, half.y - 3.0))
		if _is_free(at):
			C01Kit.visual(level, at, Vector3(random.randf_range(1.0, 2.2), 0.12, random.randf_range(0.8, 1.8)), C01Kit.STONE, Vector3(0.0, random.randf() * PI, 0.0))
	var shrub: VegetationEntry = load("res://assets/vegetation_kit/cespuglio_secco_01.tres")
	for index: int in 10:
		var at: Vector3 = Vector3(random.randf_range(-half.x + 3.0, -16.0), 0.0, random.randf_range(-half.y + 3.0, half.y - 3.0))
		if not _is_free(at):
			continue
		var bush: Node3D = shrub.model.instantiate()
		bush.position = at
		bush.rotation.y = random.randf_range(-PI, PI)
		level.add_child(bush)
	# The Night side: the frost field of the prologue and the frozen pond.
	CampScenery.dress_frost_field(level, Rect2(half.x - 20.0, -half.y, 20.0, SIZE.y), _is_free)
	var pond: MeshInstance3D = MeshInstance3D.new()
	var disc: CylinderMesh = CylinderMesh.new()
	disc.top_radius = POND_RADIUS
	disc.bottom_radius = POND_RADIUS
	disc.height = 0.04
	disc.radial_segments = 32
	pond.mesh = disc
	pond.material_override = C01Kit.material(Color(0.62, 0.78, 0.92))
	pond.position = POND_CENTER + Vector3.UP * 0.03
	level.add_child(pond)
	# Invisible edges of the plain.
	for side: Array in [
		[Vector3(0.0, 1.5, -half.y), Vector3(SIZE.x, 3.0, 0.5)], [Vector3(0.0, 1.5, half.y), Vector3(SIZE.x, 3.0, 0.5)],
		[Vector3(-half.x, 1.5, 0.0), Vector3(0.5, 3.0, SIZE.y)], [Vector3(half.x, 1.5, 0.0), Vector3(0.5, 3.0, SIZE.y)],
	]:
		var wall: StaticBody3D = StaticBody3D.new()
		var shape: CollisionShape3D = CollisionShape3D.new()
		var box: BoxShape3D = BoxShape3D.new()
		box.size = side[1]
		shape.shape = box
		wall.add_child(shape)
		wall.position = side[0]
		level.add_child(wall)


## The caravan parked: the vehicles of the prologue, reused (122-124).
func _build_caravan() -> void:
	# The field-carts, on the left of the column.
	for spot: Vector3 in [Vector3(-14.0, 0.0, -10.0), Vector3(-2.0, 0.0, -13.0), Vector3(10.0, 0.0, -11.0)]:
		_vehicle(_load(FIELD_CART), spot)
	_vehicle(_load(LEAD_VEHICLE), Vector3(-30.0, 0.0, -14.0))
	_vehicle(_load(CONDOMINIO), Vector3(8.0, 0.0, 0.0))
	var recipes: Array = VehicleKit.load_recipes()
	var slots: Array[Vector3] = [Vector3(-20.0, 0.0, 4.0), Vector3(20.0, 0.0, -2.0), Vector3(-6.0, 0.0, 14.0), Vector3(14.0, 0.0, 16.0)]
	for index: int in mini(recipes.size(), slots.size()):
		_vehicle(VehicleKit.build(recipes[index]), slots[index])
	# Anselmo's truck at the far right (a vehicle of the kit as placeholder).
	if recipes.size() > slots.size():
		_vehicle(VehicleKit.build(recipes[slots.size()]), Vector3(33.0, 0.0, -14.0))


func _build_things() -> void:
	# The Generators' vents with heaps of reservoir stones, breathing warm air.
	for x: float in [-1.0, 1.2]:
		C01Kit.box(level, Vector3(x, 0.4, 6.0), Vector3(0.8, 0.8, 0.8), C01Kit.IRON)
	C01Kit.visual(level, Vector3(0.1, 0.2, 7.1), Vector3(1.6, 0.4, 0.9), C01Kit.STONE.darkened(0.2))
	# The tools of the Voltacampi, behind the field-carts.
	for x: float in [-4.5, -3.2, -1.8]:
		C01Kit.visual(level, Vector3(x, 0.8, -19.0), Vector3(0.12, 1.6, 0.12), C01Kit.WOOD, Vector3(0.0, 0.0, 0.3))
	_pickup(&"patch_felt", &"c01_truce_felt", POND_CENTER + Vector3(-1.0, 0.0, 7.2))
	_pickup(&"patch_field_canvas", &"c01_truce_canvas", Vector3(-3.0, 0.05, -18.2))
	_pickup(&"warm_stone", &"c01_truce_stone_vents", Vector3(0.1, 0.05, 8.2))
	_pickup(&"warm_stone", &"c01_truce_stone_cracked", Vector3(-31.0, 0.05, 5.0))
	_pickup(&"warm_stone", &"c01_truce_stone_pond", POND_CENTER + Vector3(-POND_RADIUS - 0.6, 0.05, -1.0))
	_pickup(&"memory_black_seed", &"c01_truce_seed", POND_CENTER + Vector3(POND_RADIUS + 0.8, 0.05, -2.0))
	# The Pellegrino di feltro asleep by the pond, next to the felt patch.
	pellegrino = Pellegrino.new()
	pellegrino.position = POND_CENTER + Vector3(1.5, 0.0, 8.2)
	level.add_child(pellegrino)


func _build_people() -> void:
	iole = Interactable.new()
	iole.name = "Iole"
	iole.radius = 2.0
	level.add_child(iole)
	iole.global_position = IOLE_SPOT
	iole_sprite = NpcSprite.new()
	iole_sprite.sprite_texture = IOLE_TEXTURE
	iole_sprite.frames_per_second = 4.0
	iole.add_child(iole_sprite)
	iole.used.connect(_on_iole_used)
	C01Kit.person(level, Vector3(-24.0, 0.0, -9.0), MERIDIAN_TEXTURE)
	for bark: Array in BARKS:
		var person: NpcSprite = NpcSprite.new()
		person.sprite_texture = load("res://assets/sprites/folla/%s_south.png" % bark[1])
		person.trade = bark[0]
		level.add_child(person)
		person.global_position = bark[2]
		_barks.append({"person": person, "speaker": bark[3], "line": bark[4], "said": false})
	caller = TruceCaller.new()
	caller.name = "IoleRunning"
	caller.sprite_texture = IOLE_TEXTURE
	caller.walk_texture = IOLE_WALK
	level.add_child(caller)


# --- Events ------------------------------------------------------------------

## The three crowd members say their line when Ottavia comes near (121).
func _update_barks(delta: float) -> void:
	if _bark_left > 0.0:
		_bark_left -= delta
		if _bark_left <= 0.0:
			_bubble.hide_bubble()
		return
	for bark: Dictionary in _barks:
		if bool(bark["said"]):
			continue
		var person: NpcSprite = bark["person"]
		if person.global_position.distance_to(ottavia.global_position) <= BARK_METERS:
			bark["said"] = true
			_bubble.show_over(person, bark["line"])
			GameAudio.play_voice(bark["line"])
			_bark_left = BARK_SECONDS
			return


## One minute before the end, a Voltacampi calls (section 3).
func _on_warning() -> void:
	dialogue.show_line(&"SPEAKER_VOLTACAMPI_MAN", &"C01_VOLTACAMPI_WARNING")
	get_tree().create_timer(3.5).timeout.connect(dialogue.hide_box)


func _on_iole_used() -> void:
	if leaving:
		return
	await _iole_lines()
	_go_to_dungeon()


## The shadow reached the end first: Iole runs to Ottavia.
func _on_expired() -> void:
	if leaving:
		return
	iole.visible = false
	iole.remove_from_group(&"interactables")
	caller.call_player(ottavia)
	await caller.arrived
	await _iole_lines()
	_go_to_dungeon()


func _iole_lines() -> void:
	leaving = true
	ottavia.controls_enabled = false
	hints.hide_goal()
	marker.clear()
	iole_sprite.set_strip(IOLE_TALK, 7.0)
	for line: Array in IOLE_LINES:
		var voice: float = dialogue.show_line(line[0], line[1])
		await get_tree().create_timer(DialogueBox.line_wait(line_seconds, voice)).timeout
	dialogue.hide_box()
	iole_sprite.set_strip(IOLE_TEXTURE, 4.0)


## Into the dungeon: the sundial stops for good there (38).
func _go_to_dungeon() -> void:
	clock.stop()
	left_for_dungeon.emit()
	if not leave_scene:
		ottavia.controls_enabled = true
		return
	var fade: ColorRect = ColorRect.new()
	fade.color = Color(0.0, 0.0, 0.0, 0.0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 45
	layer.add_child(fade)
	add_child(layer)
	var tween: Tween = create_tween()
	tween.tween_property(fade, "color:a", 1.0, 1.0)
	await tween.finished
	get_tree().change_scene_to_file(DUNGEON_SCENE)


# --- Helpers -------------------------------------------------------------------

func _is_free(point: Vector3) -> bool:
	for spot: Vector3 in CLEAR:
		if Vector2(point.x - spot.x, point.z - spot.y).length() < spot.z:
			return false
	for bark: Array in BARKS:
		var at: Vector3 = bark[2]
		if Vector2(point.x - at.x, point.z - at.z).length() < 2.0:
			return false
	return true


func _load(path: String) -> Node3D:
	return (load(path) as PackedScene).instantiate()


func _vehicle(vehicle: Node3D, center: Vector3) -> void:
	level.add_child(vehicle)
	var box: AABB = VehicleKit.bounds(vehicle)
	vehicle.position = center - Vector3(box.get_center().x, box.position.y, box.get_center().z)
	LevelBlocks.make_solid(vehicle, 0.9)


func _pickup(item: StringName, id: StringName, at: Vector3) -> void:
	var pickup: WorldPickup = WorldPickup.new()
	pickup.item_id = item
	pickup.pickup_id = id
	level.add_child(pickup)
	pickup.global_position = at
