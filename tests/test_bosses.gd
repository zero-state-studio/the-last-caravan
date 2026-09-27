extends SceneTree
## The two phase 3 bosses: the Foglione Radicato (83) with its leaves toward
## the sun and the field lever, and the Vecchio Spartighiaccio (41) with its
## front shield and the ice plates; fight restart after a defeat and the
## victory (105).
## Usage: godot --headless --path . --script res://tests/test_bosses.gd

const TUNING: CreatureTuning = preload("res://assets/combat/creature_tuning.tres")

var _checks: int = 0
var _failures: int = 0
var _ottavia: OttaviaProto
var _manager: RoomManager


func _initialize() -> void:
	change_scene_to_file("res://scenes/proto/diorama.tscn")
	await _wait(0.3)
	_ottavia = current_scene.get_node("Ottavia")
	_manager = current_scene.get_node("RoomManager")
	current_scene.get_node("Creatures").free()

	await _test_foglione()
	await _test_spartighiaccio()

	# Free the level (its creatures keep fighting and playing sounds) and let
	# the audio server drop them: a stream playing at exit counts as a leak.
	current_scene.queue_free()
	# Real time: headless frames run unthrottled, a few of them last
	# microseconds and the audio server would not drop the streams yet.
	await create_timer(0.3, true, false, true).timeout
	print("TESTS: bosses %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _test_foglione() -> void:
	var arena: FoglioneArena = current_scene.get_node("FieldArena")
	var boss: FoglioneRadicato = arena.boss
	await _manager.travel(&"campo_foglione", &"da_cancello")
	await _wait(0.2)
	_check(boss.active and boss.is_in_group(&"active_boss"), "foglione: wakes when Ottavia enters its field")
	var from_west: CombatHit = _hit(Vector3.RIGHT)
	_check(is_equal_approx(boss.damage_multiplier(from_west), TUNING.foglione_leaf_multiplier), "foglione: from the reachable (sun) side only the leaves are hit")

	_ottavia.global_position = arena.lever.global_position + Vector3(0.5, 0.2, 0.5)
	await _wait(0.1)
	_check(_ottavia.interact(), "foglione: Ottavia can pull the field lever")
	_check(arena.tilted and boss.sun_direction.is_equal_approx(Vector3.RIGHT), "foglione: the lever tilts the field and moves the sun east")
	await _wait(180.0 / TUNING.foglione_turn_degrees_per_second + 0.5)
	_check(boss.facing.dot(Vector3.RIGHT) > 0.95, "foglione: the rooted beast turns after the sun")
	_check(is_equal_approx(boss.damage_multiplier(from_west), 1.0), "foglione: its west flank is uncovered")

	# Standing still in the middle of the field: the roots find her.
	_ottavia.global_position = Vector3(58.0, 0.5, 0.0)
	var health: float = _ottavia.health
	await _wait(TUNING.foglione_root_interval + TUNING.foglione_root_telegraph + 0.6)
	_check(_ottavia.health < health, "foglione: roots burst out under Ottavia")

	_ottavia.take_damage(_ottavia.max_health * 2.0)
	await _wait(1.8)
	_check(_manager.current_room.room_id == &"campo_foglione", "boss defeat: Ottavia starts again in the arena")
	_check(is_equal_approx(boss.health, boss.max_health) and not arena.tilted and boss.facing.is_equal_approx(Vector3.LEFT), "boss defeat: the fight starts over from the beginning")

	boss.health = 1.0
	boss.receive_hit(_hit(Vector3.LEFT))
	await _wait(0.2)
	_check(arena.won and not boss.active, "foglione: defeated, the fight is won")
	_ottavia.restore_health()


func _test_spartighiaccio() -> void:
	var arena: IceArena = current_scene.get_node("PondArena")
	var boss: VecchioSpartighiaccio = arena.boss
	await _manager.travel(&"lago_ghiaccio", &"da_sentiero")
	await _wait(0.2)
	_check(boss.active, "spartighiaccio: wakes when Ottavia enters the pond")
	boss.facing = Vector3.LEFT
	_check(is_equal_approx(boss.damage_multiplier(_hit(Vector3.RIGHT)), TUNING.sparti_shield_multiplier), "spartighiaccio: the front shield stops almost everything")
	_check(is_equal_approx(boss.damage_multiplier(_hit(Vector3.FORWARD)), 1.0), "spartighiaccio: its flanks take full damage")

	var cracked_any: bool = false
	for index: int in 60:
		await _wait(0.1)
		if boss.phase == VecchioSpartighiaccio.Phase.RECOVER:
			break
	for x: int in range(-66, -53):
		cracked_any = cracked_any or arena.plate_state(Vector3(x + 0.5, 0.0, boss.global_position.z)) == IceArena.Plate.CRACKED
	_check(cracked_any or _count_cracked(arena) > 0, "spartighiaccio: a charge cracks the ice it crosses")

	var point: Vector3 = arena.global_position + Vector3(-2.25, 0.0, -3.75)
	arena.crack_at(point, 101)
	arena.crack_at(point, 101)
	_check(arena.plate_state(point) == IceArena.Plate.CRACKED, "ice: the same charge cracks a plate only once")
	arena.crack_at(point, 102)
	_check(arena.is_broken_at(point), "ice: a later charge breaks a cracked plate")

	# Just east of the broken plate: it is right ahead of the shield.
	boss.global_position = point + Vector3(0.75 + boss.radius + 0.2, 0.0, 0.0)
	boss.facing = Vector3.LEFT
	boss._set_phase(VecchioSpartighiaccio.Phase.CHARGE)
	await physics_frame
	await physics_frame
	_check(boss.phase == VecchioSpartighiaccio.Phase.STUCK and boss.is_exposed(), "spartighiaccio: stops open at the edge of broken ice")

	_ottavia.global_position = arena.global_position + Vector3(-6.5, 0.1, 5.0)
	await _wait(0.3)
	var health: float = _ottavia.health
	_ottavia.global_position = point + Vector3.UP * 0.2
	await _wait(0.8)
	_check(_ottavia.health < health, "ice: falling into the water costs some health")
	_check(_ottavia.global_position.y > -0.2 and not arena.is_broken_at(_ottavia.global_position), "ice: back on the last safe plate")
	_check(_manager.current_room.room_id == &"lago_ghiaccio", "ice: still in the pond room after the fall")

	_ottavia.take_damage(_ottavia.max_health * 2.0)
	await _wait(1.3)
	_check(not arena.is_broken_at(point) and _count_cracked(arena) == 0, "boss defeat: the ice freezes again")


func _count_cracked(arena: IceArena) -> int:
	var count: int = 0
	for state: int in arena._states:
		if state != IceArena.Plate.INTACT:
			count += 1
	return count


func _hit(direction: Vector3) -> CombatHit:
	var hit: CombatHit = CombatHit.new()
	hit.direction = direction
	hit.damage = 10.0
	return hit


func _wait(seconds: float) -> void:
	await create_timer(seconds, true, true).timeout


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		print("FAIL: " + message)
