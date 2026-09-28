extends SceneTree
## Prologue, spaces 1 and 2 (106): the Tessibuio floor and the back door.
## Usage: godot --headless --path . --script res://tests/test_prologue.gd

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	await _test_floor()
	await _test_camp_intro()
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


func _frames(count: int) -> void:
	for index: int in count:
		await physics_frame


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		print("FAIL: " + message)
