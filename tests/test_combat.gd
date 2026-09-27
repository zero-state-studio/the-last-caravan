extends SceneTree
## Ottavia's combat (33): strike and combo, counter-hit, deflect, block,
## hit taken, breath costs and regeneration, breathless, hook pull and push,
## lantern shutter and raise, call without a companion.
## Usage: godot --headless --path . --script res://tests/test_combat.gd

var _checks: int = 0
var _failures: int = 0
var _messages: Array[StringName] = []
var _ottavia: OttaviaProto
var _combat: OttaviaCombat
var _dummy: TrainingDummy
var _tuning: CombatTuning


func _initialize() -> void:
	change_scene_to_file("res://scenes/proto/diorama.tscn")
	await _wait(0.3)
	_ottavia = current_scene.get_node("Ottavia")
	# Ottavia against the dummy only; the creatures have their own test.
	current_scene.get_node("Creatures").free()
	_combat = _ottavia.combat
	_tuning = _combat.tuning
	_dummy = current_scene.get_node("TrainingDummy")
	_tuning.dummy_attack_interval = 1000.0
	_combat.message.connect(func(key: StringName) -> void: _messages.append(key))
	_place_in_front()

	await _test_strikes()
	await _test_defence()
	await _test_breath()
	await _test_hook()
	await _test_lantern_and_call()
	await _test_rules_from_review()

	# Free the level (its creatures keep fighting and playing sounds) and let
	# the audio server drop them: a stream playing at exit counts as a leak.
	current_scene.queue_free()
	for index: int in 10:
		await process_frame
	print("TESTS: combat %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _test_strikes() -> void:
	_dummy.health = 1000.0
	_combat.press(&"attack")
	await _wait(0.7)
	_check(is_equal_approx(_dummy.health, 1000.0 - _tuning.strike_damage), "strike: one hit of strike_damage (got %.1f)" % (1000.0 - _dummy.health))

	_dummy.health = 1000.0
	_combat.press(&"attack")
	await _wait(0.2)
	_combat.press(&"attack")
	await _wait(0.25)
	_combat.press(&"attack")
	await _wait(1.0)
	var expected: float = _tuning.strike_damage * (2.0 + _tuning.combo_finisher_multiplier)
	_check(is_equal_approx(1000.0 - _dummy.health, expected), "combo: three hits, the last one stronger (expected %.1f, got %.1f)" % [expected, 1000.0 - _dummy.health])

	_dummy.health = 1000.0
	_messages.clear()
	_dummy._set_phase(TrainingDummy.Phase.EXPOSED)
	_combat.press(&"attack")
	await _wait(0.4)
	_check(is_equal_approx(1000.0 - _dummy.health, _tuning.strike_damage * _tuning.counter_multiplier), "counter-hit on an open dummy (got %.1f)" % (1000.0 - _dummy.health))
	_check(&"COMBAT_COUNTER" in _messages, "counter-hit shows its signal")
	await _wait(0.8)


func _test_defence() -> void:
	_combat.reset()
	_messages.clear()
	_combat.press(&"parry")
	await physics_frame
	await physics_frame
	_check(_combat.state == OttaviaCombat.State.PARRY, "parry: pressing enters the guard")
	_check(_combat.receive_attack(_attack()) == CombatAttack.Result.DEFLECTED, "parry: a hit right after the press is deflected")
	_check(_dummy.is_staggered(), "deflect: the attacker is staggered")
	_check(&"COMBAT_DEFLECT" in _messages, "deflect shows its signal")

	await _wait(_tuning.deflect_window + 0.2)
	var breath_before: float = _combat.stamina
	var health_before: float = _ottavia.health
	_check(_combat.receive_attack(_attack()) == CombatAttack.Result.BLOCKED, "parry held: later hits are blocked")
	_check(is_equal_approx(_combat.stamina, maxf(0.0, breath_before - _tuning.block_hit_cost)), "block costs block_hit_cost breath")
	_check(is_equal_approx(_ottavia.health, health_before), "block: no damage")

	_combat.release(&"parry")
	await physics_frame
	health_before = _ottavia.health
	_check(_combat.receive_attack(_attack()) == CombatAttack.Result.HIT, "no guard: the attack hits")
	_check(is_equal_approx(_ottavia.health, health_before - _tuning.dummy_damage), "hit: damage taken")
	_check(_combat.state == OttaviaCombat.State.HITSTUN, "hit: short stun")
	await _wait(_tuning.hitstun_seconds + 0.2)
	_ottavia.restore_health()


func _test_breath() -> void:
	_combat.reset()
	_combat.press(&"step", Vector2.RIGHT)
	await physics_frame
	await physics_frame
	_check(_combat.state == OttaviaCombat.State.STEP, "step: the sidestep starts")
	_check(is_equal_approx(_combat.stamina, _tuning.max_stamina - _tuning.step_stamina_cost), "step costs step_stamina_cost breath")
	var after_step: float = _combat.stamina
	await _wait(_tuning.step_seconds + _tuning.stamina_regen_delay + 0.4)
	_check(_combat.stamina > after_step, "breath comes back when Ottavia does not act")

	_messages.clear()
	_combat.stamina = 5.0
	_combat.press(&"step", Vector2.RIGHT)
	await physics_frame
	await physics_frame
	_check(_combat.state == OttaviaCombat.State.BREATHLESS, "empty breath: breathless")
	_check(&"COMBAT_BREATHLESS" in _messages, "breathless shows its signal")
	await _wait(_tuning.step_invulnerable_seconds + 0.05)
	var health_before: float = _ottavia.health
	_combat.receive_attack(_attack())
	_check(is_equal_approx(health_before - _ottavia.health, _tuning.dummy_damage * _tuning.breathless_damage_multiplier), "breathless: more damage taken")
	await _wait(_tuning.breathless_seconds + 0.2)
	_check(_combat.state == OttaviaCombat.State.FREE, "breathless lasts only an instant")
	_ottavia.restore_health()


func _test_hook() -> void:
	_combat.reset()
	_dummy.global_position = Vector3(20.0, 0.0, 20.0)
	var small: CombatEnemy = CombatEnemy.new()
	var sprite: Sprite3D = Sprite3D.new()
	sprite.name = "Sprite3D"
	sprite.texture = load("res://assets/sprites/combat/training_dummy.png")
	small.add_child(sprite)
	small.is_small = true
	current_scene.add_child(small)
	var origin: Vector3 = _ottavia.global_position
	small.global_position = origin + Vector3(0.0, 0.0, -2.8)
	_ottavia.face_toward(Vector3.FORWARD)
	_combat.press(&"hook")
	_combat.release(&"hook")
	await _wait(0.6)
	var pulled: float = _flat(small.global_position - _ottavia.global_position)
	_check(absf(pulled - _tuning.hook_pull_distance) < 0.35, "hook tap pulls a small creature close (distance %.2f)" % pulled)

	_ottavia.face_toward(Vector3.FORWARD)
	var before: float = _flat(small.global_position - _ottavia.global_position)
	_combat.press(&"hook")
	await _wait(_tuning.hook_hold_seconds + 0.1)
	_combat.release(&"hook")
	await _wait(0.6)
	var pushed: float = _flat(small.global_position - _ottavia.global_position)
	_check(pushed > before + _tuning.hook_push_distance * 0.7, "hook hold pushes away (from %.2f to %.2f)" % [before, pushed])
	small.queue_free()


func _test_lantern_and_call() -> void:
	_combat.reset()
	var open_before: bool = _ottavia.lantern_open
	_combat.press(&"lantern")
	_combat.release(&"lantern")
	_check(_ottavia.lantern_open != open_before, "lantern tap toggles the shutter")
	_combat.press(&"lantern")
	_combat.release(&"lantern")
	_check(_ottavia.lantern_open == open_before, "lantern tap toggles it back")
	var base_range: float = _ottavia.lantern_light.omni_range
	_combat.press(&"lantern")
	await _wait(_tuning.lantern_hold_seconds + 0.1)
	_check(_ottavia.lantern_light.omni_range > base_range * 1.2, "lantern held: raised, lights farther")
	_combat.release(&"lantern")
	_check(is_equal_approx(_ottavia.lantern_light.omni_range, base_range), "lantern released: back to normal")
	_messages.clear()
	_combat.press(&"call")
	_check(&"COMBAT_NO_COMPANION" in _messages, "call without a companion in the chapter says so")


## Corrections after the first review: free deflection, hook only in front,
## half regeneration while walking, aim assist that can be turned off.
func _test_rules_from_review() -> void:
	_combat.reset()
	_dummy.global_position = _ottavia.global_position + Vector3(0.0, 0.0, -1.6)
	var press_cost: float = _tuning.parry_press_cost
	_tuning.parry_press_cost = 10.0
	var before: float = _combat.stamina
	_combat.press(&"parry")
	await physics_frame
	await physics_frame
	_combat.receive_attack(_attack())
	_check(is_equal_approx(_combat.stamina, before), "a deflection costs no breath, even with a press cost")
	_combat.release(&"parry")
	_tuning.parry_press_cost = press_cost
	await _wait(0.3)

	var behind: CombatEnemy = CombatEnemy.new()
	var sprite: Sprite3D = Sprite3D.new()
	sprite.name = "Sprite3D"
	behind.add_child(sprite)
	behind.is_small = true
	current_scene.add_child(behind)
	_dummy.global_position = Vector3(20.0, 0.0, 20.0)
	behind.global_position = _ottavia.global_position + Vector3(0.0, 0.0, 1.5)
	_ottavia.face_toward(Vector3.FORWARD)
	_check(_combat.hook_target() == null, "the hook never catches a creature behind Ottavia")
	_ottavia.face_toward(Vector3.BACK)
	_check(_combat.hook_target() == behind, "turned toward it, the hook catches it")
	behind.queue_free()

	_ottavia.set_physics_process(false)
	_combat.reset()
	_combat.stamina = 10.0
	_combat.physics_update(1.0, Vector2.ZERO, true)
	var standing: float = _combat.stamina
	_combat.physics_update(0.25, Vector2.ZERO, true)
	var standing_gain: float = _combat.stamina - standing
	var walking: float = _combat.stamina
	_combat.physics_update(0.25, Vector2.RIGHT, true)
	var walking_gain: float = _combat.stamina - walking
	_check(is_equal_approx(walking_gain, standing_gain * _tuning.walking_regen_multiplier), "walking regains breath at walking_regen_multiplier (%.2f vs %.2f)" % [walking_gain, standing_gain])
	_ottavia.set_physics_process(true)

	# About 22 degrees off the facing: inside the 35 degree assist cone.
	_dummy.global_position = _ottavia.global_position + Vector3(0.8, 0.0, -2.0)
	_ottavia.face_toward(Vector3.FORWARD)
	GameOptions.aim_assist = false
	_check(_combat._aim_direction(3.0).is_equal_approx(Vector3.FORWARD), "aim assist off: strikes follow the facing only")
	GameOptions.aim_assist = true
	_ottavia.face_toward(Vector3.FORWARD)
	_check(not _combat._aim_direction(3.0).is_equal_approx(Vector3.FORWARD), "aim assist on: strikes turn toward the creature")
	_place_in_front()


func _place_in_front() -> void:
	_ottavia.global_position = _dummy.global_position + Vector3(0.0, 0.05, 1.6)
	_ottavia.face_toward(Vector3.FORWARD)


func _attack() -> CombatAttack:
	var attack: CombatAttack = CombatAttack.new()
	attack.damage = _tuning.dummy_damage
	attack.source = _dummy
	return attack


func _flat(offset: Vector3) -> float:
	return Vector2(offset.x, offset.z).length()


func _wait(seconds: float) -> void:
	await create_timer(seconds, true, true).timeout


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		print("FAIL: " + message)
