class_name ClimbSpot
extends Area3D
## A wall with handholds (33): pushing the stick against it for a moment,
## Ottavia climbs automatically and steps over onto `top` (world point).
## The jump stays on its own button.

signal climbed

## Where Ottavia ends up, on top of the ledge.
@export var top: Vector3 = Vector3.ZERO
## Outward normal of the wall (horizontal): she must push against it.
@export var wall_normal: Vector3 = Vector3.BACK
@export var push_seconds: float = 0.18

var _push: float = 0.0


func _physics_process(delta: float) -> void:
	var ottavia: OttaviaProto = get_tree().get_first_node_in_group(&"player") as OttaviaProto
	if ottavia == null or not ottavia.controls_enabled or ottavia.is_climbing() or not overlaps_body(ottavia):
		_push = 0.0
		return
	var input: Vector2 = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var toward: Vector3 = Vector3(input.x, 0.0, input.y)
	if toward.length() > 0.3 and toward.normalized().dot(-wall_normal) > 0.6:
		_push += delta
	else:
		_push = 0.0
	if _push >= push_seconds:
		_push = 0.0
		climb(ottavia)


func climb(ottavia: OttaviaProto) -> void:
	await ottavia.climb_to(top, wall_normal)
	climbed.emit()


static func create(parent: Node3D, at: Vector3, size: Vector3, top_point: Vector3, normal: Vector3) -> ClimbSpot:
	var spot: ClimbSpot = ClimbSpot.new()
	spot.top = top_point
	spot.wall_normal = normal
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	shape.shape = box
	spot.add_child(shape)
	spot.position = at
	parent.add_child(spot)
	return spot
