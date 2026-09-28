extends SceneTree
## Prologue, spaces 1 and 2 (106): the Tessibuio floor and the back door.
## Usage: godot --headless --path . --script res://tests/test_prologue.gd

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	await _test_animations()
	await _test_vehicle_wheels()
	await _test_title()
	await _test_ducking()
	await _test_floor()
	await _test_camp_intro()
	await _test_camp_tasks()
	await _test_column()
	print("TESTS: prologue %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


## The column vehicles (16) roll on their wheels and the Generator beats (77).
func _test_vehicle_wheels() -> void:
	var recipe: Dictionary = VehicleKit.load_recipes()[0]
	var vehicle: Node3D = VehicleKit.build(recipe)
	root.add_child(vehicle)
	var animator: VehicleWheels = VehicleWheels.attach(vehicle)
	await _frames(2)
	_check(animator.wheels.size() >= 4, "vehicle: the kit chassis has its wheels cut out (%d)" % animator.wheels.size())
	var wheel: Node3D = animator.wheels[0]["node"]
	var radius: float = animator.wheels[0]["radius"]
	var start: Basis = wheel.basis
	var engine: Node3D = vehicle.get_node(String(VehicleWheels.ENGINE_NAME))
	var engine_rest: Vector3 = engine.scale
	var biggest_beat: float = 0.0
	for frame: int in 60:
		vehicle.position.x -= 0.03
		await physics_frame
		biggest_beat = maxf(biggest_beat, engine.scale.x / engine_rest.x - 1.0)
	var turned: float = start.get_rotation_quaternion().angle_to(wheel.basis.get_rotation_quaternion())
	_check(absf(turned - 1.8 / radius) < 0.05, "vehicle: moving 1.8 m west turns a wheel of radius %.2f by distance / radius (%.2f rad)" % [radius, turned])
	_check(biggest_beat > 0.005, "vehicle: while moving, the Generator beats")
	var tail: MeshInstance3D = vehicle.get_node(String(VehicleWheels.TAILS_NAME)).find_children("*", "MeshInstance3D", true, false)[0]
	_check(float(tail.get_instance_shader_parameter(&"sway_amount")) > 0.0, "vehicle: while moving, the Tails snake")
	vehicle.free()


func _test_floor() -> void:
	var floor: Node3D = (load(PrologueState.FLOOR_SCENE) as PackedScene).instantiate()
	floor.intro_seconds = 0.0
	floor.leave_scene = false
	root.add_child(floor)
	await _frames(4)
	var ottavia: OttaviaProto = floor.ottavia
	var hints: HintBanner = floor.hints
	var dialogue: DialogueBox = floor.dialogue
	_check(not ottavia.lantern_open, "floor: Ottavia wakes with the lantern closed")
	_check(GameAudio.music_stream() == null and GameAudio.is_loop_playing(&"generator"), "audio: on the dark floor no music, only the muffled Generators (126)")
	var zelinda: NpcSprite = floor.level.get_node("Zelinda")
	var first_frame: int = zelinda.frame
	await create_timer(0.5).timeout
	_check(zelinda.hframes == 8 and zelinda.frame != first_frame, "floor: Zelinda weaves (8-frame idle, one view)")
	_check(hints.current_hint() == &"PRO_HINT_OPEN_LANTERN", "floor: the first hint is to open the lantern")
	ottavia.set_lantern_open(true)
	await _frames(2)
	_check(hints.current_hint() == &"PRO_HINT_MOVE", "floor: once the lantern is open, the hint is to move")
	_check(GameAudio.is_loop_playing(&"lantern_flame"), "audio: the open lantern's flame hums (127)")
	ottavia.global_position += Vector3(2.0, 0.0, 0.0)
	await _frames(2)
	_check(hints.current_hint() == &"", "floor: walking clears the move hint")
	ottavia.global_position = floor.ZELINDA_POSITION + Vector3(-2.0, 0.0, 0.6)
	await _frames(2)
	_check(dialogue.is_showing() and dialogue.current_line() == "PRO_ZELINDA_01", "floor: near Zelinda with the lantern open, she asks to close it")
	_check(hints.current_hint() == &"PRO_HINT_CLOSE_LANTERN", "floor: the hint is to close the lantern")
	ottavia.set_lantern_open(false)
	await _frames(2)
	_check(floor.step == floor.Step.TO_DOOR and hints.current_hint() == &"", "floor: closing the lantern ends the scene with Zelinda")
	ottavia.global_position = floor.DOOR_POSITION + Vector3(-1.2, 0.1, 0.0)
	await _frames(2)
	floor.go_outside()
	await create_timer(0.8).timeout
	_check(PrologueState.entered_from_door and floor.step == floor.Step.OUTSIDE and not ottavia.controls_enabled, "floor: the back door takes Ottavia outside")
	floor.queue_free()
	await _frames(2)


func _test_camp_intro() -> void:
	PrologueState.entered_from_door = true
	var camp: Node3D = (load(PrologueState.CAMP_SCENE) as PackedScene).instantiate()
	camp.line_seconds = 0.05
	root.add_child(camp)
	await _frames(4)
	_check(camp.vehicles.size() >= 20 and camp.vehicles.size() <= 25, "camp: the caravan counts 20-25 vehicles (%d)" % camp.vehicles.size())
	var dyed: Dictionary = {}
	for node: Node in camp.level.find_children("*", "NpcSprite", true, false):
		var person: NpcSprite = node
		if not String(person.trade).is_empty() and float((person.material_override as ShaderMaterial).get_shader_parameter(&"garment_strength")) > 0.0:
			dyed[person.trade] = true
	_check(dyed.size() == CrowdTrades.TRADES.size(), "camp: the crowd wears the colours of all six trades (121, %d)" % dyed.size())
	_check(camp.intro_running and not camp.ottavia.controls_enabled, "camp: coming from the door, the glare and the wide shot play first")
	_check(GameAudio.music_stream() == camp.THEME_MUSIC and GameAudio.is_loop_playing(&"crowd"), "audio: Ottavia's theme under the door and the narration, the crowd murmurs (126)")
	var voiced: bool = true
	for line: StringName in camp.NARRATION:
		voiced = voiced and GameAudio.voice_stream(line) != null
	_check(voiced, "audio: every narration line has its voice, found by line ID (59)")
	await camp.intro_finished
	_check(camp.ottavia.controls_enabled and not PrologueState.entered_from_door, "camp: after the narration the controls come back")
	_check(GameAudio.music_stream() == camp.CAMP_MUSIC, "audio: then the light version of the theme for the camp (126)")
	camp.queue_free()
	await _frames(2)


## Ottavia's v2 sheet (19, 33): every state shows its own row.
func _test_animations() -> void:
	var floor: Node3D = (load(PrologueState.FLOOR_SCENE) as PackedScene).instantiate()
	floor.intro_seconds = 0.0
	floor.leave_scene = false
	root.add_child(floor)
	current_scene = floor
	await _frames(4)
	var ottavia: OttaviaProto = floor.ottavia
	ottavia.set_lantern_open(true)
	await _frames(2)
	_check(_row_of(ottavia) == _row(ottavia, "idle"), "animation: standing still shows the idle row")
	ottavia.combat.press(&"attack")
	await _frames(4)
	_check(_row_of(ottavia) == _row(ottavia, "combo"), "animation: a strike shows the combo row")
	ottavia.combat.release(&"attack")
	await create_timer(0.8).timeout
	ottavia.combat.press(&"jump")
	await _frames(6)
	ottavia.combat.release(&"jump")
	_check(_row_of(ottavia) == _row(ottavia, "jump"), "animation: in the air, the jump row")
	await create_timer(1.0).timeout
	Input.action_press(&"move_right")
	ottavia.combat.press(&"run")
	await _frames(8)
	_check(_row_of(ottavia) == _row(ottavia, "run"), "animation: holding run while moving shows the run row")
	ottavia.combat.release(&"run")
	Input.action_release(&"move_right")
	await _frames(4)
	var attack: CombatAttack = CombatAttack.new()
	attack.damage = 1.0
	attack.deflectable = false
	ottavia.combat.receive_attack(attack)
	await _frames(3)
	_check(_row_of(ottavia) == _row(ottavia, "hurt"), "animation: a hit shows the hurt row")
	await create_timer(0.8).timeout
	ottavia.climb_to(ottavia.global_position + Vector3(1.0, 1.0, 0.0), Vector3.LEFT)
	await _frames(3)
	_check(ottavia.is_climbing() and _row_of(ottavia) == _row(ottavia, "climb"), "animation: climbing shows the climb row")
	while ottavia.is_climbing():
		await physics_frame
	_check(ottavia.global_position.y > 0.9, "climb: Ottavia ends on top of the ledge")
	ottavia.play_scripted("give_hand")
	await _frames(2)
	_check(_row_of(ottavia) == int(ottavia.animation_entry("give_hand", Facing.Direction.EAST)["row"]), "animation: scene actions (give hand) play their row")
	ottavia.stop_scripted()
	floor.queue_free()
	await _frames(2)


func _row_of(ottavia: OttaviaProto) -> int:
	return ottavia.sprite.frame / OttaviaProto.COLUMNS


func _row(ottavia: OttaviaProto, name: String) -> int:
	return int(ottavia.animation_entry(name, ottavia._facing)["row"])


func _test_camp_tasks() -> void:
	PrologueState.reset()
	var camp: Node3D = (load(PrologueState.CAMP_SCENE) as PackedScene).instantiate()
	camp.leave_scene = false
	root.add_child(camp)
	current_scene = camp
	await _frames(4)
	var tasks: CampTasks = camp.tasks
	var ottavia: OttaviaProto = camp.ottavia
	var hints: HintBanner = camp.hints
	_check(tasks.task == CampTasks.Task.SPRINT and hints.current_hint() == &"PRO_HINT_SPRINT", "camp 1: after the first call, the hint is to hold to sprint")
	ottavia.global_position = Vector3(CampTasks.TAIL_ROWS[0] - 3.0, 0.05, 0.0)
	await _frames(2)
	_check(tasks.task == CampTasks.Task.JUMP and hints.current_hint() == &"PRO_HINT_JUMP", "camp 2: at the Tails, the hint is to jump")
	ottavia.global_position = CampTasks.TENTS + Vector3(0.0, 0.05, 3.0)
	await _frames(2)
	_check(tasks.task == CampTasks.Task.CLIMB and hints.current_hint() == &"PRO_HINT_CLIMB", "camp 3: at the tents, the hint is to climb")
	ottavia.global_position = CampTasks.RUGGERO_SPOT + Vector3(1.0, 0.1, 0.0)
	await _frames(3)
	_check(tasks.task == CampTasks.Task.WAKE, "camp 3: on the terrace, Ruggero can be woken")
	ottavia.interact()
	await _frames(2)
	_check(tasks.task == CampTasks.Task.BREAK and camp.dialogue.current_line() == "PRO_RUGGERO_01", "camp 3: Ruggero wakes and speaks")
	ottavia.global_position = CampTasks.TRASLOCANTE_SPOT + Vector3(-2.0, 0.05, 0.0)
	await _frames(3)
	_check(hints.current_hint() == &"PRO_HINT_BREAK" and camp.dialogue.current_line() == "PRO_TRASLOCANTE_01", "camp 4: the Homehauler asks, the hint is to strike to break")
	for item: Breakable in tasks.breakables:
		var hit: CombatHit = CombatHit.new()
		hit.damage = 100.0
		hit.direction = Vector3.RIGHT
		item.receive_hit(hit)
	await _frames(3)
	_check(tasks.task == CampTasks.Task.FIGHT and tasks.swarm.size() == CampTasks.SWARM_SIZE and hints.current_hint() == &"PRO_HINT_STRIKE", "camp 5: the Tail is free, a swarm of Brinacchi comes, the hint is to strike")
	for enemy: CombatEnemy in tasks.swarm:
		enemy.health = 0.0
	await _frames(3)
	_check(tasks.task == CampTasks.Task.LAST_CALL and camp.dialogue.current_line() == "PRO_GNOMONE_02", "camp: after the swarm, the Gnomon's last call")
	camp.queue_free()
	await _frames(2)


func _test_column() -> void:
	PrologueState.reset()
	var column: Node3D = (load(PrologueState.COLUMN_SCENE) as PackedScene).instantiate()
	column.line_seconds = 0.05
	column.chain_seconds = 0.05
	root.add_child(column)
	current_scene = column
	await create_timer(5.6).timeout
	var ottavia: OttaviaProto = column.ottavia
	_check(column.step == column.Step.GO_BACK and column.column.size() >= 3, "column: the caravan marches with three or four vehicles in view (103)")
	_check(GameAudio.music_stream() == column.RETURN_MUSIC, "audio: going back for Mirco, the tense music (126)")
	var start_x: float = column.column[0].position.x
	await create_timer(0.5).timeout
	_check(column.column[0].position.x < start_x, "column: the vehicles move west")
	ottavia.global_position = column.mirco.global_position + Vector3(-1.5, 0.05, 0.0)
	await create_timer(0.4).timeout
	_check(column.step == column.Step.FIGHT and column.brinacchi.size() == 2, "column: Mirco speaks, Ottavia answers, a couple of Brinacchi come")
	for enemy: CombatEnemy in column.brinacchi:
		enemy.health = 0.0
	await _frames(3)
	_check(column.step == column.Step.TIE, "column: then Mirco can be tied to the rope")
	ottavia.interact()
	await create_timer(1.8).timeout
	_check(column.step == column.Step.RETURN and PrologueState.knots == 1 and column.rope.knots == 1, "column: tied to the rope, a knot is added (125)")
	var back: float = column._last_vehicle_back()
	ottavia.global_position.x = back + (column._return_start_x - back) * 0.3
	await _frames(3)
	_check(ottavia.combat.run_drain_multiplier > 1.0, "column: past halfway, the breath runs out faster")
	ottavia.global_position.x = column._last_vehicle_back() + 1.0
	await _frames(3)
	_check(column.step == column.Step.VERDICT, "column: reaching the column past the limit starts the verdict")
	var marching_x: float = column.column[0].position.x
	await create_timer(0.1).timeout
	_check(column.column[0].position.x < marching_x and not ottavia.auto_move.is_zero_approx(), "column: during the verdict the column keeps walking, and Ottavia with it")
	_check(GameAudio.music_stream() == null, "audio: in the verdict the music falls silent, only the voices (126)")
	var speakers: Array[Node3D] = column.chain_speakers()
	var nearer: bool = speakers.size() == 5
	for index: int in range(1, speakers.size()):
		nearer = nearer and absf(speakers[index].global_position.x - ottavia.global_position.x) < absf(speakers[index - 1].global_position.x - ottavia.global_position.x)
	_check(nearer and speakers[0].global_position.x < ottavia.global_position.x - 30.0, "column: the chain starts far toward the head and each voice is nearer Ottavia (106)")
	_check(column.bubble.is_showing() and StringName(column.bubble.current_line()) in column.CHAIN and column.bubble.current_target() in column.walkers, "column: each chain line shows above the one in the crowd who says it (96)")
	var title_music: Array[AudioStream] = []
	column.title.title_leaving.connect(func(_seconds: float) -> void: title_music.append(GameAudio.music_stream()), CONNECT_ONE_SHOT)
	await column.prologue_finished
	_check(column.step == column.Step.DONE, "column: the verdict ends on the chapter title")
	_check(title_music.size() == 1 and title_music[0] == column.TITLE_MUSIC and GameAudio.music_stream() == null, "audio: on the title the first phrase of the theme, broken off as the title fades (126)")
	_check(column._enea.get_parent() == column.level and column._enea.texture == column.ENEA_LOOKING_BACK, "column: in the head shot Enea stops and turns to look back (106)")
	var chain_voiced: bool = column.CHAIN.size() == 5
	for line: StringName in column.CHAIN:
		chain_voiced = chain_voiced and GameAudio.voice_stream(line) != null and not tr(line).is_empty()
	_check(chain_voiced, "column: the verdict chain has five voiced lines (106)")
	column.queue_free()
	await _frames(2)


## Chapter title (125): 1.5 s in, 4 still, 1.5 out; a key skips it.
func _test_title() -> void:
	var title: ChapterTitle = ChapterTitle.new()
	root.add_child(title)
	await _frames(1)
	var started: int = Time.get_ticks_msec()
	var skip: Callable = func() -> void:
		await create_timer(0.3).timeout
		title.skip_title()
	skip.call()
	await title.show_title(&"PRO_TITLE_CH1")
	var seconds: float = (Time.get_ticks_msec() - started) / 1000.0
	_check(seconds > 1.6 and seconds < 2.5 and not title.is_title_visible(), "title: skipped, it fades out at once (%.1f s instead of 7)" % seconds)
	title.queue_free()
	await _frames(1)


## Voices first (126): under a voice the music goes down, then back up.
func _test_ducking() -> void:
	var length: float = GameAudio.play_voice(&"PRO_NARRATION_05")
	await create_timer(0.5).timeout
	var ducked: float = GameAudio.music_duck_db()
	await create_timer(length + 1.2).timeout
	_check(ducked < -8.0 and GameAudio.music_duck_db() > -0.5, "audio: the music goes down under a voice (%.1f dB) and back up after it" % ducked)


func _frames(count: int) -> void:
	for index: int in count:
		await physics_frame


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		print("FAIL: " + message)
