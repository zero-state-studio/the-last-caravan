class_name GatedExit
extends RoomExit
## A passage that works only while its `gate` says so: a ramp turned the
## right way, a bridge lowered, a shortcut opened (chapter 1). Standing on
## it when it opens also takes Ottavia through.

## Returns true when the passage can be used; empty: always.
var gate: Callable = Callable()


func is_open() -> bool:
	return not gate.is_valid() or bool(gate.call())


func _on_body_entered(body: Node3D) -> void:
	if is_open():
		super._on_body_entered(body)


func _physics_process(_delta: float) -> void:
	if not monitoring or not is_open():
		return
	var ottavia: OttaviaProto = get_tree().get_first_node_in_group(&"player") as OttaviaProto
	if ottavia == null or not ottavia.controls_enabled or not overlaps_body(ottavia):
		return
	var manager: RoomManager = get_tree().get_first_node_in_group(&"room_manager") as RoomManager
	if manager != null and not manager.is_busy():
		manager.use_exit(self)
