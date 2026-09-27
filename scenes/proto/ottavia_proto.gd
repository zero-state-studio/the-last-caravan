class_name OttaviaProto
extends CharacterBody3D
## Provisional Ottavia for the visual prototype (19, 49).
## Uses source-assets/test/ottavia_test_sheet.png: 40x56 frames ordered
## south 1, south 2, east 1, east 2, north 1, north 2, west 1, west 2.

const FRAMES_PER_VIEW: int = 2
const IDLE_FRAME_TIME: float = 0.5
const WALK_FRAME_TIME: float = 0.18
## Height of the drawn body in pixels (head to feet, staff excluded).
const BODY_HEIGHT_PIXELS: float = 42.0

@export var move_speed: float = 3.0
@export var gravity: float = 20.0
## Yaw of the camera, so "up" on the stick always means "away from the camera".
@export var camera_yaw_degrees: float = 0.0

@onready var sprite: Sprite3D = $Sprite3D

var _facing: Facing.Cardinal = Facing.Cardinal.SOUTH
var _frame_timer: float = 0.0
var _frame_step: int = 0


func _physics_process(delta: float) -> void:
	var input: Vector2 = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var direction: Vector3 = Vector3(input.x, 0.0, input.y).rotated(Vector3.UP, deg_to_rad(camera_yaw_degrees))
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= gravity * delta
	move_and_slide()
	_facing = Facing.nearest_cardinal(input, _facing)
	_animate(delta, not input.is_zero_approx())


func set_billboard_fixed_y(fixed_y: bool) -> void:
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y if fixed_y else BaseMaterial3D.BILLBOARD_ENABLED


func set_pixel_size(pixel_size: float) -> void:
	sprite.pixel_size = pixel_size


func set_shaded(shaded: bool) -> void:
	sprite.shaded = shaded


func _animate(delta: float, moving: bool) -> void:
	var frame_time: float = WALK_FRAME_TIME if moving else IDLE_FRAME_TIME
	_frame_timer += delta
	if _frame_timer >= frame_time:
		_frame_timer = fmod(_frame_timer, frame_time)
		_frame_step = (_frame_step + 1) % FRAMES_PER_VIEW
	sprite.frame = int(_facing) * FRAMES_PER_VIEW + _frame_step
