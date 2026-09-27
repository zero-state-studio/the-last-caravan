class_name Raspagelo
extends CombatEnemy
## B5 Raspagelo: a burrowing rodent of the Twilight Margin (89) with shovel
## teeth and an armored plate on the forehead. Underground it cannot be hit:
## only a mound of earth moves toward Ottavia. It stops under her, the
## ground shakes (time to step aside), it bursts out biting, stays open for a
## moment and dives back. The head plate halves frontal strikes when it is
## not open.

enum Phase { IDLE, BURROW, TELEGRAPH, BURST, SURFACED, DIVE }

const MOUND_COLOR: Color = Color(0.45, 0.33, 0.24)
const DIVE_SECONDS: float = 0.3
const FRONT_DEGREES: float = 60.0

@export var creature: CreatureTuning

var phase: Phase = Phase.IDLE
var _time: float = 0.0
var _facing: Vector3 = Vector3.BACK
var _mound: Sprite3D


func _ready() -> void:
	max_health = creature.raspagelo_health
	is_small = true
	super._ready()
	_mound = Sprite3D.new()
	_mound.texture = _mound_texture()
	_mound.pixel_size = WorldScale.METERS_PER_PIXEL
	_mound.offset = Vector2(0.0, 4.5)
	_mound.no_depth_test = true
	_mound.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_mound.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_mound.visible = false
	add_child(_mound)


func can_be_targeted() -> bool:
	return is_alive() and (phase == Phase.IDLE or phase == Phase.BURST or phase == Phase.SURFACED)


func is_exposed() -> bool:
	return (phase == Phase.BURST or (phase == Phase.SURFACED and _time < creature.raspagelo_exposed)) or super.is_exposed()


func damage_multiplier(hit: CombatHit) -> float:
	if is_exposed():
		return 1.0
	if rad_to_deg((-hit.direction).angle_to(_facing)) <= FRONT_DEGREES:
		return creature.raspagelo_armor_multiplier
	return 1.0


func _behave(delta: float) -> void:
	_time += delta
	var player: OttaviaProto = find_player()
	var target: Node3D = find_target()
	if player == null or target == null:
		return
	var distance: float = flat_distance_to(target.global_position)
	var move: Vector3 = Vector3.ZERO
	match phase:
		Phase.IDLE:
			if distance < creature.raspagelo_aggro and player.health > 0.0:
				_set_phase(Phase.DIVE)
		Phase.DIVE:
			if _time >= DIVE_SECONDS:
				_go_under(true)
				_set_phase(Phase.BURROW)
		Phase.BURROW:
			if distance > creature.leash_distance or player.health <= 0.0:
				pass
			elif distance > 0.25:
				move = flat_direction_to(target.global_position) * creature.raspagelo_burrow_speed
			if distance <= 0.35 and _time >= creature.raspagelo_underground_min:
				_set_phase(Phase.TELEGRAPH)
				CombatEffects.ground_ring(get_tree().current_scene, global_position, creature.raspagelo_burst_radius, Color(0.95, 0.85, 0.7, 0.9), creature.raspagelo_telegraph * Difficulty.telegraph())
		Phase.TELEGRAPH:
			_mound.position = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)) * WorldScale.METERS_PER_PIXEL
			if _time >= creature.raspagelo_telegraph * Difficulty.telegraph():
				_go_under(false)
				_facing = flat_direction_to(target.global_position)
				sprite.flip_h = _facing.x > 0.0
				_set_phase(Phase.BURST)
				attack_player(creature.raspagelo_damage, creature.raspagelo_burst_radius, false)
				flash(0.6, Color(0.85, 0.9, 1.0))
				# A burst of earth that is hard to miss, even in tall grass.
				CombatEffects.spark(get_tree().current_scene, global_position + Vector3.UP * 0.4, MOUND_COLOR.lightened(0.4), 30.0)
				CombatEffects.ground_ring(get_tree().current_scene, global_position, 0.6, Color(0.9, 0.75, 0.55, 0.9), 0.4)
		Phase.BURST:
			if _time >= 0.1:
				_set_phase(Phase.SURFACED)
		Phase.SURFACED:
			if _time >= creature.raspagelo_exposed + creature.raspagelo_surfaced and not is_staggered():
				_set_phase(Phase.DIVE)
	if not is_being_moved():
		velocity = move


func _go_under(under: bool) -> void:
	sprite.visible = not under
	_mound.visible = under
	_mound.position = Vector3.ZERO
	# Underground it passes under Ottavia's feet.
	collision_layer = 0 if under else 1
	collision_mask = 0 if under else 1


func _on_defeated() -> void:
	sprite.visible = false
	_mound.visible = false


func _on_reset() -> void:
	_go_under(false)
	_set_phase(Phase.IDLE)


func _set_phase(new_phase: Phase) -> void:
	phase = new_phase
	_time = 0.0


## A small mound of dug earth, drawn at the world density.
static func _mound_texture() -> ImageTexture:
	var image: Image = Image.create(20, 9, false, Image.FORMAT_RGBA8)
	for y: int in 9:
		for x: int in 20:
			var nx: float = (x + 0.5 - 10.0) / 10.0
			var ny: float = (y + 0.5) / 9.0
			if nx * nx + (1.0 - ny) * (1.0 - ny) * 0.9 <= 1.0 and ny > 0.2:
				var shade: float = 1.0 if y < 4 else 0.7
				image.set_pixel(x, y, Color(MOUND_COLOR.r * shade, MOUND_COLOR.g * shade, MOUND_COLOR.b * shade))
	return ImageTexture.create_from_image(image)
