class_name OttaviaProto
extends CharacterBody3D
## Provisional Ottavia for the visual prototype (19, 49).
## Uses assets/sprites/ottavia/ottavia_v1_sheet.png: 64x64 cells, 8 frames per
## row, rows idle_s..idle_sw then walk_s..walk_sw (see ottavia_v1_sheet.md).

const FRAMES_PER_ROW: int = 8
const WALK_ROW_OFFSET: int = 8
const IDLE_FRAME_TIME: float = 0.16
const WALK_FRAME_TIME: float = 0.1
## Where the lit sprite samples light and shadow: chest height, a bit toward the sun.
const LIGHT_SAMPLE_HEIGHT: float = 0.9
const LIGHT_SAMPLE_TOWARD_SUN: float = 0.4
## Frame data with the lantern point of every frame (see tools/lantern_mask.lua).
const SHEET_DATA: JSON = preload("res://assets/sprites/ottavia/ottavia_v1_sheet.json")
const EMISSION_MASK: Texture2D = preload("res://assets/sprites/ottavia/ottavia_v1_emission.png")
const CELL_PIXELS: float = 64.0
const UNSHADED_SHADER: Shader = preload("res://scenes/proto/materials/sprite_billboard_unshaded.gdshader")
const LIT_SHADER: Shader = preload("res://scenes/proto/materials/sprite_billboard_lit.gdshader")

signal defeated

## Health and speed come from the combat tuning (see OttaviaCombat).
var max_health: float = 100.0
@export var gravity: float = 20.0
## Yaw of the camera, so "up" on the stick always means "away from the camera".
@export var camera_yaw_degrees: float = 0.0

@onready var sprite: Sprite3D = $Sprite3D
## Invisible upright copy that only casts the shadow, turned toward the sun,
## so the shadow is never the one of a leaning billboard.
@onready var shadow_proxy: Sprite3D = $ShadowProxy
## Small real light that follows the lantern (19): the only light in the
## Night (45), and the one whose shadows matter to B15 and to the creatures
## drawn to light (36).
@onready var lantern_light: OmniLight3D = $LanternLight
@onready var combat: OttaviaCombat = $Combat

## Brightness of the lantern glass (emission mask), feeding the scene glow.
@export var lantern_glass_energy: float = 2.5

var _material: ShaderMaterial = ShaderMaterial.new()
var _facing: Facing.Direction = Facing.Direction.SOUTH
var _frame_timer: float = 0.0
var _frame: int = 0
var _moving: bool = false
## False during room transitions and cutscenes: input is ignored.
var controls_enabled: bool = true
var health: float = 0.0
var _lantern_points: PackedVector2Array = []
var _dark_areas: int = 0
var _forced_lantern_shadows: int = -1
var lantern_open: bool = true
var _lantern_base_range: float = 5.0
var _lantern_base_energy: float = 1.5
var _flash: float = 0.0
var _flash_color: Color = Color.WHITE


func _ready() -> void:
	add_to_group(&"player")
	max_health = combat.tuning.max_health
	health = max_health
	_lantern_base_range = lantern_light.omni_range
	_lantern_base_energy = lantern_light.light_energy
	_material.shader = UNSHADED_SHADER
	_material.set_shader_parameter(&"sprite_texture", sprite.texture)
	_material.set_shader_parameter(&"emission_mask", EMISSION_MASK)
	_material.set_shader_parameter(&"emission_energy", lantern_glass_energy)
	sprite.material_override = _material
	_lantern_points = lantern_points_from(SHEET_DATA.data)
	_update_lantern_shadows()
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shadow_proxy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY


func _physics_process(delta: float) -> void:
	var input: Vector2 = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down") if controls_enabled else Vector2.ZERO
	combat.physics_update(delta, input, controls_enabled)
	if controls_enabled and Input.is_action_just_pressed(&"interact"):
		interact()
	var direction: Vector3 = Vector3(input.x, 0.0, input.y).rotated(Vector3.UP, deg_to_rad(camera_yaw_degrees))
	var speed: float = combat.tuning.move_speed * combat.move_speed_multiplier()
	var forced: Vector3 = combat.forced_velocity()
	velocity.x = direction.x * speed + forced.x
	velocity.z = direction.z * speed + forced.z
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= gravity * delta
	move_and_slide()
	if combat.can_turn():
		_facing = Facing.nearest_direction(input, _facing)
	_animate(delta, not input.is_zero_approx() and combat.move_speed_multiplier() > 0.0)
	_update_flash(delta)


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
## The lighting sample point moves toward the sun, in front of the proxy.
func set_sun_azimuth(degrees: float) -> void:
	var azimuth: float = deg_to_rad(degrees)
	shadow_proxy.global_rotation = Vector3(0.0, azimuth, 0.0)
	var toward_sun: Vector3 = Vector3(sin(azimuth), 0.0, cos(azimuth))
	_material.set_shader_parameter(&"light_sample_offset", Vector3.UP * LIGHT_SAMPLE_HEIGHT + toward_sun * LIGHT_SAMPLE_TOWARD_SUN)


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
	_update_lantern_light()


## Lantern points (cell pixels) of every frame, in sheet order.
static func lantern_points_from(data: Dictionary) -> PackedVector2Array:
	var points: PackedVector2Array = []
	for frame: Dictionary in data["frames"]:
		var lantern: Dictionary = frame["lantern"]
		points.append(Vector2(float(lantern["x"]), float(lantern["y"])))
	return points


## World offset of a lantern point from the feet, on the upright plane that
## faces the camera: the light stays where the lantern is drawn, at its real
## height, whatever the direction and frame.
static func lantern_offset(point: Vector2, pixel_size: float, sprite_offset_y: float, camera_right: Vector3) -> Vector3:
	var right: Vector3 = Vector3(camera_right.x, 0.0, camera_right.z).normalized()
	var across: float = (point.x - CELL_PIXELS * 0.5) * pixel_size
	var up: float = (CELL_PIXELS * 0.5 - point.y + sprite_offset_y) * pixel_size
	return right * across + Vector3.UP * up


## Called by DarkArea: the lantern casts shadows only where it is dark, to
## stay cheap in daylight (Steam Deck, 7).
func enter_dark_area() -> void:
	_dark_areas += 1
	_update_lantern_shadows()


func exit_dark_area() -> void:
	_dark_areas = maxi(0, _dark_areas - 1)
	_update_lantern_shadows()


## Debug override for measurements: 1 on, 0 off, -1 follow the dark areas.
func force_lantern_shadows(mode: int) -> void:
	_forced_lantern_shadows = mode
	_update_lantern_shadows()


func _update_lantern_shadows() -> void:
	var enabled: bool = _dark_areas > 0 if _forced_lantern_shadows < 0 else _forced_lantern_shadows == 1
	lantern_light.shadow_enabled = enabled


func _update_lantern_light() -> void:
	if _lantern_points.is_empty():
		return
	var camera: Camera3D = get_viewport().get_camera_3d()
	var camera_right: Vector3 = camera.global_basis.x if camera != null else Vector3.RIGHT
	var offset: Vector3 = lantern_offset(_lantern_points[sprite.frame], sprite.pixel_size, sprite.offset.y, camera_right)
	lantern_light.global_position = global_position + offset


## Damage from creatures; at zero health Ottavia is defeated (105).
func take_damage(amount: float) -> void:
	if health <= 0.0:
		return
	health = maxf(0.0, health - amount)
	if health <= 0.0:
		defeated.emit()


func restore_health() -> void:
	health = max_health
	combat.reset()


## Uses the nearest interactable within its radius (levers, doors...).
func interact() -> bool:
	var best: Interactable = null
	var best_distance: float = INF
	for node: Node in get_tree().get_nodes_in_group(&"interactables"):
		var item: Interactable = node as Interactable
		if item == null or not item.can_use():
			continue
		var distance: float = Vector2(item.global_position.x - global_position.x, item.global_position.z - global_position.z).length()
		if distance <= item.radius and distance < best_distance:
			best = item
			best_distance = distance
	if best == null:
		return false
	best.use()
	return true


## Horizontal world direction Ottavia is facing (one of the eight views).
func facing_vector() -> Vector3:
	return Facing.to_world(_facing)


func face_toward(direction: Vector3) -> void:
	_facing = Facing.nearest_direction(Vector2(direction.x, direction.z), _facing)


func flash(amount: float, color: Color) -> void:
	_flash = maxf(_flash, amount * HitFeedback.flash_scale)
	_flash_color = color


## Lantern shutter (33): closed, the glass goes dark and the light is off.
func set_lantern_open(open: bool) -> void:
	lantern_open = open
	lantern_light.visible = open
	_material.set_shader_parameter(&"emission_energy", lantern_glass_energy if open else 0.0)


## Raised lantern (33): lights farther while the button is held.
func set_lantern_raised(raised: bool) -> void:
	var tuning: CombatTuning = combat.tuning
	lantern_light.omni_range = _lantern_base_range * (tuning.lantern_raised_range_multiplier if raised else 1.0)
	lantern_light.light_energy = _lantern_base_energy * (1.3 if raised else 1.0)


## Hit flash, plus a faint tint while parrying (pale) or breathless (blue).
func _update_flash(delta: float) -> void:
	_flash = maxf(0.0, _flash - 8.0 * delta)
	var amount: float = _flash
	var color: Color = _flash_color
	if _flash <= 0.05:
		if combat.state == OttaviaCombat.State.PARRY:
			amount = 0.15 * HitFeedback.flash_scale
			color = Color(0.85, 0.92, 1.0)
		elif combat.state == OttaviaCombat.State.BREATHLESS:
			amount = (0.25 + 0.15 * sin(Time.get_ticks_msec() * 0.02)) * HitFeedback.flash_scale
			color = Color(0.45, 0.55, 1.0)
	_material.set_shader_parameter(&"flash", amount)
	_material.set_shader_parameter(&"flash_color", color)
