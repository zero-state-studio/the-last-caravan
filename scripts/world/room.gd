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
## A room of a dungeon: the sundial of the Truce stops here (38).
@export var dungeon: bool = false
## Arriving here through a passage writes the autosave (95): the entry of
## a dungeon. `save_stage` names the point of the chapter in the save.
@export var autosave_on_enter: bool = false
@export var save_stage: StringName = &"dungeon"
## Camera distance in this room; 0 keeps the level's standard (50).
@export var camera_distance: float = 0.0


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
	if not is_inside_tree():
		return null
	for node: Node in get_tree().get_nodes_in_group(&"room_entries"):
		var entry: RoomEntry = node as RoomEntry
		if entry != null and entry.room_id == room_id and entry.entry_id == entry_id:
			return entry
	return null
