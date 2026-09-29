extends SceneTree
## Reverse progression (34), coat patches (104) and difficulty (40).
## Usage: godot --headless --path . --script res://tests/test_progression.gd

var _checks: int = 0
var _failures: int = 0
var _ottavia: OttaviaProto
var _combat: OttaviaCombat


func _initialize() -> void:
	change_scene_to_file("res://scenes/proto/diorama.tscn")
	await _wait(0.3)
	_ottavia = current_scene.get_node("Ottavia")
	_combat = _ottavia.combat
	current_scene.get_node("Creatures").free()
	_ottavia.global_position = Vector3(0.0, 0.05, 11.0)
	await _wait(0.2)

	_test_table()
	await _test_chapters()
	await _test_end_screen()
	await _test_patches()
	await _test_difficulty()

	current_scene.queue_free()
	await create_timer(0.3, true, false, true).timeout
	print("TESTS: progression %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _test_table() -> void:
	_check(Progression.CHAPTERS.size() == 10, "progression: ten chapters")
	var all_lines: bool = true
	for chapter: int in range(2, 10):
		var lines: PackedStringArray = Progression.chapter_lines(chapter)
		all_lines = all_lines and lines[0] != "" and lines[1] != "" and lines[0] != "PROG_LOSE_STAMINA"
	_check(all_lines, "progression: chapters 2-9 each lose one thing and learn one technique, translated")
	_check(Progression.power(9) > Progression.power(1) and int(Progression.entry(9)["combo"]) < int(Progression.entry(1)["combo"]), "progression: stronger strikes, shorter combos")


func _test_chapters() -> void:
	_combat.set_chapter(1)
	var stamina_1: float = _combat.max_stamina()
	var speed_1: float = _combat.move_speed()
	var combo_1: int = _combat.combo_length()
	_combat.set_chapter(9)
	_check(_combat.max_stamina() < stamina_1 and _combat.move_speed() <= speed_1 and _combat.combo_length() < combo_1, "chapter 9: less breath, slower, shorter combo")
	_check(_combat.knows(&"deep_counter") and not Progression.knows(1, &"deep_counter"), "chapter 9 knows techniques chapter 1 does not")

	var dummy: TrainingDummy = current_scene.get_node("TrainingDummy")
	dummy.tuning.dummy_attack_interval = 1000.0
	_ottavia.global_position = dummy.global_position + Vector3(0.0, 0.05, 1.6)
	_ottavia.face_toward(Vector3.FORWARD)
	_combat.set_chapter(2)
	var lines: PackedStringArray = Progression.chapter_lines(2)
	_check(lines[0] == TranslationServer.translate(&"PROG_LOSE_LONG_SPRINT") and lines[1] == TranslationServer.translate(&"PROG_LEARN_TIMED_STEP"), "chapter 1 ends: loses the long sprint, learns the timed step (107)")
	_check(is_equal_approx(Progression.run_share(2), 0.75), "chapter 2: the run lasts 75%")
	# Chapter 1: after a deflection the next strike is a counter-hit (33).
	_combat.set_chapter(1)
	_combat.reset()
	dummy.health = 1000.0
	_combat.press(&"parry")
	await physics_frame
	await physics_frame
	var attack: CombatAttack = CombatAttack.new()
	attack.damage = 5.0
	attack.source = dummy
	_combat.receive_attack(attack)
	_combat.release(&"parry")
	dummy._set_phase(TrainingDummy.Phase.WAIT)
	dummy._stagger_left = 0.0
	await physics_frame
	_combat.press(&"attack")
	await _wait(0.4)
	var expected: float = _combat.tuning.strike_damage * _combat.counter_multiplier()
	_check(absf((1000.0 - dummy.health) - expected) < 0.5, "chapter 1: after a deflection the next strike is a counter-hit (%.1f)" % (1000.0 - dummy.health))
	await _wait(0.6)
	_combat.set_chapter(6)
	_combat.reset()
	dummy.health = dummy.max_health
	_ottavia.global_position = dummy.global_position + Vector3(0.0, 0.05, 2.0)
	_combat.press(&"lantern")
	await _wait(_combat.tuning.lantern_hold_seconds + 0.1)
	_check(dummy.is_staggered(), "chapter 6, dazzling lantern: raising it staggers nearby creatures")
	_combat.release(&"lantern")
	_combat.set_chapter(1)
	_combat.reset()


func _test_end_screen() -> void:
	var diorama: Node = current_scene
	var screen: ChapterScreen = current_scene.get_node("ChapterScreen")
	diorama.settings.chapter = 3.0
	diorama.end_chapter()
	_check(_combat.chapter == 4 and screen.is_open() and paused, "end of chapter: next chapter, the screen shows and the game pauses")
	screen.close()
	_check(not paused and not screen.is_open(), "end of chapter: closing resumes the game")
	diorama.settings.chapter = 1.0
	diorama.apply_settings()


func _test_patches() -> void:
	_combat.reset()
	var night: Raspagelo = (load("res://scenes/creatures/raspagelo.tscn") as PackedScene).instantiate()
	var day: Voltafaccia = (load("res://scenes/creatures/voltafaccia.tscn") as PackedScene).instantiate()
	night.position = Vector3(20.0, 0.0, 20.0)
	day.position = Vector3(22.0, 0.0, 20.0)
	current_scene.add_child(night)
	current_scene.add_child(day)
	_combat.patches = [&"patch_felt"]
	_check(is_equal_approx(_combat.patch_damage_taken(night), 0.75) and is_equal_approx(_combat.patch_damage_taken(day), 1.0), "felt patch: a quarter less damage from Night creatures only")
	_combat.patches = []
	_check(is_equal_approx(_combat.patch_damage_taken(night), 1.0), "no patch: full damage")
	_ottavia.set_physics_process(false)
	_combat.stamina = 10.0
	_combat.physics_update(1.0, Vector2.ZERO, true)
	var start: float = _combat.stamina
	_combat.physics_update(0.1, Vector2.ZERO, true)
	var plain: float = _combat.stamina - start
	_combat.patches = [&"patch_field_canvas"]
	start = _combat.stamina
	_combat.physics_update(0.1, Vector2.ZERO, true)
	_check(_combat.stamina - start > plain * 1.1, "field-canvas patch: breath comes back faster")
	_combat.patches = [&"patch_oiled_leather"]
	_check(is_equal_approx(_combat.patch_multiplier(CoatPatches.EFFECT_BREATHLESS), 0.7), "oiled-leather patch: out of breath 30% less")
	_combat.patches = []
	_ottavia.set_physics_process(true)
	night.free()
	day.free()


func _test_difficulty() -> void:
	var beast: Voltafaccia = (load("res://scenes/creatures/voltafaccia.tscn") as PackedScene).instantiate()
	beast.position = Vector3(20.0, 0.0, 22.0)
	current_scene.add_child(beast)
	await _wait(0.05)
	GameOptions.difficulty = Difficulty.Level.EASY
	beast.reset_enemy()
	var easy_health: float = beast.max_health
	var easy_cone: float = _combat.aim_cone_degrees()
	var easy_window: float = _combat.deflect_window()
	GameOptions.difficulty = Difficulty.Level.HARD
	beast.reset_enemy()
	_check(beast.max_health > easy_health, "difficulty: creatures stronger at hard")
	_check(is_equal_approx(_combat.deflect_window(), easy_window) and is_equal_approx(easy_cone, _combat.tuning.aim_cone_easy_degrees) and _combat.aim_cone_degrees() < easy_cone, "difficulty: easy widens the aim cone (90 degrees), same deflection window")
	_check(is_equal_approx(Difficulty.enemy_damage(), 1.3) and is_equal_approx(Difficulty.enemy_health(), 1.25), "difficulty: hard, 30% more damage and 25% more health (chapter 1)")
	GameOptions.difficulty = Difficulty.Level.EASY
	_check(is_equal_approx(Difficulty.telegraph(), 1.3) and is_equal_approx(Difficulty.enemy_damage(), 1.0), "difficulty: easy, only 30% longer telegraphs")
	GameOptions.difficulty = Difficulty.Level.MEDIUM
	beast.free()


func _wait(seconds: float) -> void:
	await create_timer(seconds, true, true).timeout


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		print("FAIL: " + message)
