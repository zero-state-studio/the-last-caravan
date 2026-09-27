class_name Room
extends Node3D
## A room of a level: the box it covers (to know which room Ottavia is in),
## the area the camera may frame, and its entries (RoomEntry children).
## Rooms of the same level can touch: passages between them are RoomExit
## areas that belong to the place (a stair, a bridge, a gap in the plants).

@export var room_id: StringName
## Axis-aligned box centered on the node, in meters.
@export var size: Vector3 = Vector3(10.0, 4.0, 10.0)
## World X/Z rectangle the camera focus stays inside. Empty: the room box.
@export var camera_limits_rect: Rect2 = Rect2()
## Entry used when Ottavia arrives without a passage (for example a fall).
@export var default_entry: StringName


func _enter_tree() -> void:
	add_to_group(&"rooms")


func contains(point: Vector3) -> bool:
	return AABB(global_position - size * 0.5, size).has_point(point)


func camera_limits() -> Rect2:
	if camera_limits_rect.has_area():
		return camera_limits_rect
	return Rect2(Vector2(global_position.x - size.x * 0.5, global_position.z - size.z * 0.5), Vector2(size.x, size.z))


func find_entry(entry_id: StringName) -> RoomEntry:
	for node: Node in find_children("*", "RoomEntry", true, false):
		var entry: RoomEntry = node
		if entry.entry_id == entry_id:
			return entry
	return null
