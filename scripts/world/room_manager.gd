class_name RoomManager
extends Node
## Rooms of a level and what happens between them: passages with a fade,
## the entry position, the camera limits of each room, and the defeat (105):
## if Ottavia falls, she starts again from the entry of the room with full
## health.

signal room_changed(room: Room)
signal player_respawned(room: Room)
## Emitted during the black screen of a restart, after the creatures of the
## room are back at their start (arenas reset their mechanics here).
signal room_restarted(room: Room)
## Ottavia fell out of the room into the void and is back at its entry.
signal player_fell(room: Room)

## Below the bottom of the current room by this much, Ottavia has fallen.
const FALL_MARGIN: float = 1.0

## Paths, not typed node exports: hand-written paths in a .tscn do not
## resolve into typed node exports (see docs/tecnica.md).
@export var player_path: NodePath
@export var camera_rig_path: NodePath
@export var fade_seconds: float = 0.25
@export var defeat_fade_seconds: float = 0.6

var player: OttaviaProto
var camera_rig: FollowCameraRig
var current_room: Room
var respawn_position: Vector3 = Vector3.ZERO

var _busy: bool = false
var _fade: ColorRect
var _standard_distance: float = -1.0


func _enter_tree() -> void:
	add_to_group(&"room_manager")


func _ready() -> void:
	player = get_node(player_path) as OttaviaProto
	camera_rig = get_node(camera_rig_path) as FollowCameraRig
	player.defeated.connect(_on_player_defeated)
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0.0, 0.0, 0.0, 0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)
	# The level sets the start position in its own _ready, after this one.
	_update_room.call_deferred()


func rooms() -> Array[Room]:
	var result: Array[Room] = []
	for node: Node in get_tree().get_nodes_in_group(&"rooms"):
		result.append(node as Room)
	return result


func find_room(room_id: StringName) -> Room:
	for room: Room in rooms():
		if room.room_id == room_id:
			return room
	return null


func is_busy() -> bool:
	return _busy


func use_exit(exit: RoomExit) -> void:
	if _busy:
		return
	travel(exit.target_room, exit.target_entry)


## Fade out, move Ottavia to the entry, switch room and camera limits, fade in.
func travel(room_id: StringName, entry_id: StringName) -> void:
	var room: Room = find_room(room_id)
	var entry: RoomEntry = room.find_entry(entry_id) if room != null else null
	if entry == null:
		push_warning("RoomManager: no entry %s in room %s" % [entry_id, room_id])
		return
	_busy = true
	player.controls_enabled = false
	await _fade_to(1.0, fade_seconds)
	_place_player(entry.global_position)
	_set_room(room, entry.global_position)
	if room.autosave_on_enter:
		SaveGame.autosave(get_tree(), room.room_id, entry_id, room.save_stage)
	await _fade_to(0.0, fade_seconds)
	player.controls_enabled = true
	_busy = false


func _physics_process(_delta: float) -> void:
	if not _busy:
		_update_room()
		_check_fall()


## A fall off a terrace into the void below every room: back to the entry
## of the room, with no damage (105 without the defeat).
func _check_fall() -> void:
	if current_room == null or current_room.contains(player.global_position) or player.is_on_floor():
		return
	var bottom: float = current_room.global_position.y - current_room.size.y * 0.5
	if player.global_position.y < bottom - FALL_MARGIN:
		_fall_back()


func _fall_back() -> void:
	_busy = true
	player.controls_enabled = false
	await _fade_to(1.0, fade_seconds)
	_place_player(respawn_position)
	await _fade_to(0.0, fade_seconds)
	player.controls_enabled = true
	_busy = false
	player_fell.emit(current_room)


## After «Continue» (95): Ottavia at the saved entry, without a fade.
## False when the room or the entry does not exist any more.
func restore_checkpoint(checkpoint: Dictionary) -> bool:
	var room: Room = find_room(StringName(str(checkpoint.get("room", ""))))
	var entry: RoomEntry = room.find_entry(StringName(str(checkpoint.get("entry", "")))) if room != null else null
	if entry == null:
		return false
	_place_player(entry.global_position)
	_set_room(room, entry.global_position)
	return true


## Rooms can be left without a passage (a fall from the platform): follow
## Ottavia into the room that now contains her, without a fade.
func _update_room() -> void:
	var position: Vector3 = player.global_position
	if current_room != null and current_room.contains(position):
		return
	for room: Room in rooms():
		if room.contains(position):
			var entry: RoomEntry = room.find_entry(room.default_entry)
			_set_room(room, entry.global_position if entry != null else position)
			return


func _set_room(room: Room, entry_position: Vector3) -> void:
	current_room = room
	respawn_position = entry_position
	camera_rig.limits = room.camera_limits()
	if _standard_distance < 0.0:
		_standard_distance = camera_rig.distance
	var distance: float = room.camera_distance if room.camera_distance > 0.0 else _standard_distance
	if not is_equal_approx(distance, camera_rig.distance):
		camera_rig.distance = distance
		camera_rig.apply()
	room_changed.emit(room)


func _on_player_defeated() -> void:
	if _busy:
		return
	_busy = true
	player.controls_enabled = false
	await _fade_to(1.0, defeat_fade_seconds)
	_place_player(respawn_position)
	player.restore_health()
	reset_room_enemies(current_room)
	room_restarted.emit(current_room)
	await _fade_to(0.0, defeat_fade_seconds)
	player.controls_enabled = true
	_busy = false
	player_respawned.emit(current_room)


## Every creature that started in `room` goes back to its start (105).
func reset_room_enemies(room: Room) -> void:
	if room == null:
		return
	for node: Node in get_tree().get_nodes_in_group(&"combat_targets"):
		var enemy: CombatEnemy = node as CombatEnemy
		if enemy != null and room.contains(enemy.spawn_transform.origin + Vector3.UP * 0.5):
			enemy.reset_enemy()


func _place_player(position: Vector3) -> void:
	player.global_position = position
	player.velocity = Vector3.ZERO
	camera_rig.snap_to_target()


func _fade_to(alpha: float, seconds: float) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_fade, "color:a", alpha, seconds)
	await tween.finished
