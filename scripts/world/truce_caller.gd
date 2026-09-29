class_name TruceCaller
extends Node3D
## Someone who runs to Ottavia when the Truce runs out (chapter 1: Iole,
## section 3): they appear a few metres away, run up to her and stop; the
## level then plays their lines and takes Ottavia into the dungeon.
## Ottavia waits, without controls, while they come.

signal arrived

@export var sprite_texture: Texture2D
@export var walk_texture: Texture2D
@export var run_speed: float = 4.0
## Where they appear, from Ottavia, and how close they stop.
@export var start_offset: Vector3 = Vector3(-9.0, 0.0, 3.0)
@export var stop_distance: float = 1.3

var sprite: NpcSprite
var _running: bool = false
var _target: OttaviaProto


func _ready() -> void:
	sprite = NpcSprite.new()
	sprite.sprite_texture = sprite_texture
	add_child(sprite)
	visible = false


func call_player(ottavia: OttaviaProto) -> void:
	_target = ottavia
	ottavia.controls_enabled = false
	global_position = ottavia.global_position + start_offset
	visible = true
	if walk_texture != null:
		sprite.set_strip(walk_texture, 10.0)
	_running = true


func is_running() -> bool:
	return _running


func _physics_process(delta: float) -> void:
	if not _running or _target == null:
		return
	var goal: Vector3 = _target.global_position
	var offset: Vector3 = goal - global_position
	offset.y = 0.0
	if offset.length() <= stop_distance:
		_running = false
		if sprite_texture != null:
			sprite.set_strip(sprite_texture, sprite.frames_per_second)
		_target.face_toward(-offset)
		arrived.emit()
		return
	global_position += offset.normalized() * minf(run_speed * delta, offset.length() - stop_distance + 0.01)
	global_position.y = goal.y
