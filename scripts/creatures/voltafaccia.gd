class_name Voltafaccia
extends CombatEnemy
## B31 Voltafaccia: a small grazer of the Day Margin (92) that always keeps
## its muzzle toward the sun, the Day in the west (100), and turns its whole
## body not to lose it: it sidles toward Ottavia instead of turning. Its
## shaded side is the right one (north): hit from there, it takes double
## damage (36). The first beast that teaches the rule of the Day.

enum Phase { GRAZE, APPROACH, WINDUP, ACTIVE, EXPOSED, COOLDOWN }

## Toward the Day (100): the beast always faces this way.
const SUN_DIRECTION: Vector3 = Vector3.LEFT
const TELEGRAPH_COLOR: Color = Color(1.0, 0.6, 0.3)
const GRAZE_RADIUS: float = 1.5
const SEPARATION_DISTANCE: float = 1.2

@export var creature: CreatureTuning

var phase: Phase = Phase.GRAZE
var _time: float = 0.0
var _graze_goal: Vector3


func _ready() -> void:
	max_health = creature.voltafaccia_health
	super._ready()
	_graze_goal = global_position


## The beast's right: with the sun in the west, the north side.
func shaded_side() -> Vector3:
	return SUN_DIRECTION.cross(Vector3.UP)


func damage_multiplier(hit: CombatHit) -> float:
	var toward_attacker: Vector3 = -hit.direction
	if rad_to_deg(toward_attacker.angle_to(shaded_side())) <= creature.voltafaccia_shade_degrees:
		return creature.voltafaccia_shade_multiplier
	return 1.0


func is_exposed() -> bool:
	return phase == Phase.EXPOSED or super.is_exposed()


func _behave(delta: float) -> void:
	_time += delta
	var player: OttaviaProto = find_player()
	var target: Node3D = find_target()
	if player == null or target == null:
		return
	var distance: float = flat_distance_to(target.global_position)
	var move: Vector3 = Vector3.ZERO
	match phase:
		Phase.GRAZE:
			if flat_distance_to(_graze_goal) < 0.2 or _time > 2.5:
				_time = 0.0
				var angle: float = randf() * TAU
				_graze_goal = spawn_transform.origin + Vector3(cos(angle), 0.0, sin(angle)) * randf() * GRAZE_RADIUS
			move = flat_direction_to(_graze_goal) * creature.voltafaccia_speed * 0.3
			if distance < creature.voltafaccia_aggro and player.health > 0.0:
				_set_phase(Phase.APPROACH)
		Phase.APPROACH:
			if distance > creature.leash_distance or player.health <= 0.0:
				_set_phase(Phase.GRAZE)
			elif distance <= creature.voltafaccia_attack_range:
				_set_phase(Phase.WINDUP)
			else:
				move = (flat_direction_to(target.global_position) + _separation()).normalized() * creature.voltafaccia_speed
		Phase.WINDUP:
			flash(0.3 + 0.4 * _time / maxf(creature.voltafaccia_windup * Difficulty.telegraph(), 0.01), TELEGRAPH_COLOR)
			if _time >= creature.voltafaccia_windup * Difficulty.telegraph():
				_set_phase(Phase.ACTIVE)
				var toward: Vector3 = flat_direction_to(target.global_position)
				_move_by(toward * creature.voltafaccia_lunge)
				CombatEffects.swing(get_tree().current_scene, global_position + Vector3.UP * 0.5, toward, creature.voltafaccia_attack_range, 70.0, Color(1.0, 0.8, 0.55, 0.85))
				attack_player(creature.voltafaccia_damage, creature.voltafaccia_attack_range + creature.voltafaccia_lunge * 0.5)
		Phase.ACTIVE:
			if _time >= creature.voltafaccia_active:
				_set_phase(Phase.EXPOSED)
		Phase.EXPOSED:
			if _time >= creature.voltafaccia_exposed and not is_staggered():
				_set_phase(Phase.COOLDOWN)
		Phase.COOLDOWN:
			# Backs off a little, still facing the sun.
			if distance < creature.voltafaccia_attack_range * 1.5:
				move = -flat_direction_to(target.global_position) * creature.voltafaccia_speed * 0.5
			if _time >= creature.voltafaccia_cooldown:
				_set_phase(Phase.APPROACH)
	if not is_being_moved() and not is_staggered():
		velocity = move


## Keeps the herd from piling up on one spot.
func _separation() -> Vector3:
	var push: Vector3 = Vector3.ZERO
	for node: Node in get_tree().get_nodes_in_group(&"combat_targets"):
		if node == self or not node is Voltafaccia:
			continue
		var other: Voltafaccia = node
		var offset: Vector3 = global_position - other.global_position
		offset.y = 0.0
		if offset.length() < SEPARATION_DISTANCE and offset.length() > 0.01:
			push += offset.normalized() * (SEPARATION_DISTANCE - offset.length())
	return push


func _on_staggered() -> void:
	_set_phase(Phase.EXPOSED)


func _on_defeated() -> void:
	sprite.visible = false


func _on_reset() -> void:
	_set_phase(Phase.GRAZE)


func _set_phase(new_phase: Phase) -> void:
	phase = new_phase
	_time = 0.0
