class_name PrologueAutoplay
extends Node
## Development only: plays the whole prologue by itself, for the delivery
## video (phase 4a, step 7). It presses the same actions a player would
## (move, run, jump, lantern, strike, interact) through Input, so every
## system runs as in real play. Started by the scene argument autoplay=1;
## it lives under the root, so it goes on across the scene changes.

const ARRIVE_METERS: float = 0.6
const STUCK_SECONDS: float = 1.5
const MOVES: Array[StringName] = [&"move_left", &"move_right", &"move_up", &"move_down"]

var _scene: Node
var _stuck_time: float = 0.0
var _last_position: Vector3
var _side_step: float = 0.0


## Adds the driver when the scene was started with autoplay=1.
static func attach_if_requested(tree: SceneTree) -> void:
	if not "autoplay=1" in OS.get_cmdline_user_args():
		return
	if tree.root.get_node_or_null(^"PrologueAutoplay") != null:
		return
	var driver: PrologueAutoplay = PrologueAutoplay.new()
	driver.name = "PrologueAutoplay"
	tree.root.add_child.call_deferred(driver)


func _ready() -> void:
	_watch()


func _watch() -> void:
	while true:
		await get_tree().physics_frame
		var scene: Node = get_tree().current_scene
		if scene == null or scene == _scene or not scene.is_node_ready():
			continue
		_scene = scene
		_release_all()
		print("AUTOPLAY scene %s" % scene.scene_file_path)
		match scene.scene_file_path:
			PrologueState.FLOOR_SCENE:
				_play_floor(scene)
			PrologueState.CAMP_SCENE:
				_play_camp(scene)
			PrologueState.COLUMN_SCENE:
				_play_column(scene)


func _alive(scene: Node) -> bool:
	return is_instance_valid(scene) and scene == get_tree().current_scene


# --- The three spaces -------------------------------------------------------

func _play_floor(scene: Node) -> void:
	var ottavia: OttaviaProto = scene.ottavia
	await _until(scene, func() -> bool: return scene.step == scene.Step.OPEN_LANTERN, 20.0)
	await _wait(scene, 1.2)
	await _tap(scene, &"lantern")
	await _wait(scene, 1.0)
	await _walk_to(scene, ottavia, Vector3(ottavia.global_position.x, 0.0, -1.6), false)
	await _walk_to(scene, ottavia, scene.ZELINDA_POSITION + Vector3(-2.2, 0.0, 1.5), false)
	await _until(scene, func() -> bool: return scene.step == scene.Step.CLOSE_LANTERN, 3.0)
	await _wait(scene, 2.5)
	await _tap(scene, &"lantern")
	await _wait(scene, 1.5)
	await _walk_to(scene, ottavia, Vector3(scene.DOOR_POSITION.x - 2.5, 0.0, -1.8), false)
	await _walk_to(scene, ottavia, scene.DOOR_POSITION + Vector3(0.6, 0.0, 0.0), false, 12.0)


func _play_camp(scene: Node) -> void:
	var ottavia: OttaviaProto = scene.ottavia
	var tasks: CampTasks = scene.tasks
	await _until(scene, func() -> bool: return tasks.task == CampTasks.Task.SPRINT, 120.0)
	await _wait(scene, 1.0)
	# Sprint to the Tails, jump the three rows, on to the tents.
	var lane_z: float = ottavia.global_position.z
	await _walk_to(scene, ottavia, Vector3(CampTasks.ROCK_ROWS[0] - 3.0, 0.0, lane_z), true)
	for row: float in CampTasks.ROCK_ROWS:
		await _walk_to(scene, ottavia, Vector3(row - 1.6, 0.0, lane_z), true)
		_hold_toward(ottavia, Vector3(row + 3.0, 0.0, lane_z), true)
		await _tap(scene, &"jump")
		await _wait(scene, 0.5)
	print("AUTOPLAY camp tails jumped")
	await _walk_to(scene, ottavia, CampTasks.TENTS + Vector3(-2.0, 0.0, 3.0), false)
	await _until(scene, func() -> bool: return tasks.task == CampTasks.Task.CLIMB, 3.0)
	await _wait(scene, 1.5)
	# Round the field-wagon's head to the ladder and walk into it.
	var climb: ClimbSpot = tasks.find_children("*", "ClimbSpot", true, false)[0]
	var below: Vector3 = Vector3(climb.global_position.x, 0.0, climb.global_position.z + 1.6)
	await _walk_to(scene, ottavia, Vector3(CampTasks.LANDING_MIN.x - 3.0, 0.0, CampTasks.TENTS.z + 3.0), false)
	await _walk_to(scene, ottavia, Vector3(CampTasks.LANDING_MIN.x - 3.0, 0.0, below.z), false)
	await _walk_to(scene, ottavia, below, false)
	_hold_toward(ottavia, climb.global_position - climb.wall_normal * 3.0, false)
	await _until(scene, func() -> bool: return ottavia.is_climbing(), 4.0)
	print("AUTOPLAY camp climbing=%s" % ottavia.is_climbing())
	_release_moves()
	await _until(scene, func() -> bool: return not ottavia.is_climbing(), 4.0)
	await _walk_to(scene, ottavia, CampTasks.RUGGERO_SPOT + Vector3(0.9, 0.0, 0.3), false)
	await _wait(scene, 0.8)
	print("AUTOPLAY camp ruggero task=%d" % tasks.task)
	await _tap(scene, &"interact")
	await _until(scene, func() -> bool: return tasks.task == CampTasks.Task.BREAK, 3.0)
	await _wait(scene, 2.5)
	# Down from the landing, to the Homehauler and the stuck Tail.
	await _walk_to(scene, ottavia, Vector3(ottavia.global_position.x, 0.0, ottavia.global_position.z + 4.0), false, 6.0)
	await _walk_to(scene, ottavia, Vector3(CampTasks.FIELD_WAGON.x + 10.0, 0.0, ottavia.global_position.z), false)
	await _walk_to(scene, ottavia, CampTasks.TRASLOCANTE_SPOT + Vector3(-1.5, 0.0, 0.0), false)
	await _wait(scene, 2.5)
	for item: Breakable in tasks.breakables:
		await _defeat(scene, ottavia, item)
	print("AUTOPLAY camp breakables task=%d" % tasks.task)
	# The swarm.
	await _until(scene, func() -> bool: return tasks.task == CampTasks.Task.FIGHT, 4.0)
	await _fight(scene, ottavia, func() -> Array: return tasks.swarm, 90.0)


func _play_column(scene: Node) -> void:
	var ottavia: OttaviaProto = scene.ottavia
	await _until(scene, func() -> bool: return scene.step == scene.Step.GO_BACK and ottavia.controls_enabled, 30.0)
	# Out to Mirco through the gaps in the barriers, fighting on the way.
	for point: Vector3 in scene.ROUTE:
		await _walk_fighting(scene, ottavia, point, true)
	await _walk_to(scene, ottavia, scene.mirco.global_position + Vector3(-1.5, 0.0, 0.0), true, 30.0)
	await _until(scene, func() -> bool: return scene.step == scene.Step.FIGHT, 20.0)
	await _fight(scene, ottavia, func() -> Array: return scene.brinacchi, 60.0)
	print("AUTOPLAY column fight done step=%d" % scene.step)
	await _until(scene, func() -> bool: return scene.step == scene.Step.TIE, 3.0)
	await _walk_to(scene, ottavia, scene.mirco.global_position + Vector3(-1.2, 0.0, 0.0), false)
	await _tap(scene, &"interact")
	await _until(scene, func() -> bool: return scene.step == scene.Step.RETURN and ottavia.controls_enabled, 6.0)
	# Back the same way, then after the column, running while the breath lasts.
	var back: Array = scene.ROUTE.duplicate()
	back.reverse()
	for point: Vector3 in back:
		if scene.step != scene.Step.RETURN:
			break
		await _walk_fighting(scene, ottavia, point, ottavia.combat.stamina > ottavia.combat.max_stamina() * 0.2)
	while _alive(scene) and scene.step == scene.Step.RETURN:
		if _near_enemy(scene, ottavia) != null:
			await _fight(scene, ottavia, func() -> Array: return scene.brinacchi, 10.0)
			continue
		var target: Vector3 = Vector3(scene._last_vehicle_back(), 0.0, ottavia.global_position.z)
		_hold_toward(ottavia, target, ottavia.combat.stamina > ottavia.combat.max_stamina() * 0.2)
		await get_tree().physics_frame
	_release_all()
	print("AUTOPLAY verdict")
	await scene.prologue_finished
	print("AUTOPLAY title done")
	await _wait(scene, 2.0)
	# A sound still playing at exit counts as a leak: silence first.
	GameAudio.stop_all(0.0)
	for frame: int in 10:
		await get_tree().process_frame
	get_tree().quit()


## Walks to a point; any Brinacchi that come close are fought first.
func _walk_fighting(scene: Node, ottavia: OttaviaProto, target: Vector3, run: bool) -> void:
	for attempt: int in 6:
		if not _alive(scene):
			return
		if _near_enemy(scene, ottavia) != null:
			await _fight(scene, ottavia, func() -> Array: return scene.brinacchi, 20.0)
		await _walk_to(scene, ottavia, target, run, 25.0)
		if _near_enemy(scene, ottavia) == null:
			return


func _near_enemy(scene: Node, ottavia: OttaviaProto) -> CombatEnemy:
	for enemy: CombatEnemy in scene.brinacchi:
		if is_instance_valid(enemy) and enemy.is_alive() and enemy.global_position.distance_to(ottavia.global_position) < 7.0:
			return enemy
	return null


# --- Moves ------------------------------------------------------------------

## Walks (or runs) to `target` on the ground plane; sidesteps when stuck.
func _walk_to(scene: Node, ottavia: OttaviaProto, target: Vector3, run: bool, timeout: float = 40.0) -> void:
	var left: float = timeout
	_stuck_time = 0.0
	_last_position = ottavia.global_position
	while _alive(scene) and left > 0.0:
		var offset: Vector3 = target - ottavia.global_position
		offset.y = 0.0
		if offset.length() < ARRIVE_METERS:
			break
		var direction: Vector3 = offset.normalized()
		if _side_step > 0.0:
			direction = (direction + Vector3(-direction.z, 0.0, direction.x) * 1.5).normalized()
		_hold_toward(ottavia, ottavia.global_position + direction, run)
		await get_tree().physics_frame
		if not _alive(scene) or not ottavia.is_inside_tree():
			break
		var delta: float = get_physics_process_delta_time()
		left -= delta
		_side_step = maxf(0.0, _side_step - delta)
		if ottavia.controls_enabled and ottavia.global_position.distance_to(_last_position) < 0.02:
			_stuck_time += delta
			if _stuck_time > STUCK_SECONDS:
				_stuck_time = 0.0
				_side_step = 0.8
		else:
			_stuck_time = 0.0
		_last_position = ottavia.global_position
	_release_moves()


## Presses the move actions toward a point (analog strength per axis).
func _hold_toward(ottavia: OttaviaProto, target: Vector3, run: bool) -> void:
	var flat: Vector2 = Vector2(target.x - ottavia.global_position.x, target.z - ottavia.global_position.z)
	flat = flat.normalized() if flat.length() > 0.001 else Vector2.ZERO
	_axis(&"move_left", &"move_right", flat.x)
	_axis(&"move_up", &"move_down", flat.y)
	if run:
		Input.action_press(&"run")
	else:
		Input.action_release(&"run")


func _axis(negative: StringName, positive: StringName, value: float) -> void:
	if value > 0.05:
		Input.action_press(positive, value)
		Input.action_release(negative)
	elif value < -0.05:
		Input.action_press(negative, -value)
		Input.action_release(positive)
	else:
		Input.action_release(negative)
		Input.action_release(positive)


## Strikes `enemy` until it is down, staying close to it.
func _defeat(scene: Node, ottavia: OttaviaProto, enemy: CombatEnemy, timeout: float = 20.0) -> void:
	var left: float = timeout
	var strike_in: float = 0.0
	while _alive(scene) and is_instance_valid(enemy) and enemy.is_alive() and left > 0.0:
		var offset: Vector3 = enemy.global_position - ottavia.global_position
		offset.y = 0.0
		if offset.length() > 1.3:
			_hold_toward(ottavia, enemy.global_position, false)
		else:
			_release_moves()
			ottavia.face_toward(offset)
			if strike_in <= 0.0:
				await _tap(scene, &"attack")
				strike_in = 0.32
		await get_tree().physics_frame
		var delta: float = get_physics_process_delta_time()
		left -= delta
		strike_in -= delta
	_release_moves()


func _fight(scene: Node, ottavia: OttaviaProto, enemies: Callable, timeout: float) -> void:
	var left: float = timeout
	while _alive(scene) and left > 0.0:
		var alive: Array = (enemies.call() as Array).filter(func(enemy: CombatEnemy) -> bool: return is_instance_valid(enemy) and enemy.is_alive())
		if alive.is_empty():
			break
		alive.sort_custom(func(a: CombatEnemy, b: CombatEnemy) -> bool: return a.global_position.distance_to(ottavia.global_position) < b.global_position.distance_to(ottavia.global_position))
		var started: float = Time.get_ticks_msec() / 1000.0
		await _defeat(scene, ottavia, alive[0], 4.0)
		left -= Time.get_ticks_msec() / 1000.0 - started
	_release_all()


# --- Timing -----------------------------------------------------------------

func _tap(scene: Node, action: StringName) -> void:
	Input.action_press(action)
	await _wait(scene, 0.08)
	Input.action_release(action)
	await get_tree().physics_frame


func _wait(scene: Node, seconds: float) -> void:
	var left: float = seconds
	while _alive(scene) and left > 0.0:
		await get_tree().physics_frame
		left -= get_physics_process_delta_time()


func _until(scene: Node, condition: Callable, timeout: float) -> void:
	var left: float = timeout
	while _alive(scene) and left > 0.0 and not condition.call():
		await get_tree().physics_frame
		left -= get_physics_process_delta_time()


func _release_moves() -> void:
	for action: StringName in MOVES:
		Input.action_release(action)
	Input.action_release(&"run")


func _release_all() -> void:
	_release_moves()
	for action: StringName in [&"attack", &"jump", &"lantern", &"interact", &"parry"]:
		Input.action_release(action)
