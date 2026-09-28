extends SceneTree
## Prologue, spaces 1 and 2 (106): the Tessibuio floor and the back door.
## Usage: godot --headless --path . --script res://tests/test_prologue.gd

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	await _test_animations()
	await _test_floor()
	await _test_camp_intro()
	await _test_camp_tasks()
	await _test_column()
	print("TESTS: prologue %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


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
	var zelinda: NpcSprite = floor.level.get_node("Zelinda")
	var first_frame: int = zelinda.frame
	await create_timer(0.5).timeout
	_check(zelinda.hframes == 8 and zelinda.frame != first_frame, "floor: Zelinda weaves (8-frame idle, one view)")
	_check(hints.current_hint() == &"PRO_HINT_OPEN_LANTERN", "floor: the first hint is to open the lantern")
	ottavia.set_lantern_open(true)
	await _frames(2)
	_check(hints.current_hint() == &"PRO_HINT_MOVE", "floor: once the lantern is open, the hint is to move")
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
	_check(camp.intro_running and not camp.ottavia.controls_enabled, "camp: coming from the door, the glare and the wide shot play first")
	await camp.intro_finished
	_check(camp.ottavia.controls_enabled and not PrologueState.entered_from_door, "camp: after the narration the controls come back")
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
	await column.prologue_finished
	_check(column.step == column.Step.DONE, "column: the verdict ends on the chapter title")
	column.queue_free()
	await _frames(2)


func _frames(count: int) -> void:
	for index: int in count:
		await physics_frame


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		print("FAIL: " + message)
