extends SceneTree
## Rooms of the diorama: the three passages (stair, bridge, gap in the
## plants), a room left by falling, camera limits, and the defeat (105):
## start again from the room entry with full health.
## Usage: godot --headless --path . --script res://tests/test_rooms.gd

var _checks: int = 0
var _failures: int = 0
var _manager: RoomManager
var _ottavia: OttaviaProto


func _initialize() -> void:
	change_scene_to_file("res://scenes/proto/diorama.tscn")
	await _wait(0.3)
	_manager = current_scene.get_node("RoomManager")
	_ottavia = current_scene.get_node("Ottavia")
	_check(_manager.current_room != null and _manager.current_room.room_id == &"prato", "starts in the meadow room")

	await _through(Vector3(-7.5, 1.0, -2.2), &"terrazza", Vector3(-7.5, 3.0, -5.9), "stair")
	var rig: FollowCameraRig = current_scene.get_node("CameraRig")
	_check(rig.limits == _manager.current_room.camera_limits(), "camera limits follow the room")

	_ottavia.take_damage(_ottavia.max_health * 2.0)
	await _wait(1.6)
	_check(is_equal_approx(_ottavia.health, _ottavia.max_health), "defeat: health is full again")
	_check(_flat_distance(_ottavia.global_position, Vector3(-7.5, 3.0, -5.9)) < 0.6, "defeat: back at the entry of the room (got %s)" % _ottavia.global_position)
	_check(_ottavia.controls_enabled, "defeat: controls back on")

	await _through(Vector3(-1.2, 3.2, -10.0), &"piattaforma", Vector3(5.6, 3.0, -10.0), "bridge")
	await _through(Vector3(13.0, 3.4, -5.4), &"prato", Vector3(13.0, 0.0, 0.8), "gap in the plants")

	_ottavia.global_position = Vector3(6.5, 3.05, -10.0)
	await _wait(0.2)
	_check(_manager.current_room.room_id == &"piattaforma", "moved onto the platform without a passage")
	_ottavia.global_position = Vector3(6.5, 0.05, -3.0)
	await _wait(0.2)
	_check(_manager.current_room.room_id == &"prato", "a fall from the platform lands in the meadow room")
	_check(_flat_distance(_manager.respawn_position, Vector3(-1.5, 0.0, -3.0)) < 0.01, "after a fall the respawn is the room's default entry")

	print("TESTS: rooms %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _through(start: Vector3, room_id: StringName, entry: Vector3, passage: String) -> void:
	_ottavia.global_position = start
	await _wait(0.9)
	_check(_manager.current_room.room_id == room_id, "%s: now in room %s (got %s)" % [passage, room_id, _manager.current_room.room_id])
	_check(_flat_distance(_ottavia.global_position, entry) < 0.6 and absf(_ottavia.global_position.y - entry.y) < 0.4, "%s: at the entry (got %s)" % [passage, _ottavia.global_position])


func _wait(seconds: float) -> void:
	await create_timer(seconds, true, true).timeout


func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		print("FAIL: " + message)
