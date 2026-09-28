class_name CampTasks
extends Node3D
## The five tasks of the camp (106, docs/livelli/prologo.md, space 3), one
## command each, in this order: sprint to the Frost-cutters' tents after
## the Gnomon's first call; jump the ledges of rock on the way; climb
## the ladder of a field-wagon to wake Ruggero; break the ice holding a Tail;
## fight the swarm of Brinacchi (B1) drawn by its warmth and the lantern.
## Then the Gnomon's second call. There is no real defeat: falling in the
## fight starts again a few steps back (105).

signal finished

enum Task { WAIT, SPRINT, JUMP, CLIMB, WAKE, BREAK, FIGHT, LAST_CALL, DONE }

## Asleep sitting on the landing, head on his chest; woken, he gets up.
const RUGGERO_ASLEEP: Texture2D = preload("res://assets/sprites/comparse/ruggero_dorme_seduto.png")
const RUGGERO_RISING: Texture2D = preload("res://assets/sprites/comparse/ruggero_si_alza.png")
const RUGGERO_RISE_FPS: float = 8.0
const RUGGERO_AWAKE: Texture2D = preload("res://assets/sprites/comparse/ruggero_south.png")
const TRASLOCANTE: Texture2D = preload("res://assets/sprites/comparse/traslocante_south.png")
const GNOMONE: Texture2D = preload("res://assets/sprites/comparse/gnomone_south.png")
const BRINACCHIO: PackedScene = preload("res://scenes/creatures/brinacchio.tscn")
const TAIL: PackedScene = preload("res://assets/models/vehicles/moduli/code.glb")
const TENT: PackedScene = preload("res://assets/models/vehicles/moduli/tenda.glb")
const DRY_BUSH: PackedScene = preload("res://assets/models/vegetation/cespuglio_secco_01.glb")
const TEX_FROST: Texture2D = preload("res://assets/textures/terrain/frost_ground.png")
const ICE_COLOR: Color = Color(0.86, 0.94, 1.0)
const ICE_GLOW: Color = Color(0.55, 0.72, 0.95)
const TEX_ROCK: Texture2D = preload("res://assets/textures/terrain/rock_cliff_01.png")
const TEX_PLANKS: Texture2D = preload("res://assets/textures/terrain/wood_planks_01.png")

## The task area, east of the camion-condominio, toward the frost.
const TENTS: Vector3 = Vector3(56.0, 0.0, -4.0)
const TENTS_RADIUS: float = 5.0
## The skittering of the Brinacchi swarm while it lives (127).
const SWARM_DB: float = -6.0
const ROCK_ROWS: Array[float] = [22.0, 27.0, 32.0]
const ROCK_ROW_Z: Vector2 = Vector2(-13.0, 9.0)
## Low enough to jump (jump height 0.6 m).
const ROCK_HEIGHT: float = 0.45
const FIELD_WAGON: Vector3 = Vector3(50.0, 0.0, 15.0)
## The plank landing on the head of the field-wagon, by its tanks (106):
## Ruggero sleeps there; a ladder goes up on the camera side.
const DECK_HEIGHT: float = 2.2
const LANDING_MIN: Vector2 = Vector2(40.2, 13.4)
const LANDING_MAX: Vector2 = Vector2(42.8, 16.6)
const LADDER_X: float = 41.9
const RUGGERO_SPOT: Vector3 = Vector3(41.0, DECK_HEIGHT, 14.6)
const STUCK_TAIL: Vector3 = Vector3(72.0, 0.0, 4.0)
const TRASLOCANTE_SPOT: Vector3 = Vector3(68.5, 0.0, 7.5)
const SWARM_START: Vector3 = Vector3(69.0, 0.0, 2.0)
const SWARM_SIZE: int = 5
const GNOMONE_SPOT: Vector3 = Vector3(-80.0, 5.2, -2.0)
const SPRINT_REMINDER_SECONDS: float = 30.0
const PARRY_HINT_SECONDS: float = 5.0
const LINE_SECONDS: float = 3.5

var task: Task = Task.WAIT
var breakables: Array[Breakable] = []
## Where to go next (106): glow, edge arrow and the goal above the hint.
var marker: ObjectiveMarker
var _climb_spot: ClimbSpot
var swarm: Array[CombatEnemy] = []

var _ottavia: OttaviaProto
var _dialogue: DialogueBox
var _hints: HintBanner
var _ruggero: NpcSprite
var _stuck_tail: Node3D
var _task_time: float = 0.0
var _parry_hint_shown: bool = false


func setup(ottavia: OttaviaProto, dialogue: DialogueBox, hints: HintBanner) -> void:
	_ottavia = ottavia
	_dialogue = dialogue
	_hints = hints
	_ottavia.defeated.connect(_on_defeated)
	marker = ObjectiveMarker.new()
	add_child(marker)
	_build()


## Starts the tasks: the Gnomon's first call and the sprint. The dev
## argument task=<climb|break|fight> skips ahead for captures.
func begin() -> void:
	for argument: String in OS.get_cmdline_user_args():
		match argument:
			"task=climb":
				_set_task(Task.CLIMB)
				_hints.show_hint(&"PRO_HINT_CLIMB", &"move")
				return
			"task=break":
				_set_task(Task.BREAK)
				return
			"task=fight":
				_start_fight()
				return
	_say(&"SPEAKER_GNOMONE", &"PRO_GNOMONE_01")
	_set_task(Task.SPRINT)
	_hints.show_hint(&"PRO_HINT_SPRINT", &"run")


func _physics_process(delta: float) -> void:
	if _ottavia == null:
		return
	_task_time += delta
	var here: Vector3 = _ottavia.global_position
	match task:
		Task.SPRINT:
			if here.x > ROCK_ROWS[0] - 4.0:
				_set_task(Task.JUMP)
				_hints.show_hint(&"PRO_HINT_JUMP", &"jump")
			elif _task_time > SPRINT_REMINDER_SECONDS:
				# No defeat, only the reminder to hurry.
				_task_time = 0.0
				_hints.show_hint(&"PRO_HINT_SPRINT", &"run")
		Task.JUMP:
			if _flat(here, TENTS) < TENTS_RADIUS:
				_set_task(Task.CLIMB)
				_hints.show_hint(&"PRO_HINT_CLIMB", &"move")
		Task.CLIMB:
			if here.y > DECK_HEIGHT - 0.3 and _flat(here, RUGGERO_SPOT) < 3.0:
				_set_task(Task.WAKE)
				_hints.show_hint(&"INPUT_INTERACT", &"interact")
		Task.BREAK:
			if _flat(here, TRASLOCANTE_SPOT) < 6.0 and _hints.current_hint() != &"PRO_HINT_BREAK":
				_say(&"SPEAKER_TRASLOCANTE", &"PRO_TRASLOCANTE_01")
				_hints.show_hint(&"PRO_HINT_BREAK", &"attack")
		Task.FIGHT:
			if not _parry_hint_shown and _task_time > PARRY_HINT_SECONDS:
				_parry_hint_shown = true
				_hints.show_hint(&"PRO_HINT_PARRY", &"parry")
			if swarm.all(func(enemy: CombatEnemy) -> bool: return not enemy.is_alive()):
				_last_call()


func _set_task(next: Task) -> void:
	task = next
	_task_time = 0.0
	_show_goal()


## Each task says where to go and why, and marks the place (106).
func _show_goal() -> void:
	match task:
		Task.SPRINT:
			_goal(&"PRO_GOAL_ROCKS", Vector3(ROCK_ROWS[0] - 1.5, 0.0, 2.2))
		Task.JUMP:
			_goal(&"PRO_GOAL_TENTS", TENTS)
		Task.CLIMB:
			_goal(&"PRO_GOAL_CLIMB", Vector3(_climb_spot.global_position.x, 0.0, _climb_spot.global_position.z + 0.8))
		Task.WAKE:
			_hints.show_goal(&"PRO_GOAL_WAKE")
			marker.point_to_node(_ruggero)
		Task.BREAK:
			_goal(&"PRO_GOAL_BREAK", STUCK_TAIL)
		Task.FIGHT:
			_hints.show_goal(&"PRO_GOAL_SWARM")
			marker.clear()
		_:
			_hints.hide_goal()
			marker.clear()


func _goal(key: StringName, at: Vector3) -> void:
	_hints.show_goal(key)
	marker.point_to(at)


## A wooden ladder against the landing (33: Ottavia climbs it by walking
## into it).
func _build_ladder(wood: Material) -> void:
	var ladder: Node3D = Node3D.new()
	ladder.position = Vector3(LADDER_X, 0.0, LANDING_MAX.y + 0.18)
	ladder.rotation.x = -0.12
	add_child(ladder)
	for side: float in [-0.28, 0.28]:
		LevelBlocks.box(ladder, Vector3(side, DECK_HEIGHT * 0.55, 0.0), Vector3(0.08, DECK_HEIGHT * 1.1, 0.08), wood, false)
	var rung: float = 0.3
	while rung < DECK_HEIGHT * 1.05:
		LevelBlocks.box(ladder, Vector3(0.0, rung, 0.0), Vector3(0.56, 0.06, 0.07), wood, false)
		rung += 0.34


## Ruggero wakes up when Ottavia talks to him on the landing.
func _on_ruggero_used() -> void:
	if task != Task.WAKE:
		return
	_hints.hide_hint()
	_say(&"SPEAKER_RUGGERO", &"PRO_RUGGERO_01")
	_set_task(Task.BREAK)
	# He lifts his head and gets up, slowly.
	_ruggero.set_strip(RUGGERO_RISING, RUGGERO_RISE_FPS)
	await get_tree().create_timer(RUGGERO_RISING.get_width() / 64.0 / RUGGERO_RISE_FPS).timeout
	_ruggero.set_strip(RUGGERO_AWAKE)


func _on_breakable_broken() -> void:
	if task != Task.BREAK or not breakables.all(func(item: Breakable) -> bool: return not item.is_alive()):
		return
	_hints.hide_hint()
	# The Tail comes free with a metallic groan (127) and lifts off the ice.
	SoundBank.play_sound(get_tree(), &"coda_libera", 0.0)
	var tween: Tween = create_tween()
	tween.tween_property(_stuck_tail, "rotation:z", 0.0, 0.8).set_trans(Tween.TRANS_BACK)
	_start_fight()


## The warmth of the freed Tail and the lantern draw a swarm (B1).
func _start_fight() -> void:
	_set_task(Task.FIGHT)
	_parry_hint_shown = false
	_hints.show_hint(&"PRO_HINT_STRIKE", &"attack")
	_spawn_swarm()
	GameAudio.play_loop(&"swarm", GameAudio.load_sfx(&"sciame_zampettio"), SWARM_DB, 0.8)


func _spawn_swarm() -> void:
	for enemy: CombatEnemy in swarm:
		if is_instance_valid(enemy):
			enemy.queue_free()
	swarm.clear()
	for index: int in SWARM_SIZE:
		var angle: float = TAU * index / SWARM_SIZE
		var creature: CombatEnemy = BRINACCHIO.instantiate()
		creature.hit_sound = &"bastone_creatura"
		creature.defeat_sound = &"brinacchio_sconfitto"
		creature.position = _ottavia.global_position + Vector3(cos(angle), 0.0, sin(angle)) * 4.0
		add_child(creature)
		swarm.append(creature)


func _last_call() -> void:
	GameAudio.stop_loop(&"swarm", 0.6)
	_set_task(Task.LAST_CALL)
	_hints.hide_hint()
	_say(&"SPEAKER_GNOMONE", &"PRO_GNOMONE_02")
	await get_tree().create_timer(LINE_SECONDS).timeout
	_set_task(Task.DONE)
	finished.emit()


## Falling in the fight is not a defeat: a few steps back, the swarm again.
func _on_defeated() -> void:
	if task != Task.FIGHT:
		_ottavia.restore_health()
		return
	_ottavia.controls_enabled = false
	await get_tree().create_timer(0.8).timeout
	_ottavia.global_position = SWARM_START + Vector3(-5.0, 0.0, 2.0)
	_ottavia.velocity = Vector3.ZERO
	_ottavia.restore_health()
	_spawn_swarm()
	_ottavia.controls_enabled = true


func _say(speaker: StringName, line: StringName) -> void:
	# The Gnomon speaks through his brass trumpet (127).
	if speaker == &"SPEAKER_GNOMONE":
		SoundBank.play_sound(get_tree(), &"tromba_gnomone", 0.0)
	_dialogue.show_line(speaker, line)
	await get_tree().create_timer(LINE_SECONDS).timeout
	if _dialogue.current_line() == String(line):
		_dialogue.hide_box()


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _build() -> void:
	# The Gnomon at the sundial of the lead vehicle, far to the west.
	var gnomone: NpcSprite = NpcSprite.new()
	gnomone.sprite_texture = GNOMONE
	gnomone.position = GNOMONE_SPOT
	add_child(gnomone)
	# Uneven ground before the tents (106): low ledges of rock across the
	# way, to jump, and loose stones between them.
	var rock: ShaderMaterial = LevelBlocks.material(TEX_ROCK, TEX_ROCK, Color(0.62, 0.57, 0.54))
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = 1062
	for x: float in ROCK_ROWS:
		var z: float = ROCK_ROW_Z.x
		while z < ROCK_ROW_Z.y:
			var length: float = random.randf_range(1.2, 2.2)
			var height: float = random.randf_range(ROCK_HEIGHT * 0.8, ROCK_HEIGHT)
			var slab: Node3D = LevelBlocks.box(self, Vector3(x + random.randf_range(-0.2, 0.2), height * 0.5, z + length * 0.5), Vector3(random.randf_range(0.7, 1.0), height, length), rock)
			slab.rotation = Vector3(random.randf_range(-0.08, 0.08), random.randf_range(-0.2, 0.2), random.randf_range(-0.08, 0.08))
			z += length * 0.92
		for stone: int in 5:
			var at: Vector3 = Vector3(x + random.randf_range(1.2, 3.4), 0.0, random.randf_range(ROCK_ROW_Z.x, ROCK_ROW_Z.y))
			var size: float = random.randf_range(0.25, 0.45)
			LevelBlocks.box(self, at + Vector3.UP * size * 0.3, Vector3(size, size * 0.6, size * 0.8), rock, false).rotation.y = random.randf_range(-PI, PI)
	# The Frost-cutters' tents, at the far end of the camp.
	for offset: Vector3 in [Vector3(-2.5, 0.0, -1.0), Vector3(3.0, 0.0, 1.5)]:
		var tent: Node3D = TENT.instantiate()
		tent.position = TENTS + offset
		tent.rotation.y = randf_range(-0.3, 0.3)
		add_child(tent)
	_build_field_wagon()
	_build_stuck_tail()


## A field-wagon with a plank landing on its head, by the tanks, reached by
## a ladder on the camera side; old Ruggero asleep on the landing.
func _build_field_wagon() -> void:
	var wagon: Node3D = (load("res://assets/models/vehicles/carro_campo_prova.glb") as PackedScene).instantiate()
	add_child(wagon)
	var box: AABB = VehicleKit.bounds(wagon)
	wagon.position = FIELD_WAGON - Vector3(box.get_center().x, box.position.y, box.get_center().z)
	var planks: ShaderMaterial = LevelBlocks.material(TEX_PLANKS)
	var size: Vector2 = LANDING_MAX - LANDING_MIN
	var centre: Vector2 = (LANDING_MIN + LANDING_MAX) * 0.5
	LevelBlocks.box(self, Vector3(centre.x, DECK_HEIGHT - 0.12, centre.y), Vector3(size.x, 0.24, size.y), planks)
	# Four posts under the landing, and a low rail on the far side.
	for corner: Vector2 in [LANDING_MIN, Vector2(LANDING_MIN.x, LANDING_MAX.y), Vector2(LANDING_MAX.x, LANDING_MIN.y), LANDING_MAX]:
		var inset: Vector2 = corner + (centre - corner).normalized() * 0.2
		LevelBlocks.box(self, Vector3(inset.x, (DECK_HEIGHT - 0.24) * 0.5, inset.y), Vector3(0.16, DECK_HEIGHT - 0.24, 0.16), planks)
	LevelBlocks.box(self, Vector3(centre.x, DECK_HEIGHT + 0.45, LANDING_MIN.y + 0.08), Vector3(size.x, 0.1, 0.1), planks, false)
	_build_ladder(planks)
	_climb_spot = ClimbSpot.create(self, Vector3(LADDER_X, 1.0, LANDING_MAX.y + 0.45), Vector3(1.2, 2.0, 0.9), Vector3(LADDER_X, DECK_HEIGHT, LANDING_MAX.y - 0.7), Vector3.BACK)
	_ruggero = NpcSprite.new()
	_ruggero.sprite_texture = RUGGERO_ASLEEP
	_ruggero.frame_count = 4
	_ruggero.frames_per_second = 1.5
	_ruggero.position = RUGGERO_SPOT
	add_child(_ruggero)
	var talk: Interactable = Interactable.new()
	talk.radius = 1.8
	talk.position = RUGGERO_SPOT
	talk.used.connect(_on_ruggero_used)
	add_child(talk)


## A Tail stuck in the ice among dry bushes and frost crusts, and the
## Homehauler waiting for it.
func _build_stuck_tail() -> void:
	_stuck_tail = TAIL.instantiate()
	_stuck_tail.position = STUCK_TAIL
	_stuck_tail.rotation = Vector3(0.0, PI * 0.5, -0.35)
	add_child(_stuck_tail)
	# Ice, white and pale blue, with a little light of its own so the warm
	# sunset does not turn it purple.
	var frost: StandardMaterial3D = StandardMaterial3D.new()
	frost.albedo_texture = TEX_FROST
	frost.albedo_color = ICE_COLOR
	frost.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	frost.uv1_triplanar = true
	frost.uv1_scale = Vector3.ONE * 0.5
	frost.roughness = 0.35
	frost.emission_enabled = true
	frost.emission = ICE_GLOW
	frost.emission_energy_multiplier = 0.35
	var spots: Array[Vector3] = [Vector3(-1.2, 0.0, 1.4), Vector3(0.9, 0.0, 1.6), Vector3(1.6, 0.0, -0.6), Vector3(-1.4, 0.0, -1.2), Vector3(0.2, 0.0, -1.9)]
	for index: int in spots.size():
		var look: Node3D
		if index % 2 == 0:
			look = Node3D.new()
			LevelBlocks.box(look, Vector3(0.0, 0.25, 0.0), Vector3(0.9, 0.5, 0.7), frost, false).rotation.y = 0.5 * index
			LevelBlocks.box(look, Vector3(0.2, 0.55, 0.1), Vector3(0.5, 0.35, 0.45), frost, false).rotation.y = 1.1 * index
		else:
			look = DRY_BUSH.instantiate()
		var item: Breakable = Breakable.create(self, STUCK_TAIL + spots[index], look, 12.0, Color(0.85, 0.92, 1.0) if index % 2 == 0 else Color(0.8, 0.65, 0.4))
		item.heavy = true
		var crust: bool = index % 2 == 0
		item.hit_sound = &"bastone_ghiaccio" if crust else &"bastone_legno"
		item.defeat_sound = &"crosta_spezza" if crust else &"arbusto_spezza"
		item.broken.connect(_on_breakable_broken)
		breakables.append(item)
	var worker: NpcSprite = NpcSprite.new()
	worker.sprite_texture = TRASLOCANTE
	worker.position = TRASLOCANTE_SPOT
	add_child(worker)
