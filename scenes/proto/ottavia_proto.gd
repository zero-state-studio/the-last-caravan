class_name OttaviaProto
extends CharacterBody3D
## Ottavia (19, 49). Uses assets/sprites/ottavia/ottavia_v2_sheet.png: 64x64
## cells, COLUMNS per row, one row per animation and direction, listed in
## ottavia_v2_sheet.json ("animations": row, frames, ms, loop), built by
## tools/ottavia_sheet_v2.py.

const COLUMNS: int = 12
## Animations drawn in two directions only (south, west): the others use the
## nearer of the two.
const TWO_WAY: Array[String] = ["tie_rope", "give_hand"]
const CLIMB_UP_SECONDS: float = 1.0
const CLIMB_OVER_SECONDS: float = 0.35
const LANDING_SECONDS: float = 0.18
## One footstep sound every this many metres walked (a run takes longer
## strides).
const STEP_METERS: float = 0.8
const FLAME_HUM_DB: float = -22.0
## Where the lit sprite samples light and shadow: chest height, a bit toward the sun.
const LIGHT_SAMPLE_HEIGHT: float = 0.9
const LIGHT_SAMPLE_TOWARD_SUN: float = 0.4
## Frame data with the lantern point of every frame (see tools/lantern_mask.lua).
const SHEET_DATA: JSON = preload("res://assets/sprites/ottavia/ottavia_v2_sheet.json")
const EMISSION_MASK: Texture2D = preload("res://assets/sprites/ottavia/ottavia_v2_emission.png")
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
var _animations: Dictionary = {}
var _animation: String = ""
var _animation_time: float = 0.0
## A one-off action played by a scene (tying the rope, giving the hand).
var _scripted: String = ""
var _climbing: bool = false
var _was_airborne: bool = false
var _landing_left: float = 0.0
## Height of the ground last stood on: the camera stays there during a jump.
var _ground_y: float = 0.0
## False during room transitions and cutscenes: input is ignored.
var controls_enabled: bool = true
## During cutscenes: Ottavia walks at this velocity (for example with the
## column on the march), animated as walking.
var auto_move: Vector3 = Vector3.ZERO
## Footstep effect for the ground under her (127): set by each scene, empty
## for silence.
var footstep_sound: StringName = &""
var _step_distance: float = 0.0
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
	_animations = SHEET_DATA.data["animations"]
	_update_lantern_shadows()
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shadow_proxy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY


func _physics_process(delta: float) -> void:
	if _climbing:
		_animate(delta, false)
		return
	var input: Vector2 = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down") if controls_enabled else Vector2.ZERO
	combat.physics_update(delta, input, controls_enabled)
	if controls_enabled and Input.is_action_just_pressed(&"interact"):
		interact()
	var direction: Vector3 = Vector3(input.x, 0.0, input.y).rotated(Vector3.UP, deg_to_rad(camera_yaw_degrees))
	var speed: float = combat.move_speed() * combat.move_speed_multiplier()
	var forced: Vector3 = combat.forced_velocity()
	velocity.x = direction.x * speed + forced.x
	velocity.z = direction.z * speed + forced.z
	var walking_by_script: bool = not controls_enabled and not auto_move.is_zero_approx()
	if walking_by_script:
		velocity.x = auto_move.x
		velocity.z = auto_move.z
		input = Vector2(auto_move.x, auto_move.z).normalized()
	var jump: float = combat.take_jump_impulse()
	if jump > 0.0:
		velocity.y = jump
	elif is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= gravity * delta
	var before: Vector3 = global_position
	move_and_slide()
	if is_on_floor():
		_ground_y = global_position.y
		_step(Vector2(global_position.x - before.x, global_position.z - before.z).length())
	if combat.can_turn():
		_facing = Facing.nearest_direction(input, _facing)
	_animate(delta, not input.is_zero_approx() and combat.move_speed_multiplier() > 0.0)
	_update_flash(delta)


## Where the camera looks: the feet, but at the ground height during a jump
## so the view does not bob (a fall still takes it down).
func camera_anchor() -> Vector3:
	var point: Vector3 = global_position
	if combat.is_airborne():
		point.y = minf(point.y, _ground_y)
	return point


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


func _step(distance: float) -> void:
	if footstep_sound.is_empty() or _climbing:
		return
	_step_distance += distance
	var stride: float = STEP_METERS * (1.3 if _animation == "run" else 1.0)
	if _step_distance >= stride:
		_step_distance = fmod(_step_distance, stride)
		SoundBank.play_sound(get_tree(), footstep_sound, 0.1)


func _animate(delta: float, moving: bool) -> void:
	var airborne: bool = combat.is_airborne() and not _climbing
	if _was_airborne and not airborne:
		_landing_left = LANDING_SECONDS
		SoundBank.play_sound(get_tree(), &"atterraggio")
	_was_airborne = airborne
	_landing_left = maxf(0.0, _landing_left - delta)
	var name: String = _pick_animation(moving, airborne)
	if name != _animation:
		_animation = name
		_animation_time = 0.0
	_animation_time += delta
	var entry: Dictionary = animation_entry(name, _facing)
	var count: int = int(entry["frames"])
	var index: int = 0
	match name:
		"combo":
			# Three strikes of the chapter-1 combo, four frames each.
			var strike: float = combat.tuning.strike_startup + combat.tuning.strike_active + combat.tuning.strike_recovery
			var progress: float = clampf(combat.state_time() / maxf(strike, 0.01), 0.0, 0.999)
			index = (combat.combo_index % 3) * 4 + int(progress * 4.0)
		"hurt":
			index = int(clampf(combat.state_time() / maxf(combat.tuning.hitstun_seconds, 0.01), 0.0, 0.999) * count)
		"jump":
			if _landing_left > 0.0:
				index = 6 + int((1.0 - _landing_left / LANDING_SECONDS) * 2.0)
			elif velocity.y > 1.5:
				index = 2 if combat.state_time() > 0.08 else 1
			elif velocity.y > -1.5:
				index = 4
			else:
				index = 5
		_:
			var frame_time: float = float(entry["ms"]) / 1000.0
			if name == "walk" and combat.running:
				frame_time /= combat.tuning.run_speed_multiplier
			var step: int = int(_animation_time / frame_time)
			index = step % count if bool(entry["loop"]) else mini(step, count - 1)
			if name == "parry" and combat.state == OttaviaCombat.State.PARRY:
				# Guard held: stay on the block pose until the parry ends.
				index = mini(index, 3)
	index = clampi(index, 0, count - 1)
	sprite.frame = int(entry["row"]) * COLUMNS + index
	shadow_proxy.frame = sprite.frame
	_update_lantern_light()


func _pick_animation(moving: bool, airborne: bool) -> String:
	if _scripted != "":
		return _scripted
	if _climbing:
		return "climb"
	match combat.state:
		OttaviaCombat.State.STRIKE:
			return "combo"
		OttaviaCombat.State.PARRY:
			return "parry"
		OttaviaCombat.State.HITSTUN:
			return "hurt"
		OttaviaCombat.State.BREATHLESS:
			return "breathless"
	if airborne or _landing_left > 0.0:
		return "jump"
	if moving and combat.running:
		return "run"
	return "walk" if moving else "idle"


## Row data of an animation in a direction (two-way ones fall back to s/w).
func animation_entry(name: String, direction: Facing.Direction) -> Dictionary:
	var key: String = "%s_%s" % [name, Facing.suffix(direction)]
	if _animations.has(key):
		return _animations[key]
	if name in TWO_WAY:
		var world: Vector3 = Facing.to_world(direction)
		return _animations["%s_%s" % [name, "w" if world.x < -0.3 else "s"]]
	return _animations["idle_%s" % Facing.suffix(direction)]


## Plays a one-off action to its last frame (tie_rope, give_hand) and holds
## it; `stop_scripted` goes back to the normal animations.
func play_scripted(name: String) -> void:
	_scripted = name
	_animation = ""
	var entry: Dictionary = animation_entry(name, _facing)
	await get_tree().create_timer(float(entry["frames"]) * float(entry["ms"]) / 1000.0).timeout


func stop_scripted() -> void:
	_scripted = ""


func is_climbing() -> bool:
	return _climbing


## Automatic climb (33): up the wall, then over the edge onto `top`.
func climb_to(top: Vector3, wall_normal: Vector3) -> void:
	if _climbing:
		return
	_climbing = true
	SoundBank.play_sound(get_tree(), &"presa_arrampicata")
	var was_enabled: bool = controls_enabled
	controls_enabled = false
	velocity = Vector3.ZERO
	face_toward(-wall_normal)
	var start: Vector3 = global_position
	var up: Vector3 = Vector3(start.x, top.y + 0.05, start.z)
	var tween: Tween = create_tween()
	tween.tween_property(self, "global_position", up, CLIMB_UP_SECONDS)
	tween.tween_property(self, "global_position", top + Vector3.UP * 0.05, CLIMB_OVER_SECONDS)
	await tween.finished
	_ground_y = global_position.y
	_climbing = false
	controls_enabled = was_enabled


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
	# The flame hums softly while the shutter is open (127).
	if is_inside_tree():
		if open:
			GameAudio.play_loop(&"lantern_flame", GameAudio.load_sfx(&"fiamma_ronzio"), FLAME_HUM_DB, 0.4)
		else:
			GameAudio.stop_loop(&"lantern_flame", 0.2)
	_material.set_shader_parameter(&"emission_energy", lantern_glass_energy if open else 0.0)


## Raised lantern (33): lights farther while the button is held.
func set_lantern_raised(raised: bool) -> void:
	var tuning: CombatTuning = combat.tuning
	var patch: float = CoatPatches.LANTERN_RANGE if combat.has_patch(&"lantern") else 1.0
	lantern_light.omni_range = _lantern_base_range * patch * (tuning.lantern_raised_range_multiplier if raised else 1.0)
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
		elif combat.slowdown > 0.0:
			# Parasites clinging to her (B1): an icy tint while she is slowed.
			amount = (0.2 + 0.1 * sin(Time.get_ticks_msec() * 0.01)) * HitFeedback.flash_scale
			color = Color(0.75, 0.88, 1.0)
		elif combat.state == OttaviaCombat.State.BREATHLESS:
			amount = (0.25 + 0.15 * sin(Time.get_ticks_msec() * 0.02)) * HitFeedback.flash_scale
			color = Color(0.45, 0.55, 1.0)
	_material.set_shader_parameter(&"flash", amount)
	_material.set_shader_parameter(&"flash_color", color)


func _exit_tree() -> void:
	GameAudio.stop_loop(&"lantern_flame", 0.1)
