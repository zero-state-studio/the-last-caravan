class_name RoomExit
extends Area3D
## A passage out of a room. When Ottavia walks into it, the RoomManager fades
## out, moves her to `target_entry` of `target_room` and fades back in.
## The target entry must lie outside every exit of the target room.

@export var target_room: StringName
@export var target_entry: StringName


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not body is OttaviaProto:
		return
	var manager: RoomManager = get_tree().get_first_node_in_group(&"room_manager") as RoomManager
	if manager != null:
		manager.use_exit(self)
