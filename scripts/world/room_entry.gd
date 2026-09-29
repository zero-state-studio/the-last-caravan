class_name RoomEntry
extends Marker3D
## Where Ottavia appears when she enters a room through a passage, and where
## she starts again after a defeat in that room (105).

@export var entry_id: StringName
## For an entry that is not under its room (on a turning terrace, which
## carries it round): the id of the room it belongs to.
@export var room_id: StringName


func _enter_tree() -> void:
	add_to_group(&"room_entries")
