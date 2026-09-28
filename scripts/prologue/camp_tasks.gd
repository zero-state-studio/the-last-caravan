class_name CampTasks
extends Node3D
## The five tasks of the camp (106, docs/livelli/prologo.md, space 3), one
## command each, in this order: sprint to the Frost-cutters' tents after
## the Gnomon's first call; jump the Tails crawling in the frost; climb onto
## a field-wagon terrace to wake Ruggero; break the frost holding a Tail;
## fight the swarm of Brinacchi (B1) drawn by its warmth and the lantern.
## Then the Gnomon's second call. There is no real defeat: falling in the
## fight starts again a few steps back (105).

signal finished

enum Task { WAIT, SPRINT, JUMP, CLIMB, WAKE, BREAK, FIGHT, LAST_CALL, DONE }

const RUGGERO_ASLEEP: Texture2D = preload("res://assets/sprites/comparse/ruggero_dorme.png")
const RUGGERO_AWAKE: Texture2D = preload("res://assets/sprites/comparse/ruggero_south.png")
const TRASLOCANTE: Texture2D = preload("res://assets/sprites/comparse/traslocante_south.png")
const GNOMONE: Texture2D = preload("res://assets/sprites/comparse/gnomone_south.png")
const BRINACCHIO: PackedScene = preload("res://scenes/creatures/brinacchio.tscn")
const TAIL: PackedScene = preload("res://assets/models/vehicles/moduli/code.glb")
const TENT: PackedScene = preload("res://assets/models/vehicles/moduli/tenda.glb")
const DRY_BUSH: PackedScene = preload("res://assets/models/vegetation/cespuglio_secco_01.glb")
const TEX_FROST: Texture2D = preload("res://assets/textures/terrain/frost_ground.png")
const TEX_PLANKS: Texture2D = preload("res://assets/textures/terrain/wood_planks_01.png")

## The task area, east of the camion-condominio, toward the frost.
const TENTS: Vector3 = Vector3(56.0, 0.0, -4.0)
const TENTS_RADIUS: float = 5.0
## The skittering of the Brinacchi swarm while it lives (127).
const SWARM_DB: float = -6.0
const TAIL_ROWS: Array[float] = [22.0, 27.0, 32.0]
const TAIL_ROW_Z: Vector2 = Vector2(-13.0, 9.0)
const TAIL_HEIGHT: float = 0.42
const FIELD_WAGON: Vector3 = Vector3(50.0, 0.0, 15.0)
const DECK_HEIGHT: float = 2.1
const RUGGERO_SPOT: Vector3 = Vector3(47.5, DECK_HEIGHT, 15.2)
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
			if here.x > TAIL_ROWS[0] - 4.0:
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


## Ruggero wakes up when Ottavia talks to him on the terrace.
func _on_ruggero_used() -> void:
	if task != Task.WAKE:
		return
	_ruggero.set_strip(RUGGERO_AWAKE)
	_hints.hide_hint()
	_say(&"SPEAKER_RUGGERO", &"PRO_RUGGERO_01")
	_set_task(Task.BREAK)


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
	# Tails crawling in the frost behind the vehicles: rows to jump over.
	var tail_block: ShaderMaterial = LevelBlocks.material(TEX_FROST)
	for x: float in TAIL_ROWS:
		var z: float = TAIL_ROW_Z.x
		while z < TAIL_ROW_Z.y:
			var tail: Node3D = TAIL.instantiate()
			tail.position = Vector3(x, 0.0, z + 1.1)
			tail.rotation.y = PI * 0.5
			add_child(tail)
			z += 2.3
		var block: Node3D = LevelBlocks.box(self, Vector3(x, TAIL_HEIGHT * 0.5, (TAIL_ROW_Z.x + TAIL_ROW_Z.y) * 0.5), Vector3(0.7, TAIL_HEIGHT, TAIL_ROW_Z.y - TAIL_ROW_Z.x), tail_block)
		block.visible = false
	# The Frost-cutters' tents, at the far end of the camp.
	for offset: Vector3 in [Vector3(-2.5, 0.0, -1.0), Vector3(3.0, 0.0, 1.5)]:
		var tent: Node3D = TENT.instantiate()
		tent.position = TENTS + offset
		tent.rotation.y = randf_range(-0.3, 0.3)
		add_child(tent)
	_build_field_wagon()
	_build_stuck_tail()


## A field-wagon with a walkable terrace, a wall with handholds on the camera
## side, and old Ruggero asleep on the deck.
func _build_field_wagon() -> void:
	var wagon: Node3D = (load("res://assets/models/vehicles/carro_campo_prova.glb") as PackedScene).instantiate()
	add_child(wagon)
	var box: AABB = VehicleKit.bounds(wagon)
	wagon.position = FIELD_WAGON - Vector3(box.get_center().x, box.position.y, box.get_center().z)
	var deck: Node3D = LevelBlocks.box(self, FIELD_WAGON + Vector3(0.0, DECK_HEIGHT * 0.5, 0.0), Vector3(box.size.x * 0.9, DECK_HEIGHT, box.size.z * 0.7), LevelBlocks.material(TEX_PLANKS))
	deck.visible = false
	var front_z: float = FIELD_WAGON.z + box.size.z * 0.35
	ClimbSpot.create(self, Vector3(RUGGERO_SPOT.x + 1.5, 1.0, front_z + 0.45), Vector3(3.0, 2.0, 0.9), Vector3(RUGGERO_SPOT.x + 1.5, DECK_HEIGHT, front_z - 0.8), Vector3.BACK)
	_ruggero = NpcSprite.new()
	_ruggero.sprite_texture = RUGGERO_ASLEEP
	_ruggero.frame_count = 6
	_ruggero.frames_per_second = 3.0
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
	# Pale icy blue, so the crusts stand out on the frosted ground.
	var frost: ShaderMaterial = LevelBlocks.material(TEX_FROST, TEX_FROST, Color(1.35, 1.45, 1.7))
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
