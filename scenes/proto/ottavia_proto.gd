class_name OttaviaProto
extends CharacterBody3D
## Provisional Ottavia for the visual prototype (19, 49).
## Uses assets/sprites/ottavia/ottavia_v1_sheet.png: 64x64 cells, 8 frames per
## row, rows idle_s..idle_sw then walk_s..walk_sw (see ottavia_v1_sheet.md).

const FRAMES_PER_ROW: int = 8
const WALK_ROW_OFFSET: int = 8
const IDLE_FRAME_TIME: float = 0.16
const WALK_FRAME_TIME: float = 0.1
const UNSHADED_SHADER: Shader = preload("res://scenes/proto/materials/sprite_billboard_unshaded.gdshader")
const LIT_SHADER: Shader = preload("res://scenes/proto/materials/sprite_billboard_lit.gdshader")

@export var move_speed: float = 3.0
@export var gravity: float = 20.0
## Yaw of the camera, so "up" on the stick always means "away from the camera".
@export var camera_yaw_degrees: float = 0.0

@onready var sprite: Sprite3D = $Sprite3D
## Invisible upright copy that only casts the shadow, turned toward the sun,
## so the shadow is never the one of a leaning billboard.
@onready var shadow_proxy: Sprite3D = $ShadowProxy

var _material: ShaderMaterial = ShaderMaterial.new()
var _facing: Facing.Direction = Facing.Direction.SOUTH
var _frame_timer: float = 0.0
var _frame: int = 0
var _moving: bool = false


func _ready() -> void:
	_material.shader = UNSHADED_SHADER
	_material.set_shader_parameter(&"sprite_texture", sprite.texture)
	sprite.material_override = _material
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shadow_proxy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY


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
	_facing = Facing.nearest_direction(input, _facing)
	_animate(delta, not input.is_zero_approx())


func set_billboard_fixed_y(fixed_y: bool) -> void:
	_material.set_shader_parameter(&"full_billboard", not fixed_y)


func set_upright_depth(enabled: bool) -> void:
	_material.set_shader_parameter(&"upright_depth", enabled)


func set_pixel_size(pixel_size: float) -> void:
	sprite.pixel_size = pixel_size
	shadow_proxy.pixel_size = pixel_size


func set_shaded(shaded: bool) -> void:
	_material.shader = LIT_SHADER if shaded else UNSHADED_SHADER


## The shadow proxy faces the sun horizontally; see diorama.gd for the angle.
func set_sun_azimuth(degrees: float) -> void:
	shadow_proxy.global_rotation = Vector3(0.0, deg_to_rad(degrees), 0.0)


func _animate(delta: float, moving: bool) -> void:
	if moving != _moving:
		_moving = moving
		_frame = 0
		_frame_timer = 0.0
	var frame_time: float = WALK_FRAME_TIME if moving else IDLE_FRAME_TIME
	_frame_timer += delta
	while _frame_timer >= frame_time:
		_frame_timer -= frame_time
		_frame = (_frame + 1) % FRAMES_PER_ROW
	var row: int = int(_facing) + (WALK_ROW_OFFSET if moving else 0)
	sprite.frame = row * FRAMES_PER_ROW + _frame
	shadow_proxy.frame = sprite.frame
