extends SceneTree
## Chapter 1 in its placeholder form (phase 4b step 2), walked through by
## script: the Truce (Iole, the sundial, the caller), every room of the
## dungeon with its levers, gates, saved people and shortcuts, the easy
## bridge and the bonus branch, the boss and its end, and the ending.
## Usage: godot --headless --path . --script res://tests/test_chapter01.gd

const SAVE_PATH: String = "user://test_save_c01.json"

var _checks: int = 0
var _failures: int = 0
var _scene: Node
var _manager: RoomManager
var _ottavia: OttaviaProto


func _initialize() -> void:
	SaveGame.path_override = SAVE_PATH
	GameState.reset()
	# Options stay as set here: scenes do not read them from disk again.
	GameOptions.loaded = true
	GameOptions.difficulty = Difficulty.Level.MEDIUM
	await _test_truce()
	await _test_truce_runs_out()
	await _test_dungeon()
	await _test_easy_bridge()
	await _test_ending()
	GameState.reset()
	GameOptions.difficulty = Difficulty.Level.MEDIUM
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	SaveGame.path_override = ""
	current_scene.queue_free()
	await create_timer(0.3, true, false, true).timeout
	print("TESTS: chapter01 %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


# --- Truce -------------------------------------------------------------------

func _load(path: String) -> void:
	change_scene_to_file(path)
	await _wait(0.4)
	_scene = current_scene
	_ottavia = _scene.get_node("Ottavia")
	_manager = _scene.get_node_or_null("RoomManager") as RoomManager


func _test_truce() -> void:
	await _load("res://scenes/capitolo01/tregua.tscn")
	_scene.set(&"line_seconds", 0.3)
	_scene.set(&"leave_scene", false)
	await _wait(4.5)
	var clock: TruceClock = _scene.get(&"clock")
	_check(clock.running and GameState.at_caravan, "Truce: the Meridian calls it and the sundial runs")
	_check(GameState.warm_stones == 0, "Truce: chapter 1 starts with no warm stones")
	# The three warm stones and the patches of the Truce.
	var found: int = 0
	for node: Node in _scene.get_node("Level").get_children():
		if node is WorldPickup:
			found += 1
	_check(found == 6, "Truce: two patches, three warm stones and a memory lie around (got %d)" % found)
	var stone: WorldPickup = null
	for node: Node in _scene.get_node("Level").get_children():
		if node is WorldPickup and (node as WorldPickup).item_id == &"warm_stone":
			stone = node
			break
	_ottavia.global_position = stone.global_position
	await _wait(0.3)
	_check(GameState.warm_stones == 1, "Truce: a warm stone taken")
	var pellegrino: Pellegrino = _scene.get(&"pellegrino")
	_ottavia.global_position = pellegrino.global_position + Vector3(-2.5, 0.0, 0.0)
	await _wait(1.0)
	_check(not pellegrino.is_provoked() and is_equal_approx(_ottavia.health, _ottavia.max_health), "Truce: the Pellegrino asleep does not attack unless provoked")
	var hit: CombatHit = CombatHit.new()
	hit.damage = 1.0
	hit.direction = Vector3.RIGHT
	pellegrino.receive_hit(hit)
	_check(pellegrino.is_provoked() and pellegrino.has_felt(), "Truce: provoked, it wakes; the felt goes first")
	pellegrino.reset_enemy()
	var iole: Interactable = _scene.get(&"iole")
	var left: Array[bool] = [false]
	_scene.connect(&"left_for_dungeon", func() -> void: left[0] = true)
	_ottavia.global_position = iole.global_position + Vector3(1.2, 0.05, 0.0)
	await _wait(0.2)
	_check(_ottavia.interact(), "Truce: Ottavia talks to Iole")
	await _wait(2.0)
	_check(left[0] and not clock.running, "Truce: after Iole's lines, into the dungeon; the sundial stops")


func _test_truce_runs_out() -> void:
	GameState.reset()
	await _load("res://scenes/capitolo01/tregua.tscn")
	_scene.set(&"line_seconds", 0.3)
	_scene.set(&"leave_scene", false)
	await _wait(4.5)
	var clock: TruceClock = _scene.get(&"clock")
	clock.seconds_left = 1.0
	var left: Array[bool] = [false]
	_scene.connect(&"left_for_dungeon", func() -> void: left[0] = true)
	await _wait(1.5)
	var caller: TruceCaller = _scene.get(&"caller")
	_check(caller.visible and not _ottavia.controls_enabled, "Truce over: Iole runs to Ottavia")
	await _wait(6.0)
	_check(left[0], "Truce over: after her lines, into the dungeon")


# --- Dungeon -----------------------------------------------------------------

func _test_dungeon() -> void:
	GameState.reset()
	await _load("res://scenes/capitolo01/carri_campo.tscn")
	_scene.set(&"line_seconds", 0.3)
	_scene.set(&"leave_scene", false)
	_check(_room() == &"s1", "dungeon: starts at the foot of the first cart")
	var t1: TurningPlatform = _scene.get(&"terrace_1")
	# Room 1: the first lever brings the ramp down into the room.
	var lever: TurnLever = _scene.get(&"lever_s1")
	await _pull(lever)
	_check(t1.quarter == 2, "room 1: one pull, the ramp comes down into room 1")
	# Room 2: two more pulls from the terrace, the ramp points to room 3.
	await _travel(&"s2", &"da_rampa")
	var lever_s2: TurnLever = _lever_on(t1)
	await _pull(lever_s2)
	await _pull(lever_s2)
	_check(t1.quarter == 0, "room 2: two more pulls, the ramp points east")
	var to_grass: GatedExit = _exit_to(&"s3", &"da_rampa")
	await _into(to_grass)
	_check(_room() == &"s3", "room 2: down the ramp into the tall grass")
	# Room 3: the ladder to room 4.
	var climb: ClimbSpot = _climb_near(Vector3(107.3, 1.0, -4.5))
	await climb.climb(_ottavia)
	await _wait(1.0)
	_check(_room() == &"s4", "room 3: up the ladder to room 4")
	# Room 4: Ruggero, the knot, his shortcut, the bridge from above.
	var ruggero: RescuedPerson = _scene.get(&"ruggero")
	_ottavia.global_position = ruggero.global_position + Vector3(-1.0, 0.05, 0.0)
	await _wait(0.2)
	_check(_ottavia.interact(), "room 4: Ruggero tied to the rope")
	await _wait(4.0)
	_check(GameState.knots == 1 and GameState.has_flag(&"c01_shortcut_ruggero") and GameState.has_flag(&"c01_bridge_high"), "room 4: a knot, his shortcut and the bridge down")
	_check(_exit_to(&"s1", &"da_scorciatoia", Vector3(190.0, 5.0, 4.0)).is_open(), "room 4: the shortcut back to the entry is open")
	# The bonus branch: hedge stems, then a patch, a stone and a memory.
	var hedge: Array[Breakable] = _scene.get(&"bonus_hedge")
	_check(hedge.size() == 3, "room 4: at medium the bonus branch is behind a hedge of stems")
	# Two turns of the terrace: the ramp comes down onto room 5.
	var t2: TurningPlatform = _scene.get(&"terrace_2")
	_ottavia.global_position = t2.global_position + Vector3(0.0, 0.5, 0.0)
	await _wait(0.2)
	var lever_s4: TurnLever = _lever_on(t2)
	var basking: Array[Specchietto] = []
	for node: Node in _scene.get_tree().get_nodes_in_group(&"combat_targets"):
		if node is Specchietto and (node as Node3D).global_position.distance_to(t2.global_position) < 10.0:
			basking.append(node)
	_check(basking.size() == 4 and basking.all(func(lizard: Specchietto) -> bool: return lizard.in_sunlight()), "room 4: the four Specchietti bask in the sun at the start")
	await _pull(lever_s4)
	await _wait(0.2)
	var shaded: int = basking.filter(func(lizard: Specchietto) -> bool: return not lizard.in_sunlight()).size()
	_check(shaded >= 3, "room 4: after one turn the fan cabbages shade the Specchietti (%d of 4)" % shaded)
	await _pull(lever_s4)
	_check(t2.quarter == 2, "room 4: two turns, the ramp points to room 5")
	await _into(_exit_to(&"s5", &"da_rampa"))
	_check(_room() == &"s5", "room 4: down the ramp to room 5")
	# Room 5: two turns lower the bridge toward room 6.
	var t3: TurningPlatform = _scene.get(&"terrace_3")
	var lever_s5: TurnLever = _lever_on(t3)
	await _pull(lever_s5)
	await _pull(lever_s5)
	_check(GameState.has_flag(&"c01_bridge_low"), "room 5: at the second turn the bridge comes down")
	await _into(_exit_to(&"s6", &"da_ponte"))
	_check(_room() == &"s6", "room 5: across the bridge to room 6")
	# Room 6: the crust, the stems, the lever, Pia, the ladder.
	var lever_s6: TurnLever = _scene.get(&"lever_s6")
	_check(not lever_s6.can_use(), "room 6: the lever is locked by the ice")
	var crust: Breakable = _scene.get(&"ice_crust")
	_break(crust)
	_check(lever_s6.can_use(), "room 6: the crust breaks, the lever works")
	var pia: RescuedPerson = _scene.get(&"pia")
	_check(not pia.can_use(), "room 6: Pia is in the cage of plants")
	for stem: Breakable in _scene.get(&"stems"):
		_break(stem)
	_check(pia.can_use(), "room 6: six stems broken, Pia can be reached")
	var t4: TurningPlatform = _scene.get(&"terrace_4")
	await _pull(lever_s6)
	await _pull(lever_s6)
	await _wait(0.2)
	_check(t4.quarter == 2 and absf(t4.rotation.x) < 0.01, "room 6: two pulls, the terrace level and turned toward the ladder")
	_ottavia.global_position = pia.global_position + Vector3(-1.0, 0.05, 0.0)
	await _wait(0.2)
	_check(_ottavia.interact(), "room 6: Pia tied to the rope")
	await _wait(4.0)
	_check(GameState.knots == 2 and GameState.has_flag(&"c01_shortcut_pia"), "room 6: a second knot and her shortcut")
	var ladder: ClimbSpot = _scene.get(&"ladder_to_top")
	_check(ladder.monitoring, "room 6: the ladder to the top can be climbed")
	await ladder.climb(_ottavia)
	await _wait(1.0)
	_check(_room() == &"s7", "room 6: up the ladder to the top")
	await _test_boss()


func _test_boss() -> void:
	var boss: RootedFoglione = _scene.get(&"boss")
	var arena: TurningPlatform = _scene.get(&"arena")
	await _wait(0.3)
	_check(boss.active, "room 7: the boss wakes")
	_check(is_equal_approx(boss.max_health, CreatureTuning.health_for_hits(30.0)), "room 7: about 30 base strikes")
	var hit: CombatHit = CombatHit.new()
	hit.damage = 14.0
	hit.direction = Vector3.FORWARD
	var before: float = boss.health
	boss.receive_hit(hit)
	_check(is_equal_approx(boss.health, before), "room 7: with the leaves closed, strikes bounce off")
	var levers: Array[TurnLever] = _scene.get(&"arena_levers")
	levers[0].use()
	await _wait(arena.turn_seconds() + 0.1)
	_check(boss.flank_open(), "room 7: after a turn it turns back to the sun, flank open")
	# A strike on its flank: from the side opposite to its face's right.
	var flank: CombatHit = CombatHit.new()
	flank.damage = 14.0
	flank.direction = -boss.facing.cross(Vector3.UP).normalized()
	before = boss.health
	boss.receive_hit(flank)
	_check(is_equal_approx(before - boss.health, 28.0), "room 7: a strike on the flank does double damage")
	boss.health = boss.max_health * 0.5
	boss.receive_hit(flank)
	_check(boss.phase == RootedFoglione.Phase.TWO, "room 7: below two thirds, phase 2")
	# Phase 3: basking with the leaves open, struck from any side.
	boss.health = boss.max_health * 0.3
	boss.receive_hit(flank)
	_check(boss.phase == RootedFoglione.Phase.THREE, "room 7: below a third, phase 3")
	boss._set_act(RootedFoglione.Act.BASK)
	var front: CombatHit = CombatHit.new()
	front.damage = 14.0
	front.direction = -boss.facing
	before = boss.health
	boss.receive_hit(front)
	_check(is_equal_approx(before - boss.health, 14.0) and boss.act == RootedFoglione.Act.RECOVER, "room 7: basking, a strike from the front does normal damage and stops the healing")
	var won: Array[bool] = [false]
	_scene.connect(&"chapter_won", func() -> void: won[0] = true)
	boss.health = 1.0
	await _wait(0.1)
	if not boss.flank_open():
		levers[1].use()
		await _wait(arena.turn_seconds() + 0.1)
	flank.direction = -boss.facing.cross(Vector3.UP).normalized()
	boss.receive_hit(flank)
	_check(not boss.is_alive() and boss.act == RootedFoglione.Act.UPROOTED, "room 7: beaten, it uproots instead of dying")
	await _wait(6.0)
	_check(won[0] and not boss.visible, "room 7: it rolls off the cart and goes; the chapter is won")


func _test_easy_bridge() -> void:
	GameState.reset()
	GameOptions.difficulty = Difficulty.Level.EASY
	await _load("res://scenes/capitolo01/carri_campo.tscn")
	_scene.set(&"leave_scene", false)
	var t1: TurningPlatform = _scene.get(&"terrace_1")
	var bridge: GatedExit = _exit_to(&"s4", &"da_ponte", Vector3(10.4, 2.6, -2.2))
	_check(not bridge.is_open(), "easy: the bridge is there, but the terrace is not turned toward it yet")
	t1.set_quarter(0)
	_check(bridge.is_open(), "easy: turned toward it, the bridge to room 4 skips room 3")
	var hedge: Array[Breakable] = _scene.get(&"bonus_hedge")
	_check(hedge.is_empty(), "easy: no bonus branch")
	GameOptions.difficulty = Difficulty.Level.MEDIUM


func _test_ending() -> void:
	await _load("res://scenes/capitolo01/fine.tscn")
	_scene.set(&"line_seconds", 0.3)
	_scene.set(&"title_seconds", 0.3)
	await _wait(8.0)
	_check(_scene.get(&"marching"), "ending: after Ruggero and the Meridian, the caravan marches")
	var anselmo: Node3D = _scene.get(&"anselmo")
	_ottavia.global_position = anselmo.global_position + Vector3(1.0, 0.0, 0.0)
	await _wait(2.5)
	_check(_scene.get(&"delivered") and LanternProgress.pieces == 1, "ending: the wick to Anselmo, the first piece of the lantern")
	var screen: ChapterScreen = _scene.get_node("ChapterScreen")
	_check(screen.is_open() and GameState.chapter == 2, "ending: the end-of-chapter screen, chapter 2 begins")
	screen.close()
	await _wait(2.0)
	_check(_ottavia.combat.chapter == 2 and Progression.run_share(2) < 1.0, "ending: from chapter 2 the run lasts less")


# --- Helpers -------------------------------------------------------------------

func _room() -> StringName:
	return _manager.current_room.room_id if _manager.current_room != null else &""


func _travel(room: StringName, entry: StringName) -> void:
	await _manager.travel(room, entry)
	await _wait(0.1)


func _pull(lever: TurnLever) -> void:
	lever.use()
	await _wait(lever.platform.turn_seconds() + 0.15)


func _lever_on(platform: TurningPlatform) -> TurnLever:
	for child: Node in platform.get_children():
		if child is TurnLever:
			return child
	return null


## The passage to `room`/`entry` (the nearest to `near` if given).
func _exit_to(room: StringName, entry: StringName, near: Vector3 = Vector3.INF) -> GatedExit:
	var best: GatedExit = null
	for node: Node in _scene.get_node("Level").get_children():
		var exit: GatedExit = node as GatedExit
		if exit == null or exit.target_room != room or exit.target_entry != entry:
			continue
		if best == null or (near != Vector3.INF and exit.global_position.distance_to(near) < best.global_position.distance_to(near)):
			best = exit
	return best


func _into(exit: GatedExit) -> void:
	_check(exit != null and exit.is_open(), "passage open toward %s" % (exit.target_room if exit != null else &"?"))
	_ottavia.global_position = exit.global_position + Vector3.DOWN * 0.3
	await _wait(1.0)


func _climb_near(point: Vector3) -> ClimbSpot:
	var best: ClimbSpot = null
	for node: Node in _scene.find_children("*", "ClimbSpot", true, false):
		var spot: ClimbSpot = node
		if best == null or spot.global_position.distance_to(point) < best.global_position.distance_to(point):
			best = spot
	return best


func _break(target: Breakable) -> void:
	var hit: CombatHit = CombatHit.new()
	hit.damage = 1000.0
	target.receive_hit(hit)


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		print("FAIL: ", label)


func _wait(seconds: float) -> void:
	await create_timer(seconds, true, true).timeout
