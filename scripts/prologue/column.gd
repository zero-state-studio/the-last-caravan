extends Node3D
## Spaces 4 and 5 of the prologue (106, docs/livelli/prologo.md): the tail
## of the caravan on the march (103) and the verdict.
## The column moves west (toward the Day, left) with three or four vehicles
## in view; Mirco has stayed behind looking at the dark to the east. Ottavia
## goes back for him against the column, a long way round fallen walls and
## rocks while the light dims as if night were coming; drives off the
## Brinacchi, ties him to her rope (a knot is added) and runs back through
## more of them: halfway, her breath runs out faster than usual. Past the
## limit she reaches the tail, where Anselmo walks: he tells her the verdict,
## slowly, and takes her measure; the empty lantern appears in the menu (88);
## black, «Ne restano dieci».

enum Step { INTRO, GO_BACK, MEET, FIGHT, TIE, RETURN, VERDICT, DONE }

const COLUMN_SPEED: float = 1.2
const COLUMN_Z: float = -3.0
const COLUMN_START_X: Array[float] = [-7.0, -31.0, -55.0, -79.0]
const COLUMN_RECIPES: Array[String] = ["casa_due_piani", "tenda_e_carico", "orto_e_serbatoio", "casa_torre"]
const HEAD_X: float = -330.0
const MIRCO_START: Vector3 = Vector3(125.0, 0.0, 6.0)
const OTTAVIA_START: Vector3 = Vector3(0.0, 0.0, 2.5)
const MEET_RADIUS: float = 3.0
const FOLLOW_DISTANCE: float = 1.3
## Past this share of the way back, the breath drains faster (106).
const HALFWAY_SHARE: float = 0.5
const TIRED_DRAIN: float = 2.2
const CATCH_DISTANCE: float = 4.0
const LINE_SECONDS: float = 3.2
## Silence after each line of the verdict: two old friends, slowly (106).
const VERDICT_PAUSE: float = 1.2
const CROWD_TYPES: Array[String] = ["uomo_giovane", "uomo_adulto", "uomo_anziano", "donna_giovane", "donna_adulta", "donna_anziana", "bambino", "bambina"]
const ROADS: Array[Dictionary] = [{"points": [Vector2(-450.0, 0.0), Vector2(200.0, -1.0)], "half_width": 4.0}]
const BRINACCHIO: PackedScene = preload("res://scenes/creatures/brinacchio.tscn")
const ANSELMO_WALK: String = "res://assets/sprites/comparse/anselmo_walk_west.png"
## Anselmo walks at the tail, behind the last vehicle, seen from afar.
const ANSELMO_BEHIND: Vector3 = Vector3(2.5, 0.0, 3.2)
const ANSELMO_FACING_NORTH: Texture2D = preload("res://assets/sprites/comparse/anselmo_north.png")
## Sound (126, 127): tension and a faster beat on the way back; the music
## falls silent for the verdict, only the voices remain, each one closer;
## the first phrase of the theme on the title.
const RETURN_MUSIC: AudioStream = preload("res://assets/audio/music/m3_ritorno_mirco.ogg")
const TITLE_MUSIC: AudioStream = preload("res://assets/audio/music/m4_titolo.ogg")
const RETURN_MUSIC_DB: float = -3.0
const GENERATOR_DB: float = -14.0
const GENERATOR_PITCH: float = 1.25
const CROWD_DB: float = -18.0
## The verdict (106): who says each line, in order. Anselmo carries the
## Mayor's words; he and Ottavia both know what is coming.
const VERDICT: Array[Array] = [
	[&"SPEAKER_ANSELMO", &"PRO_ANSELMO_LATE"],
	[&"SPEAKER_OTTAVIA", &"PRO_OTTAVIA_LATE"],
	[&"SPEAKER_ANSELMO", &"PRO_VERDICT_01"],
	[&"SPEAKER_ANSELMO", &"PRO_VERDICT_02"],
	[&"SPEAKER_ANSELMO", &"PRO_VERDICT_03"],
	[&"SPEAKER_ANSELMO", &"PRO_VERDICT_04"],
	[&"SPEAKER_ANSELMO", &"PRO_VERDICT_05"],
]
## The way to Mirco (106): barriers of fallen rock and walls across the
## way, each with a gap on one side, to be walked round. (x, z_from, z_to).
const BARRIERS: Array[Vector3] = [
	Vector3(28.0, -2.0, 9.0), Vector3(46.0, 5.0, 16.0), Vector3(64.0, -2.0, 4.0),
	Vector3(64.0, 10.0, 16.0), Vector3(82.0, -2.0, 10.0), Vector3(100.0, 4.0, 16.0),
]
## Waypoints through the gaps, from Ottavia's start to Mirco (the autoplay
## walks them; a player finds them by eye).
const ROUTE: Array[Vector3] = [
	Vector3(24.0, 0.0, 12.5), Vector3(32.0, 0.0, 12.5), Vector3(42.0, 0.0, 1.5), Vector3(50.0, 0.0, 1.5),
	Vector3(60.0, 0.0, 7.0), Vector3(68.0, 0.0, 7.0), Vector3(78.0, 0.0, 13.0), Vector3(86.0, 0.0, 13.0),
	Vector3(96.0, 0.0, 1.0), Vector3(104.0, 0.0, 1.0),
]
## Brinacchi on the way (B1): where each group waits; the first on the way
## out, the others cut across the way back.
const WAY_OUT_SWARM: Vector3 = Vector3(72.0, 0.0, 7.0)
const WAY_BACK_SWARMS: Array[Vector3] = [Vector3(90.0, 0.0, 12.0), Vector3(40.0, 0.0, 2.0)]
const SWARM_COUNT: int = 3
## The frost field around Mirco (x, z, width, depth), dressed with frozen
## things; the barriers' gaps and Mirco's spot stay clear.
const FROST_FIELD: Rect2 = Rect2(20.0, -14.0, 140.0, 40.0)

## Nightfall toward Mirco (106): how much the light dims at his place.
const DUSK_START_X: float = 20.0
const DUSK_SUN_SCALE: float = 0.62
const DUSK_AMBIENT_SCALE: float = 0.72
const DUSK_FOG_COLOR: Color = Color(0.32, 0.33, 0.45)
## East of this the ground is frosted: steps crunch.
const FROST_X: float = 25.0
const SUN_ELEVATION_DEGREES: float = 14.0
const SUN_AZIMUTH_DEGREES: float = 300.0

## Seconds each verdict line stays; tests shorten it.
@export var line_seconds: float = LINE_SECONDS

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
## Where to go next (106).
var marker: ObjectiveMarker
@onready var level: Node3D = $Level

var _random: RandomNumberGenerator = RandomNumberGenerator.new()
var _mirco_idle: Dictionary = {}
var _mirco_walk: Dictionary = {}
var _return_start_x: float = 0.0
var _anselmo: NpcSprite
var _head: Node3D
var _anselmo_walking: bool = true
## Dusk (0 day, 1 at Mirco's place) and the light it scales.
var dusk: float = 0.0
var _sun: DirectionalLight3D
var _environment: Environment
var _sun_energy: float = 1.0
var _ambient_energy: float = 1.0
var _fog_color: Color = Color.WHITE
## Brinacchi groups not yet woken.
var _waiting_swarms: Array[Vector3] = []


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
	_sun = sun
	_sun_energy = sun.light_energy
	_environment = ($WorldEnvironment as WorldEnvironment).environment
	_ambient_energy = _environment.ambient_light_energy
	_fog_color = _environment.fog_light_color
	_build_barriers()
	# Where Mirco stays behind, and on the way there: the frost field.
	CampScenery.dress_frost_field(level, FROST_FIELD, _frost_free)
	_waiting_swarms = [WAY_OUT_SWARM]
	ottavia.set_shaded(true)
	ottavia.set_sun_azimuth(SUN_AZIMUTH_DEGREES)
	ottavia.global_position = OTTAVIA_START
	ottavia.face_toward(Vector3.RIGHT)
	ottavia.set_lantern_open(PrologueState.lantern_open)
	ottavia.defeated.connect(_on_defeated)
	ottavia.footstep_sound = &"passo_erba"
	GameAudio.play_music(RETURN_MUSIC, 2.0, RETURN_MUSIC_DB)
	GameAudio.play_loop(&"generator", GameAudio.load_sfx(&"generatore_fuori"), GENERATOR_DB, 1.5, GENERATOR_PITCH)
	GameAudio.play_loop(&"crowd", GameAudio.load_sfx(&"brusio_folla"), CROWD_DB, 2.0)
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("start_x="):
			ottavia.global_position.x = argument.trim_prefix("start_x=").to_float()
	camera_rig.target = ottavia
	camera_rig.limits = Rect2(Vector2(-460.0, -30.0), Vector2(620.0, 60.0))
	camera_rig.snap_to_target()
	var hud: CombatHud = CombatHud.new()
	add_child(hud)
	# Pause and options (96), with the farewell lantern once revealed (88).
	var menu: OptionsMenu = OptionsMenu.new()
	menu.name = "OptionsMenu"
	add_child(menu)
	PrologueAutoplay.attach_if_requested(get_tree())
	marker = ObjectiveMarker.new()
	level.add_child(marker)
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
	hints.show_goal(&"PRO_GOAL_MIRCO")
	marker.point_to_node(mirco)


func _physics_process(delta: float) -> void:
	if column_moving:
		for node: Node3D in column:
			node.position.x -= COLUMN_SPEED * delta
		for walker: NpcSprite in walkers:
			walker.position.x -= COLUMN_SPEED * delta
		_head.position.x -= COLUMN_SPEED * delta
		if _anselmo_walking:
			_anselmo.global_position.x -= COLUMN_SPEED * delta
	var here: Vector3 = ottavia.global_position
	_update_dusk(here.x, delta)
	_wake_swarms(here)
	ottavia.footstep_sound = &"passo_brina" if here.x > FROST_X else &"passo_erba"
	match step:
		Step.GO_BACK:
			if _flat(here, mirco.global_position) < MEET_RADIUS:
				_meet()
		Step.FIGHT:
			if brinacchi.all(func(enemy: CombatEnemy) -> bool: return not enemy.is_alive()):
				step = Step.TIE
				hints.show_hint(&"INPUT_INTERACT", &"interact")
				hints.show_goal(&"PRO_GOAL_TIE")
				marker.point_to_node(mirco)
		Step.VERDICT:
			_follow(delta)
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
	hints.show_goal(&"PRO_GOAL_SWARM")
	marker.clear()
	for index: int in 2:
		var creature: CombatEnemy = BRINACCHIO.instantiate()
		creature.hit_sound = &"bastone_creatura"
		creature.defeat_sound = &"brinacchio_sconfitto"
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
	SoundBank.play_sound(get_tree(), &"corda_nodo", 0.0)
	rope.add_knot()
	ottavia.controls_enabled = true
	_return_start_x = ottavia.global_position.x
	_waiting_swarms = WAY_BACK_SWARMS.duplicate()
	# Back to the tail of the column, which keeps walking away.
	var last: Node3D = column[0]
	var box: AABB = VehicleKit.bounds(last)
	hints.show_goal(&"PRO_GOAL_COLUMN")
	marker.point_to_node(last, Vector3(box.end.x + 1.0, 0.0, box.get_center().z))


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


## Space 5: the verdict. Anselmo walks at the tail; he tells Ottavia the
## Mayor's words, slowly, and asks for her hand. The column never stops.
func _verdict() -> void:
	step = Step.VERDICT
	ottavia.controls_enabled = false
	hints.hide_goal()
	marker.clear()
	ottavia.combat.run_drain_multiplier = 1.0
	ottavia.auto_move = Vector3(-COLUMN_SPEED, 0.0, 0.0)
	hints.hide_hint()
	# Anselmo falls in beside her; both walk on with the column.
	_anselmo.global_position = Vector3(ottavia.global_position.x - 0.6, 0.0, ottavia.global_position.z + 1.3)
	GameAudio.stop_music(1.5)
	for line: Array in VERDICT:
		var voice: float = dialogue.show_line(line[0], line[1])
		await get_tree().create_timer(DialogueBox.line_wait(line_seconds, voice, VERDICT_PAUSE)).timeout
	dialogue.hide_box()
	await get_tree().create_timer(0.8 if line_seconds >= 1.0 else line_seconds).timeout
	# For the hand they stop, face to face; the column walks on.
	ottavia.auto_move = Vector3.ZERO
	_anselmo_walking = false
	_anselmo.set_strip(ANSELMO_FACING_NORTH)
	_anselmo.global_position = ottavia.global_position + Vector3(0.0, 0.0, 1.3)
	ottavia.face_toward(Vector3.BACK)
	var hand_voice: float = dialogue.show_line(&"SPEAKER_ANSELMO", &"PRO_ANSELMO_02")
	var hand_started: float = Time.get_ticks_msec() / 1000.0
	await ottavia.play_scripted("give_hand")
	var hand_left: float = hand_voice - (Time.get_ticks_msec() / 1000.0 - hand_started)
	await get_tree().create_timer(maxf(line_seconds * 0.6, hand_left + 0.4) if line_seconds >= 1.0 else line_seconds * 0.6).timeout
	dialogue.hide_box()
	await title.show_lantern_silhouette(line_seconds)
	GameAudio.stop_loop(&"generator", 1.2)
	GameAudio.stop_loop(&"crowd", 1.2)
	await title.fade_to_black(1.2)
	# The first phrase of the theme; it breaks off as the title fades (126).
	GameAudio.play_music(TITLE_MUSIC, 0.0)
	title.title_leaving.connect(func(seconds: float) -> void: GameAudio.stop_music(seconds), CONNECT_ONE_SHOT)
	if line_seconds < 1.0:
		await title.show_title(&"PRO_TITLE_CH1", line_seconds, line_seconds, line_seconds)
	else:
		await title.show_title(&"PRO_TITLE_CH1")
	step = Step.DONE
	prologue_finished.emit()


## The light dims toward Mirco, as if night were coming (106), and comes
## back on the way to the column.
func _update_dusk(x: float, delta: float) -> void:
	var target: float = clampf((x - DUSK_START_X) / (MIRCO_START.x - DUSK_START_X), 0.0, 1.0)
	dusk = move_toward(dusk, target, delta * 0.5)
	_sun.light_energy = _sun_energy * lerpf(1.0, DUSK_SUN_SCALE, dusk)
	_environment.ambient_light_energy = _ambient_energy * lerpf(1.0, DUSK_AMBIENT_SCALE, dusk)
	_environment.fog_light_color = _fog_color.lerp(DUSK_FOG_COLOR, dusk * 0.8)


## Brinacchi groups wake up as Ottavia comes near their place.
func _wake_swarms(here: Vector3) -> void:
	for index: int in range(_waiting_swarms.size() - 1, -1, -1):
		var at: Vector3 = _waiting_swarms[index]
		if Vector2(at.x - here.x, at.z - here.z).length() < 16.0:
			_waiting_swarms.remove_at(index)
			for creature_index: int in SWARM_COUNT:
				var angle: float = TAU * creature_index / SWARM_COUNT
				_spawn_brinacchio(at + Vector3(cos(angle), 0.0, sin(angle)) * 2.0)


func _spawn_brinacchio(at: Vector3) -> CombatEnemy:
	var creature: CombatEnemy = BRINACCHIO.instantiate()
	creature.hit_sound = &"bastone_creatura"
	creature.defeat_sound = &"brinacchio_sconfitto"
	creature.position = at
	level.add_child(creature)
	brinacchi.append(creature)
	return creature


func _frost_free(point: Vector3) -> bool:
	if absf(point.z - COLUMN_Z) < 5.0 and point.x < 60.0:
		return false
	if Vector2(point.x - MIRCO_START.x, point.z - MIRCO_START.z).length() < 6.0:
		return false
	for waypoint: Vector3 in ROUTE:
		if Vector2(point.x - waypoint.x, point.z - waypoint.z).length() < 3.0:
			return false
	for barrier: Vector3 in BARRIERS:
		if absf(point.x - barrier.x) < 2.5 and point.z > barrier.y - 1.0 and point.z < barrier.z + 1.0:
			return false
	return true


## Fallen rock and broken walls across the way to Mirco, to walk round
## (106): rows of rock blocks of uneven height, a ruined wall in two rows.
func _build_barriers() -> void:
	var rock: ShaderMaterial = LevelBlocks.material(CampScenery.TEX_ROCK, CampScenery.TEX_ROCK, Color(0.5, 0.46, 0.44))
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = 1060
	for barrier: Vector3 in BARRIERS:
		var z: float = barrier.y
		while z < barrier.z:
			# Boulders, not crates: uneven, tilted, half sunk in the ground.
			var width: float = random.randf_range(1.4, 2.4)
			var height: float = random.randf_range(1.1, 2.0)
			var block: Node3D = LevelBlocks.box(level, Vector3(barrier.x + random.randf_range(-0.6, 0.6), height * 0.38, z + width * 0.5), Vector3(random.randf_range(1.4, 2.4), height, width), rock)
			block.rotation = Vector3(random.randf_range(-0.3, 0.3), random.randf_range(-PI, PI), random.randf_range(-0.3, 0.3))
			z += width * 0.8
	for at: Vector3 in [Vector3(46.0, 0.0, 10.5), Vector3(82.0, 0.0, 4.0)]:
		var wall: Node3D = (load("res://assets/models/ruins/muro_arco.glb") as PackedScene).instantiate()
		wall.position = at
		wall.rotation.y = PI * 0.5
		level.add_child(wall)


func _say(speaker: StringName, line: StringName) -> void:
	var voice: float = dialogue.show_line(speaker, line)
	await get_tree().create_timer(DialogueBox.line_wait(line_seconds, voice)).timeout
	if dialogue.current_line() == String(line):
		dialogue.hide_box()


func _on_defeated() -> void:
	ottavia.controls_enabled = false
	await get_tree().create_timer(0.8).timeout
	# A few steps back along her way: toward the start going out, toward
	# Mirco's place coming back.
	var back: float = -5.0 if step != Step.RETURN else 5.0
	ottavia.global_position = ottavia.global_position + Vector3(back, 0.0, 0.0)
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
	var trades: Array[StringName] = CrowdTrades.names()
	var trade_random: RandomNumberGenerator = RandomNumberGenerator.new()
	trade_random.seed = 121
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
		walker.trade = trades[trade_random.randi() % trades.size()]
		var side: float = -1.0 if _random.randf() < 0.5 else 1.0
		walker.position = Vector3(_random.randf_range(-95.0, -4.0), 0.0, COLUMN_Z + side * _random.randf_range(3.6, 6.0))
		level.add_child(walker)
		walkers.append(walker)


## The head of the column, far to the west: the lead vehicle with the Gnomon
## on the sundial (Arold is not seen in the prologue).
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
	# Anselmo at the tail of the column, walking with it from the start, so
	# Ottavia sees him long before she reaches him.
	_anselmo = NpcSprite.new()
	if ResourceLoader.exists(ANSELMO_WALK):
		_anselmo.sprite_texture = load(ANSELMO_WALK)
		_anselmo.frame_count = 8
		_anselmo.frames_per_second = 7.0
	else:
		_anselmo.sprite_texture = load("res://assets/sprites/comparse/anselmo_east.png")
	var tail: AABB = VehicleKit.bounds(column[0])
	_anselmo.position = Vector3(column[0].position.x + tail.end.x, 0.0, COLUMN_Z) + ANSELMO_BEHIND
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
