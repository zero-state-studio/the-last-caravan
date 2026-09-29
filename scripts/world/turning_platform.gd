class_name TurningPlatform
extends StaticBody3D
## A terrace on a turntable (chapter 1, section 4): every pull of its lever
## turns it a quarter clockwise, seen from above, in about 1.5 seconds. Its
## children (plants, fences, crates, ramps) turn with it; the bodies
## standing on it (Ottavia, creatures) are carried too, and told the angle
## at the end so they can face the new way (Day beasts turn back to the
## sun, 36). The carried creatures' start points turn as well, so a room
## restart (105) puts them back on the terrace where it is now.
## A StaticBody3D moved by code: bodies on it take no platform velocity,
## the carrying is done here, exactly once.

signal turn_started(quarter: int)
signal turn_finished(quarter: int)

## Clockwise from above is a negative turn around +Y.
const QUARTER: float = -PI * 0.5

@export var tuning: ChapterTuning
## Box above the platform, in its local space, whose bodies are carried.
@export var carry_size: Vector3 = Vector3(10.0, 3.0, 10.0)
@export var carry_offset: Vector3 = Vector3(0.0, 1.5, 0.0)
## Quarter turns done at the start (the level's starting layout).
@export var start_quarter: int = 0

## Quarter turns done so far, 0-3.
var quarter: int = 0
var turning: bool = false
var _from_yaw: float = 0.0
var _to_yaw: float = 0.0
var _elapsed: float = 0.0
var _base_yaw: float = 0.0


func _ready() -> void:
	add_to_group(&"turning_platforms")
	if tuning == null:
		tuning = ChapterTuning.new()
	_base_yaw = rotation.y
	set_quarter(start_quarter)


func turn_seconds() -> float:
	return tuning.platform_turn_seconds


## Starts a quarter turn; false while one is already running.
func turn() -> bool:
	if turning:
		return false
	turning = true
	_elapsed = 0.0
	_from_yaw = rotation.y
	_to_yaw = _from_yaw + QUARTER
	turn_started.emit((quarter + 1) % 4)
	return true


## Sets the layout at once, without carrying anything (level start, load).
func set_quarter(new_quarter: int) -> void:
	quarter = posmod(new_quarter, 4)
	turning = false
	rotation.y = _base_yaw + QUARTER * quarter


func _physics_process(delta: float) -> void:
	if not turning:
		return
	_elapsed = minf(_elapsed + delta, turn_seconds())
	var weight: float = smoothstep(0.0, 1.0, _elapsed / maxf(turn_seconds(), 0.01))
	var yaw: float = lerpf(_from_yaw, _to_yaw, weight)
	var step: float = yaw - rotation.y
	var carried: Array[Node3D] = _carried_bodies()
	var pivot: Vector3 = global_position
	rotation.y = yaw
	for body: Node3D in carried:
		body.global_position = pivot + (body.global_position - pivot).rotated(Vector3.UP, step)
		var enemy: CombatEnemy = body as CombatEnemy
		if enemy != null:
			var spawn: Transform3D = enemy.spawn_transform
			spawn.origin = pivot + (spawn.origin - pivot).rotated(Vector3.UP, step)
			spawn.basis = spawn.basis.rotated(Vector3.UP, step)
			enemy.spawn_transform = spawn
	if _elapsed >= turn_seconds():
		turning = false
		quarter = (quarter + 1) % 4
		for body: Node3D in carried:
			if body.has_method(&"carried_turned"):
				body.call(&"carried_turned", QUARTER)
		turn_finished.emit(quarter)


## Ottavia, companions and creatures standing inside the carry box.
func _carried_bodies() -> Array[Node3D]:
	var result: Array[Node3D] = []
	var candidates: Array[Node] = get_tree().get_nodes_in_group(&"player")
	candidates.append_array(get_tree().get_nodes_in_group(&"combat_targets"))
	candidates.append_array(get_tree().get_nodes_in_group(&"carriable"))
	for node: Node in candidates:
		var body: Node3D = node as Node3D
		if body != null and not body in result and not is_ancestor_of(body) and carries(body.global_position):
			result.append(body)
	return result


func carries(point: Vector3) -> bool:
	var local: Vector3 = global_transform.affine_inverse() * point - carry_offset
	return absf(local.x) <= carry_size.x * 0.5 and absf(local.y) <= carry_size.y * 0.5 and absf(local.z) <= carry_size.z * 0.5
