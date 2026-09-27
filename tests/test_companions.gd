extends SceneTree
## Enea (81): follows, cannot die, falls and gets up, learns the moves the
## player does well and then uses them; the lesson of the parry (82); Tosca
## called in a fight (20).
## Usage: godot --headless --path . --script res://tests/test_companions.gd

var _checks: int = 0
var _failures: int = 0
var _ottavia: OttaviaProto
var _enea: Enea
var _tosca: Tosca
var _tuning: CombatTuning


func _initialize() -> void:
	change_scene_to_file("res://scenes/proto/diorama.tscn")
	await _wait(0.3)
	_ottavia = current_scene.get_node("Ottavia")
	_enea = current_scene.get_node("Enea")
	_tosca = current_scene.get_node("Tosca")
	_tuning = _ottavia.combat.tuning
	current_scene.get_node("Creatures").free()
	_ottavia.global_position = Vector3(0.0, 0.05, 10.0)
	_enea.global_position = Vector3(0.0, 0.05, 11.0)
	await _wait(0.3)

	await _test_enea_follows_and_falls()
	await _test_enea_learns()
	await _test_tosca()
	await _test_lesson()

	current_scene.queue_free()
	# Real time: headless frames run unthrottled, a few of them last
	# microseconds and the audio server would not drop the streams yet.
	await create_timer(0.3, true, false, true).timeout
	print("TESTS: companions %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _test_enea_follows_and_falls() -> void:
	_ottavia.global_position = Vector3(-6.0, 0.05, 10.0)
	await _wait(2.5)
	_check(_flat(_enea.global_position - _ottavia.global_position) < 3.0, "enea: follows Ottavia")
	var attack: CombatAttack = CombatAttack.new()
	attack.damage = 50.0
	_check(_enea.receive_attack(attack) == CombatAttack.Result.HIT and _enea.state == Enea.State.DOWN, "enea: hit, he falls")
	_check(not _enea.can_be_attacked(), "enea: on the ground he is not a target")
	await _wait(_tuning.enea_down_seconds + 0.2)
	_check(_enea.state == Enea.State.FOLLOW and is_instance_valid(_enea), "enea: gets up; he cannot die")


func _test_enea_learns() -> void:
	var learned: Array[StringName] = []
	_enea.learned.connect(func(technique: StringName) -> void: learned.append(technique))
	for index: int in _tuning.enea_learn_count - 1:
		_ottavia.combat.technique_done.emit(&"counter")
	_check(not _enea.knows(&"counter"), "enea: not yet after %d counters" % (_tuning.enea_learn_count - 1))
	_ottavia.combat.technique_done.emit(&"counter")
	_check(_enea.knows(&"counter") and &"counter" in learned, "enea: learns the counter after %d" % _tuning.enea_learn_count)
	var dummy: TrainingDummy = current_scene.get_node("TrainingDummy")
	dummy.tuning.dummy_attack_interval = 1000.0
	# A real creature (Enea leaves the practice dummy alone), held open.
	var beast: Voltafaccia = (load("res://scenes/creatures/voltafaccia.tscn") as PackedScene).instantiate()
	beast.position = Vector3(0.0, 0.0, 6.0)
	current_scene.add_child(beast)
	_ottavia.global_position = Vector3(0.0, 0.05, 9.0)
	_enea.global_position = Vector3(0.0, 0.05, 7.1)
	beast.stagger(5.0)
	var health: float = beast.health
	await _wait(0.3)
	_check(beast.health < health, "enea: once learned, he strikes an open creature")
	beast.free()
	# The parry learned from the player's deflections.
	var parry_before: bool = _enea.knows(&"parry")
	_enea.known.erase(&"parry")
	_enea.counts.erase(&"parry")
	for index: int in _tuning.enea_learn_count:
		_ottavia.combat.technique_done.emit(&"parry")
	_check(_enea.knows(&"parry"), "enea: the player's deflections teach him the parry")
	var chance: float = _tuning.enea_parry_chance
	_tuning.enea_parry_chance = 1.0
	var attack: CombatAttack = CombatAttack.new()
	attack.damage = 10.0
	attack.source = dummy
	_check(_enea.receive_attack(attack) == CombatAttack.Result.DEFLECTED and dummy.is_staggered(), "enea: with the parry learned he deflects")
	_tuning.enea_parry_chance = chance
	if not parry_before:
		_enea.known.erase(&"parry")
	_enea.counts.clear()
	_enea.known.clear()


func _test_tosca() -> void:
	_ottavia.global_position = Vector3(0.0, 0.05, 10.0)
	_ottavia.face_toward(Vector3.FORWARD)
	_check(_ottavia.combat.companion == _tosca, "tosca: present in the chapter, she answers the Call")
	var creature: Voltafaccia = (load("res://scenes/creatures/voltafaccia.tscn") as PackedScene).instantiate()
	creature.position = Vector3(0.0, 0.0, 5.0)
	current_scene.add_child(creature)
	await _wait(0.1)
	var before: float = _flat(creature.global_position - _ottavia.global_position)
	_check(_tosca.call_in(), "tosca: hooks a creature in front of Ottavia")
	await _wait(0.4)
	_check(_flat(creature.global_position - _ottavia.global_position) < before - 2.0, "tosca: drags it close")
	_check(not _tosca.call_in() and not _tosca.is_ready(), "tosca: then she needs time before the next call")
	creature.free()


func _test_lesson() -> void:
	var lesson: LessonParry = current_scene.get_node("LessonParry")
	var dialogue: DialogueBox = current_scene.get_node("DialogueBox")
	_enea.global_position = _ottavia.global_position + Vector3(0.5, 0.0, 0.5)
	await _wait(0.1)
	_check(_ottavia.interact(), "lesson: talking to Enea starts it")
	await _wait(0.2)
	_check(lesson.active and not _ottavia.controls_enabled, "lesson: Ottavia steps aside, the player guides Enea")
	_check(dialogue.is_showing() and dialogue.current_line() == "DLG_LESSON_PARRY_001", "lesson: Ottavia explains, line with its ID")
	await _wait(LessonParry.LINE_SECONDS * 3.0 + 0.5)
	_check(_enea.state == Enea.State.CONTROLLED, "lesson: after the explanation Enea is in the player's hands")
	for index: int in LessonParry.SUCCESSES_NEEDED:
		_enea.deflected.emit()
	await _wait(LessonParry.LINE_SECONDS + 0.5)
	_check(lesson.done and _enea.knows(&"parry"), "lesson: two deflections and Enea has learned the parry")
	_check(_ottavia.controls_enabled and not dialogue.is_showing(), "lesson: back to Ottavia")
	for key: String in ["DLG_LESSON_PARRY_001", "DLG_LESSON_PARRY_008"]:
		TranslationServer.set_locale("it")
		var italian: String = TranslationServer.translate(key)
		TranslationServer.set_locale("en")
		var english: String = TranslationServer.translate(key)
		_check(italian != key and english != key and italian != english, "lesson: %s translated in IT and EN" % key)


func _flat(offset: Vector3) -> float:
	return Vector2(offset.x, offset.z).length()


func _wait(seconds: float) -> void:
	await create_timer(seconds, true, true).timeout


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		print("FAIL: " + message)
