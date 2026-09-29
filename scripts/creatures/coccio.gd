class_name Coccio
extends CombatEnemy
## B39 Coccio: a small, slow shelled creature of the fields (chapter 1,
## 0.5 m, 15 px). At every strike its shell shows one more crack; at the
## third it breaks. A pinch in front with 0.5 s of warning.

enum Phase { IDLE, APPROACH, WINDUP, ACTIVE, COOLDOWN }

const COLOR: Color = Color(0.72, 0.52, 0.36)
const TELEGRAPH_COLOR: Color = Color(1.0, 0.6, 0.3)
const HEIGHT_PIXELS: int = 15

@export var creature: CreatureTuning

var phase: Phase = Phase.IDLE
var cracks: int = 0
var _time: float = 0.0


func _init() -> void:
	creature = preload("res://assets/combat/creature_tuning.tres")
	world_side = &"twilight"
	is_small = true
	PlaceholderSprite.build_body(self, 0.3, 0.5, PlaceholderSprite.texture(18, HEIGHT_PIXELS, COLOR), HEIGHT_PIXELS)


func _ready() -> void:
	max_health = CreatureTuning.health_for_hits(creature.coccio_hits)
	super._ready()


func is_exposed() -> bool:
	return phase == Phase.COOLDOWN and _time < 0.6 or super.is_exposed()


func attack_in() -> float:
	if phase == Phase.WINDUP:
		return maxf(0.0, creature.coccio_windup * Difficulty.telegraph() - _time)
	return INF


func _on_hit(_hit: CombatHit) -> void:
	# One crack for each base strike of damage taken.
	var taken: float = max_health - health
	var per_crack: float = max_health / maxf(creature.coccio_hits, 1.0)
	var new_cracks: int = mini(int(floor(taken / maxf(per_crack, 0.01) + 0.001)), int(creature.coccio_hits) - 1)
	if new_cracks != cracks:
		cracks = new_cracks
		sprite.texture = PlaceholderSprite.texture(18, HEIGHT_PIXELS, COLOR, "round", cracks)
		_material.set_shader_parameter(&"sprite_texture", sprite.texture)


func _behave(delta: float) -> void:
	_time += delta
	var target: Node3D = find_target()
	var player: OttaviaProto = find_player()
	if target == null or player == null:
		return
	var distance: float = flat_distance_to(target.global_position)
	var move: Vector3 = Vector3.ZERO
	match phase:
		Phase.IDLE:
			if distance < creature.coccio_aggro and player.health > 0.0:
				_set_phase(Phase.APPROACH)
		Phase.APPROACH:
			if distance > creature.leash_distance or player.health <= 0.0:
				_set_phase(Phase.IDLE)
			elif distance <= creature.coccio_attack_range:
				_set_phase(Phase.WINDUP)
			else:
				move = flat_direction_to(target.global_position) * creature.coccio_speed
		Phase.WINDUP:
			flash(0.3 + 0.4 * _time / maxf(creature.coccio_windup * Difficulty.telegraph(), 0.01), TELEGRAPH_COLOR)
			if _time >= creature.coccio_windup * Difficulty.telegraph():
				_set_phase(Phase.ACTIVE)
				CombatEffects.swing(get_tree().current_scene, global_position + Vector3.UP * 0.3, flat_direction_to(target.global_position), creature.coccio_attack_range, 60.0, Color(1.0, 0.8, 0.55, 0.85))
				attack_player(creature.coccio_damage, creature.coccio_attack_range + 0.2)
		Phase.ACTIVE:
			if _time >= 0.1:
				_set_phase(Phase.COOLDOWN)
		Phase.COOLDOWN:
			if _time >= creature.coccio_cooldown:
				_set_phase(Phase.APPROACH)
	sprite.flip_h = flat_direction_to(target.global_position).x > 0.0
	if not is_being_moved() and not is_staggered():
		velocity = move


func _on_defeated() -> void:
	sprite.visible = false


func _on_reset() -> void:
	cracks = 0
	sprite.texture = PlaceholderSprite.texture(18, HEIGHT_PIXELS, COLOR)
	_material.set_shader_parameter(&"sprite_texture", sprite.texture)
	_set_phase(Phase.IDLE)


func _set_phase(new_phase: Phase) -> void:
	phase = new_phase
	_time = 0.0
