extends SceneTree
## Systems of chapter 1 in the diorama yard (phase 4b step 1): the Truce
## sundial (warning, stopped in a dungeon room, the caller at the end), the
## turning platform with its levers (carrying Ottavia, a creature and its
## children, the lever locked by ice), the saved person (knot, hint,
## shortcut, walk home), the autosave and «Continue», and the defeat that
## restarts the room (105).
## Usage: godot --headless --path . --script res://tests/test_systems.gd

const SAVE_PATH: String = "user://test_save.json"
const YARD_ROOM: StringName = &"banco"
const YARD_ENTRY: StringName = &"ingresso"
const YARD_CENTER: Vector3 = Vector3(0.0, 0.0, 60.0)
const YARD_ENTRY_POINT: Vector3 = Vector3(-13.0, 0.05, 64.0)
const CHAPTER_TUNING_PATH: String = "res://assets/combat/chapter_01_tuning.tres"

var _checks: int = 0
var _failures: int = 0
var _diorama: Node
## Untyped: a typed reference to the yard's class from this script keeps
## its scripts in use at exit.
var _yard
var _manager: RoomManager
var _ottavia: OttaviaProto


func _initialize() -> void:
	SaveGame.path_override = SAVE_PATH
	_remove_test_save()
	change_scene_to_file("res://scenes/proto/diorama.tscn")
	await _wait(0.3)
	_diorama = current_scene
	_diorama.get_node("Creatures").free()
	GameState.reset()
	_yard = _diorama.get("yard")
	_manager = _diorama.get_node("RoomManager")
	_ottavia = _diorama.get_node("Ottavia")

	await _test_truce()
	await _test_platform()
	await _test_levers()
	await _test_saved()
	await _test_save_and_continue()
	await _test_defeat_in_yard()

	_remove_test_save()
	GameState.reset()
	SaveGame.path_override = ""
	current_scene.queue_free()
	await create_timer(0.3, true, false, true).timeout
	print("TESTS: systems %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _test_truce() -> void:
	var clock: TruceClock = _yard.clock
	var warned: Array[bool] = [false]
	clock.warning.connect(func() -> void: warned[0] = true)
	_yard.start_truce(3.0)
	_check(clock.running and GameState.at_caravan, "Truce: started at the caravan")
	_check(GameState.warm_stones == (load(CHAPTER_TUNING_PATH) as ChapterTuning).truce_warm_stones, "Truce: warm stones back to three (129)")
	_check(SaveGame.has_save() and str(SaveGame.read()["checkpoint"]["stage"]) == "truce", "Truce: autosave at its start (95)")
	var banner: HintBanner = get_first_node_in_group(&"hint_banner") as HintBanner
	_check(banner != null and banner.current_hint() == TruceClock.HINT_SUNDIAL, "Truce: the sundial hint")
	await _wait(1.8)
	_check(warned[0] and clock.in_warning(), "Truce: the warning before the end")
	await _manager.travel(YARD_ROOM, YARD_ENTRY)
	var left: float = clock.seconds_left
	await _wait(0.6)
	_check(clock.paused and is_equal_approx(clock.seconds_left, left) and not GameState.at_caravan, "Truce: the sundial stops in a dungeon room (38)")
	_check(str(SaveGame.read()["checkpoint"]["stage"]) == "dungeon", "dungeon entry: autosave (95)")
	await _manager.travel(&"prato", &"inizio")
	await _wait(1.8)
	_check(not clock.running, "Truce: the shadow reaches the end")
	_check(_yard.caller.visible and not _ottavia.controls_enabled, "Truce over: the caller runs to Ottavia, who waits")
	await _wait(12.0)
	_check(_manager.current_room.room_id == YARD_ROOM and _ottavia.controls_enabled, "Truce over: after the lines Ottavia is in the dungeon")


func _test_platform() -> void:
	var platform: TurningPlatform = _yard.platform
	var beast: CombatEnemy = _yard.get_node("YardVoltafaccia") as CombatEnemy
	beast.process_mode = Node.PROCESS_MODE_DISABLED
	var center: Vector3 = YARD_CENTER
	_ottavia.global_position = center + Vector3(2.0, 1.05, 0.0)
	await _wait(0.3)
	var beast_before: Vector3 = beast.global_position
	var spawn_before: Vector3 = beast.spawn_transform.origin
	var seed: Node3D = platform.get_node_or_null(^"WorldPickup") as Node3D
	var turned: Array[int] = [-1]
	platform.turn_finished.connect(func(quarter: int) -> void: turned[0] = quarter, CONNECT_ONE_SHOT)
	_check(platform.turn(), "platform: a quarter turn starts")
	_check(not platform.turn(), "platform: no second turn while turning")
	await _wait(platform.turn_seconds() + 0.3)
	_check(turned[0] == 1 and platform.quarter == 1, "platform: one quarter done in %.1f s" % platform.turn_seconds())
	var expected_ottavia: Vector3 = center + Vector3(0.0, 0.0, 2.0)
	_check(_flat(_ottavia.global_position, expected_ottavia) < 0.35, "platform: Ottavia carried clockwise (east to south), got %s" % _ottavia.global_position)
	var expected_beast: Vector3 = center + (beast_before - center).rotated(Vector3.UP, TurningPlatform.QUARTER)
	_check(_flat(beast.global_position, expected_beast) < 0.1, "platform: the creature carried with it")
	var expected_spawn: Vector3 = center + (spawn_before - center).rotated(Vector3.UP, TurningPlatform.QUARTER)
	_check(_flat(beast.spawn_transform.origin, expected_spawn) < 0.1, "platform: the creature's start point turns too (105)")
	_check(is_equal_approx(wrapf(platform.rotation.y, -PI, PI), -PI * 0.5), "platform: the terrace itself is turned")
	beast.process_mode = Node.PROCESS_MODE_INHERIT
	_ottavia.global_position = center + Vector3(-9.0, 0.05, 0.0)
	await _wait(0.2)


func _test_levers() -> void:
	var platform: TurningPlatform = _yard.platform
	_ottavia.global_position = _yard.lever.global_position + Vector3(0.8, 0.05, 0.0)
	await _wait(0.4)
	var banner: HintBanner = get_first_node_in_group(&"hint_banner") as HintBanner
	_check(banner.current_hint() == &"HINT_USE_LEVER", "lever: «Use the lever» near the first one")
	var quarter: int = platform.quarter
	_check(_ottavia.interact(), "lever: pulled with the interact action")
	_check(platform.turning, "lever: the platform turns")
	await _wait(platform.turn_seconds() + 0.2)
	_check(platform.quarter == (quarter + 1) % 4, "lever: one pull, one quarter")
	_ottavia.global_position = _yard.locked_lever.global_position + Vector3(0.5, 0.05, 0.6)
	await _wait(0.2)
	_check(not _yard.locked_lever.can_use(), "ice lever: locked by the crust")
	var hit: CombatHit = CombatHit.new()
	hit.damage = 1000.0
	_yard.crust.receive_hit(hit)
	await _wait(0.2)
	_check(_yard.locked_lever.can_use(), "ice lever: free once the crust breaks")
	_yard.locked_lever.use()
	await _wait(platform.turn_seconds() + 0.2)
	_check(platform.quarter == (quarter + 2) % 4, "ice lever: turns the same platform")


func _test_saved() -> void:
	var saved: RescuedPerson = _yard.saved
	var knots: int = GameState.knots
	_ottavia.global_position = saved.global_position + Vector3(-1.0, 0.05, 0.0)
	await _wait(0.3)
	_check(_ottavia.interact(), "saved: tied to the rope with the interact action")
	await _wait(2.0)
	var rope: RopeCounter = get_first_node_in_group(&"rope_counter") as RopeCounter
	_check(GameState.knots == knots + 1 and rope.knots == knots + 1, "saved: a knot on the rope (125)")
	var banner: HintBanner = get_first_node_in_group(&"hint_banner") as HintBanner
	_check(banner.current_hint() == &"HINT_SAVED_OPEN_WAY", "saved: «Those you save open the way back»")
	_check(_yard.shortcut.is_open and GameState.has_flag(_yard.shortcut.shortcut_id), "saved: the shortcut opens and stays open")
	await _wait(30.0)
	_check(not saved.visible, "saved: they walk home alone and leave")
	_check(not saved.can_use(), "saved: cannot be tied twice")


func _test_save_and_continue() -> void:
	GameState.receive(&"patch_felt", 3)
	await _manager.travel(&"prato", &"inizio")
	await _manager.travel(YARD_ROOM, YARD_ENTRY)
	var data: Dictionary = SaveGame.read()
	_check(str(data["checkpoint"]["room"]) == String(YARD_ROOM), "save: the checkpoint is the dungeon entry")
	var knots: int = GameState.knots
	GameState.reset()
	GameState.from_data(data["state"])
	_check(GameState.knots == knots and &"patch_felt" in GameState.found_patches and GameState.has_flag(&"yard_shortcut"), "save: knots, patches and shortcuts come back")
	_ottavia.global_position = Vector3(0.0, 0.05, 0.0)
	await _wait(0.2)
	_check(_manager.restore_checkpoint(data["checkpoint"]), "continue: back at the saved entry")
	_check(_flat(_ottavia.global_position, YARD_ENTRY_POINT) < 0.3 and _manager.current_room.room_id == YARD_ROOM, "continue: Ottavia in the saved room")
	var shortcut: RescueShortcut = RescueShortcut.new()
	shortcut.shortcut_id = &"yard_shortcut"
	_diorama.add_child(shortcut)
	await _wait(0.1)
	_check(shortcut.is_open, "continue: an opened shortcut is open from the start")
	shortcut.queue_free()


func _test_defeat_in_yard() -> void:
	var beast: CombatEnemy = _yard.get_node("YardVoltafaccia") as CombatEnemy
	beast.global_position = beast.spawn_transform.origin + Vector3(0.0, 0.0, 3.0)
	var at_restart: Array[float] = [INF]
	_manager.room_restarted.connect(func(_room: Room) -> void: at_restart[0] = _flat(beast.global_position, beast.spawn_transform.origin), CONNECT_ONE_SHOT)
	_ottavia.take_damage(_ottavia.max_health * 2.0)
	await _wait(1.8)
	_check(is_equal_approx(_ottavia.health, _ottavia.max_health) and _flat(_ottavia.global_position, YARD_ENTRY_POINT) < 0.6, "defeat: full health at the entry of the room (105)")
	_check(at_restart[0] < 0.05, "defeat: the creatures of the room are back at their start (got %.2f m)" % at_restart[0])


func _remove_test_save() -> void:
	# Only the test's own file in user://, never the player's save.
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		print("FAIL: ", label)


func _wait(seconds: float) -> void:
	await create_timer(seconds, true, true).timeout
