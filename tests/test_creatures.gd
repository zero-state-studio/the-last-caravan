extends SceneTree
## The four Margin creatures of phase 3 (36): Voltafaccia (B31) shaded side,
## Raspagelo (B5) underground and bursting out, Brinacchio (B1) drawn by the
## lantern, clinging and crusting, Grappolo (B7) splitting and reforming;
## and the room restart after a defeat (105).
## Usage: godot --headless --path . --script res://tests/test_creatures.gd

const CREATURE_TUNING: CreatureTuning = preload("res://assets/combat/creature_tuning.tres")

var _checks: int = 0
var _failures: int = 0
var _ottavia: OttaviaProto
var _level: Node


func _initialize() -> void:
	change_scene_to_file("res://scenes/proto/diorama.tscn")
	await _wait(0.3)
	_level = current_scene
	_ottavia = _level.get_node("Ottavia")
	_level.get_node("Creatures").free()
	_level.get_node("TrainingDummy").free()
	# Open meadow: no walls between Ottavia and the creatures.
	_ottavia.global_position = Vector3(0.0, 0.05, 11.0)
	await _wait(0.2)

	await _test_voltafaccia()
	await _test_raspagelo()
	await _test_brinacchio()
	await _test_grappolo()
	await _test_room_restart()

	# Free the level (its creatures keep fighting and playing sounds) and let
	# the audio server drop them: a stream playing at exit counts as a leak.
	current_scene.queue_free()
	# Real time: headless frames run unthrottled, a few of them last
	# microseconds and the audio server would not drop the streams yet.
	await create_timer(0.3, true, false, true).timeout
	print("TESTS: creatures %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _test_voltafaccia() -> void:
	var beast: Voltafaccia = _spawn("res://scenes/creatures/voltafaccia.tscn", _ottavia.global_position + Vector3(12.0, -0.05, 0.0))
	_check(beast.shaded_side().is_equal_approx(Vector3.FORWARD), "voltafaccia: facing the Day (west), its right side is north")
	var from_north: CombatHit = _hit(Vector3.BACK, 10.0)
	var from_south: CombatHit = _hit(Vector3.FORWARD, 10.0)
	_check(is_equal_approx(beast.damage_multiplier(from_north), CREATURE_TUNING.voltafaccia_shade_multiplier), "voltafaccia: hit from its shaded (right) side, double damage")
	_check(is_equal_approx(beast.damage_multiplier(from_south), 1.0), "voltafaccia: hit from the other side, normal damage")
	await _wait(0.05)
	_check(beast.health_bar != null and not beast.health_bar.visible, "health bar: hidden until the creature is hit")
	beast.receive_hit(_hit(Vector3.FORWARD, beast.max_health * 0.5))
	await _wait(0.05)
	_check(beast.health_bar.visible and absf(beast.health_bar.fill_ratio() - 0.5) < 0.06, "health bar: shown after a hit, half full at half health (%.2f)" % beast.health_bar.fill_ratio())
	beast.health = beast.max_health
	beast.global_position = _ottavia.global_position + Vector3(3.0, -0.05, 0.0)
	var attacked: bool = false
	for index: int in 40:
		await _wait(0.1)
		attacked = attacked or beast.phase == Voltafaccia.Phase.WINDUP or beast.phase == Voltafaccia.Phase.ACTIVE
	_check(attacked, "voltafaccia: notices Ottavia, sidles close and attacks")
	_check(not beast.sprite.flip_h, "voltafaccia: never turns away from the sun")
	beast.free()
	_ottavia.restore_health()


func _test_raspagelo() -> void:
	var rodent: Raspagelo = _spawn("res://scenes/creatures/raspagelo.tscn", _ottavia.global_position + Vector3(-5.0, -0.05, 0.0))
	await _wait(0.6)
	_check(rodent.phase == Raspagelo.Phase.IDLE, "raspagelo: farther than 2 m it stays put (chapter 1)")
	rodent.global_position = _ottavia.global_position + Vector3(-1.6, -0.05, 0.0)
	await _wait(0.6)
	_check(rodent.phase == Raspagelo.Phase.BURROW and not rodent.can_be_targeted(), "raspagelo: dives and cannot be hit underground")
	var burst: bool = false
	var exposed_after_burst: bool = false
	for index: int in 80:
		await _wait(0.05)
		if rodent.phase == Raspagelo.Phase.BURST or rodent.phase == Raspagelo.Phase.SURFACED:
			burst = true
			exposed_after_burst = exposed_after_burst or (rodent.is_exposed() and rodent.can_be_targeted())
			break
	_check(burst, "raspagelo: bursts out under Ottavia")
	_check(exposed_after_burst, "raspagelo: open right after bursting out")
	rodent._set_phase(Raspagelo.Phase.SURFACED)
	rodent._time = CREATURE_TUNING.raspagelo_exposed + 0.05
	rodent._facing = Vector3.BACK
	_check(is_equal_approx(rodent.damage_multiplier(_hit(Vector3.FORWARD, 10.0)), CREATURE_TUNING.raspagelo_armor_multiplier), "raspagelo: the head plate halves frontal strikes when not open")
	# Defeated, it must stay gone: no digging, no coming back, no attacks.
	var health_before: float = _ottavia.health
	rodent.receive_hit(_hit(Vector3.FORWARD, 1000.0))
	await _wait(5.0)
	_check(not rodent.sprite.visible and rodent.phase == Raspagelo.Phase.SURFACED, "raspagelo: once defeated it does not dig or come back")
	_check(is_equal_approx(_ottavia.health, health_before) and rodent.collision_layer == 0, "raspagelo: once defeated it neither attacks nor blocks the way")
	rodent.free()
	_ottavia.restore_health()


func _test_brinacchio() -> void:
	_ottavia.set_lantern_open(true)
	var drawn: Brinacchio = _spawn("res://scenes/creatures/brinacchio.tscn", _ottavia.global_position + Vector3(7.0, -0.05, 0.0))
	await _wait(1.2)
	_check(drawn.flat_distance_to(_ottavia.global_position) < 6.5, "brinacchio: drawn by the open lantern from far away")
	drawn.free()
	_ottavia.set_lantern_open(false)
	var unaware: Brinacchio = _spawn("res://scenes/creatures/brinacchio.tscn", _ottavia.global_position + Vector3(7.0, -0.05, 0.0))
	await _wait(1.2)
	_check(unaware.phase == Brinacchio.Phase.WANDER, "brinacchio: shutter closed, it does not sense Ottavia")
	unaware.free()
	_ottavia.set_lantern_open(true)

	var clinging: Brinacchio = _spawn("res://scenes/creatures/brinacchio.tscn", _ottavia.global_position + Vector3(0.4, -0.05, 0.0))
	await _wait(0.3)
	_check(clinging.phase == Brinacchio.Phase.LATCHED, "brinacchio: clings to Ottavia")
	_check(_ottavia.combat.slowdown > 0.0, "brinacchio: clinging slows her down")
	_check(_ottavia.health < _ottavia.max_health, "brinacchio: clinging drains a little health")
	_ottavia.combat.press(&"jump")
	await physics_frame
	await physics_frame
	_check(clinging.phase == Brinacchio.Phase.CRUSTED and clinging.has_shield, "brinacchio: a jump shakes it off, crusted with frost")
	_check(is_zero_approx(_ottavia.combat.slowdown), "brinacchio: no slowdown once shaken off")
	var strike: CombatHit = CombatHit.new()
	strike.kind = CombatHit.Kind.STRIKE
	strike.damage = 20.0
	clinging.receive_hit(strike)
	_check(clinging.phase == Brinacchio.Phase.STUNNED and not clinging.has_shield and clinging.is_alive(), "brinacchio: a strike cracks the crust and leaves it stunned")
	clinging.receive_hit(strike)
	_check(not clinging.is_alive(), "brinacchio: the next strike defeats it")
	clinging.free()
	_ottavia.restore_health()
	await _wait(0.5)


func _test_grappolo() -> void:
	var colony: Grappolo = _spawn("res://scenes/creatures/grappolo.tscn", _ottavia.global_position + Vector3(0.0, -0.05, -15.0))
	var sparti: VecchioSpartighiaccio = current_scene.get_node("PondArena/Spartighiaccio")
	_check(sparti.health_bar == null, "health bar: bosses show their health in the HUD instead")
	await _wait(0.1)
	var members: int = colony.members
	colony.receive_hit(_hit(Vector3.FORWARD, 1.0))
	await _wait(0.1)
	_check(colony.phase == Grappolo.Phase.SPLIT and not colony.can_be_targeted(), "grappolo: a hit breaks the ball apart")
	_check(colony.bits.size() == members, "grappolo: one piece per member (%d)" % colony.bits.size())
	for index: int in 2:
		colony.bits[index].receive_hit(_hit(Vector3.FORWARD, 100.0))
	await _wait(CREATURE_TUNING.grappolo_reform_seconds + 2.0)
	_check(colony.phase != Grappolo.Phase.SPLIT and colony.sprite.visible, "grappolo: the survivors roll back together")
	_check(colony.members == members - 2, "grappolo: the reformed ball is smaller (%d members)" % colony.members)
	colony.free()


func _test_room_restart() -> void:
	var beast: Voltafaccia = _spawn("res://scenes/creatures/voltafaccia.tscn", Vector3(-9.0, 0.0, 9.0))
	var start: Vector3 = beast.global_position
	beast.receive_hit(_hit(Vector3.FORWARD, 5.0))
	beast.global_position += Vector3(2.0, 0.0, 0.0)
	_ottavia.take_damage(_ottavia.max_health * 2.0)
	await _wait(1.8)
	_check(is_equal_approx(beast.health, beast.max_health), "defeat: the creatures of the room are back to full health")
	# Moved 2 m away before the defeat; after the reset it grazes again
	# during the fade, so allow a little drift.
	_check(beast.global_position.distance_to(start) < 1.0, "defeat: the creatures of the room are back at their start")
	beast.free()


func _spawn(path: String, position: Vector3) -> CombatEnemy:
	var creature: CombatEnemy = (load(path) as PackedScene).instantiate()
	creature.position = position
	_level.add_child(creature)
	return creature


func _hit(direction: Vector3, damage: float) -> CombatHit:
	var hit: CombatHit = CombatHit.new()
	hit.direction = direction
	hit.damage = damage
	return hit


func _wait(seconds: float) -> void:
	await create_timer(seconds, true, true).timeout


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		print("FAIL: " + message)
