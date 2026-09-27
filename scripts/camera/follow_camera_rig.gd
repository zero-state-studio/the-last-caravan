class_name FollowCameraRig
extends Node3D
## Camera that follows a target with a fixed orientation (50).
## Sprites are flat, so the yaw never changes at runtime; only pitch,
## distance, field of view and projection are tunable.

@export var target: Node3D
@export_range(30.0, 70.0, 0.5) var pitch_degrees: float = 50.0
@export_range(4.0, 60.0, 0.1) var distance: float = 14.0
@export_range(5.0, 90.0, 0.5) var fov_degrees: float = 35.0
@export var orthographic: bool = false
@export var yaw_degrees: float = 0.0
## Height above the target origin the camera looks at (roughly the chest).
@export var look_height: float = 0.8
## Higher is snappier; 0 disables smoothing.
@export var follow_speed: float = 8.0
@export_group("Depth of field")
## Distance in front of the focus point where the near blur ends.
@export var dof_near_offset: float = 6.0
## Distance behind the focus point where the far blur starts.
@export var dof_far_offset: float = 8.0
@export var dof_near_enabled: bool = true
@export var dof_far_enabled: bool = true
@export_range(0.0, 1.0, 0.01) var dof_amount: float = 0.1

@onready var camera: Camera3D = $Camera3D

var _focus: Vector3 = Vector3.ZERO


func _ready() -> void:
	if target != null:
		_focus = _target_point()
	apply()


func _process(delta: float) -> void:
	if target == null:
		return
	var goal: Vector3 = _target_point()
	if follow_speed <= 0.0:
		_focus = goal
	else:
		_focus = _focus.lerp(goal, 1.0 - exp(-follow_speed * delta))
	_place_camera()


## Re-applies every tunable value; call after changing exported properties.
func apply() -> void:
	camera.fov = fov_degrees
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL if orthographic else Camera3D.PROJECTION_PERSPECTIVE
	# Keep the same framing at the focus distance when switching projection.
	camera.size = 2.0 * distance * tan(deg_to_rad(fov_degrees) * 0.5)
	var attributes: CameraAttributesPractical = camera.attributes as CameraAttributesPractical
	if attributes == null:
		attributes = CameraAttributesPractical.new()
		camera.attributes = attributes
	attributes.dof_blur_near_enabled = dof_near_enabled
	attributes.dof_blur_far_enabled = dof_far_enabled
	attributes.dof_blur_amount = dof_amount
	var near_end: float = maxf(0.1, distance - dof_near_offset)
	attributes.dof_blur_near_distance = near_end
	attributes.dof_blur_near_transition = near_end * 0.5
	attributes.dof_blur_far_distance = distance + dof_far_offset
	attributes.dof_blur_far_transition = maxf(1.0, dof_far_offset)
	_place_camera()


func snap_to_target() -> void:
	if target != null:
		_focus = _target_point()
	_place_camera()


func _target_point() -> Vector3:
	return target.global_position + Vector3.UP * look_height


func _place_camera() -> void:
	var pitch: float = deg_to_rad(pitch_degrees)
	var offset: Vector3 = Vector3(0.0, sin(pitch), cos(pitch)) * distance
	offset = offset.rotated(Vector3.UP, deg_to_rad(yaw_degrees))
	camera.global_position = _focus + offset
	camera.look_at(_focus, Vector3.UP)
