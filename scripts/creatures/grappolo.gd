class_name Grappolo
extends CombatEnemy
## B7 Grappolo: a colony of small round creatures huddled in a ball to keep
## warm; the outer ones have thick shells (only part of a strike reaches the
## ball). The ball rolls at Ottavia; hit, it breaks apart into soft pieces
## that scatter, and after a while the survivors roll back together into a
## smaller ball. When every piece is gone, the colony is defeated.

enum Phase { IDLE, WINDUP, ROLL, COOLDOWN, SPLIT }

const BIT_SCENE: PackedScene = preload("res://scenes/creatures/grappolo_bit.tscn")
const WOBBLE_PIXELS: float = 1.5
const GATHER_SECONDS: float = 1.5

@export var creature: CreatureTuning

var phase: Phase = Phase.IDLE
var members: int = 6
var bits: Array[GrappoloBit] = []
var _time: float = 0.0
var _roll_direction: Vector3 = Vector3.ZERO
var _roll_hit: bool = false
var _sprite_rest: Vector3


func _ready() -> void:
	members = creature.grappolo_members
	max_health = members * creature.grappolo_member_health
	heavy = true
	super._ready()
	_sprite_rest = sprite.position


## Health of one member, scaled by the difficulty (40).
func member_health() -> float:
	return creature.grappolo_member_health * Difficulty.enemy_health()


func can_be_targeted() -> bool:
	return is_alive() and phase != Phase.SPLIT


func is_exposed() -> bool:
	return phase == Phase.COOLDOWN and _time < 0.6 or super.is_exposed()


func damage_multiplier(_hit: CombatHit) -> float:
	return creature.grappolo_shell_multiplier


func _on_hit(_hit: CombatHit) -> void:
	if health > 0.0:
		members = maxi(1, ceili(health / member_health()))
		_split()


func _behave(delta: float) -> void:
	_time += delta
	var player: OttaviaProto = find_player()
	var target: Node3D = find_target()
	if player == null or target == null:
		return
	var distance: float = flat_distance_to(target.global_position)
	sprite.position = _sprite_rest
	velocity = Vector3.ZERO
	match phase:
		Phase.IDLE:
			if distance < creature.grappolo_aggro and player.health > 0.0:
				_set_phase(Phase.WINDUP)
		Phase.WINDUP:
			sprite.position = _sprite_rest + Vector3(randf_range(-1.0, 1.0), 0.0, 0.0) * WOBBLE_PIXELS * WorldScale.METERS_PER_PIXEL
			flash(0.25 + 0.35 * _time / maxf(creature.grappolo_roll_windup * Difficulty.telegraph(), 0.01), Color(1.0, 0.6, 0.3))
			if _time >= creature.grappolo_roll_windup * Difficulty.telegraph():
				_roll_direction = flat_direction_to(target.global_position)
				_roll_hit = false
				_set_phase(Phase.ROLL)
		Phase.ROLL:
			velocity = _roll_direction * creature.grappolo_roll_speed
			if not _roll_hit and distance <= radius + 0.6:
				_roll_hit = true
				attack_player(creature.grappolo_damage, radius + 0.7, true, true)
			if _time >= creature.grappolo_roll_seconds or is_on_wall():
				_set_phase(Phase.COOLDOWN)
		Phase.COOLDOWN:
			if _time >= creature.grappolo_roll_cooldown and not is_staggered():
				_set_phase(Phase.IDLE if distance > creature.leash_distance else Phase.WINDUP)
		Phase.SPLIT:
			_update_split()


func _split() -> void:
	_set_phase(Phase.SPLIT)
	sprite.visible = false
	collision_layer = 0
	for index: int in members:
		var bit: GrappoloBit = BIT_SCENE.instantiate()
		bit.creature = creature
		bit.colony = self
		get_parent().add_child(bit)
		var angle: float = TAU * index / members + randf() * 0.5
		bit.global_position = global_position + Vector3(cos(angle), 0.0, sin(angle)) * 0.3
		bit.scatter(Vector3(cos(angle), 0.0, sin(angle)))
		bits.append(bit)


func _update_split() -> void:
	var alive: Array[GrappoloBit] = []
	for index: int in bits.size():
		var item: Variant = bits[index]
		if is_instance_valid(item) and (item as GrappoloBit).is_alive():
			alive.append(item)
	bits = alive
	if bits.is_empty():
		health = 0.0
		SoundBank.play_sound(get_tree(), &"nemico_sconfitto")
		defeated.emit()
		return
	if _time < creature.grappolo_reform_seconds:
		return
	var center: Vector3 = Vector3.ZERO
	for bit: GrappoloBit in bits:
		center += bit.global_position
	center /= bits.size()
	var gathered: bool = true
	for bit: GrappoloBit in bits:
		bit.gather_to(center)
		gathered = gathered and bit.flat_distance_to(center) < 0.5
	if gathered or _time >= creature.grappolo_reform_seconds + GATHER_SECONDS:
		_reform(center)


func _reform(center: Vector3) -> void:
	members = bits.size()
	for bit: GrappoloBit in bits:
		bit.queue_free()
	bits.clear()
	global_position = Vector3(center.x, spawn_transform.origin.y, center.z)
	health = members * member_health()
	sprite.visible = true
	collision_layer = 1
	_set_phase(Phase.COOLDOWN)


func _on_staggered() -> void:
	if phase == Phase.ROLL or phase == Phase.WINDUP:
		_set_phase(Phase.COOLDOWN)


func _on_defeated() -> void:
	sprite.visible = false


func _on_reset() -> void:
	for index: int in bits.size():
		var item: Variant = bits[index]
		if is_instance_valid(item):
			(item as GrappoloBit).queue_free()
	bits.clear()
	members = creature.grappolo_members
	health = members * member_health()
	collision_layer = 1
	_set_phase(Phase.IDLE)


func _set_phase(new_phase: Phase) -> void:
	phase = new_phase
	_time = 0.0
