class_name Voltafaccia
extends SunFacingEnemy
## B31 Voltafaccia: a small grazer of the Day Margin (92) that always keeps
## its muzzle toward the sun, the Day in the west (100), and turns its whole
## body not to lose it: it sidles toward Ottavia instead of turning. Its
## shaded side is the right one (north when it faces west): hit from there,
## it takes double damage (36). The first beast that teaches the rule of the
## Day. In a herd (chapter 1): within 5 m the herd is alarmed, and they
## attack one at a time; after every attack it turns back to the sun.

enum Phase { GRAZE, ALARMED, APPROACH, WINDUP, ACTIVE, EXPOSED, COOLDOWN }

const TELEGRAPH_COLOR: Color = Color(1.0, 0.6, 0.3)
const GRAZE_RADIUS: float = 1.5
const SEPARATION_DISTANCE: float = 1.2
## Beasts this close to each other are one herd.
const HERD_RADIUS: float = 12.0
## Alarmed ones keep this far while another attacks.
const WAIT_DISTANCE: float = 3.2
const LOOK: String = "res://assets/sprites/creatures/c01/voltafaccia"
const LOOK_RATES: Dictionary = {"walk": 8.0, "graze": 5.0, "idle": 6.0, "attack": 14.0, "hit": 12.0, "defeat": 10.0}

var phase: Phase = Phase.GRAZE
var _time: float = 0.0
var _graze_goal: Vector3


func _ready() -> void:
	max_health = CreatureTuning.health_for_hits(creature.voltafaccia_hits)
	super._ready()
	use_look(LOOK, LOOK_RATES)
	_graze_goal = global_position


func damage_multiplier(hit: CombatHit) -> float:
	if hit_on_shaded_side(hit, creature.voltafaccia_shade_degrees):
		return creature.voltafaccia_shade_multiplier
	return 1.0


func is_exposed() -> bool:
	return phase == Phase.EXPOSED or super.is_exposed()


func attack_in() -> float:
	if phase == Phase.WINDUP:
		return maxf(0.0, creature.voltafaccia_windup * Difficulty.telegraph() - _time)
	return INF


## True while this beast holds the herd's turn to attack.
func is_attacking() -> bool:
	return phase == Phase.APPROACH or phase == Phase.WINDUP or phase == Phase.ACTIVE or phase == Phase.EXPOSED


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
			if player.health > 0.0 and (distance < creature.voltafaccia_aggro or _herd_alarmed()):
				_set_phase(Phase.ALARMED)
		Phase.ALARMED:
			if distance > creature.leash_distance or player.health <= 0.0:
				_set_phase(Phase.GRAZE)
			elif not _other_attacking():
				_set_phase(Phase.APPROACH)
			elif distance < WAIT_DISTANCE:
				move = -flat_direction_to(target.global_position) * creature.voltafaccia_speed * 0.4
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
			# Backs off a little, face to the sun again, and gives the turn.
			if distance < creature.voltafaccia_attack_range * 1.5:
				move = -flat_direction_to(target.global_position) * creature.voltafaccia_speed * 0.5
			if _time >= creature.voltafaccia_cooldown:
				_set_phase(Phase.ALARMED)
	if not is_being_moved() and not is_staggered():
		velocity = move


## Another beast of the herd noticed Ottavia: the whole herd is alarmed.
func _herd_alarmed() -> bool:
	for other: Voltafaccia in _herd():
		if other.phase != Phase.GRAZE:
			return true
	return false


func _other_attacking() -> bool:
	for other: Voltafaccia in _herd():
		if other.is_attacking():
			return true
	return false


func _herd() -> Array[Voltafaccia]:
	var result: Array[Voltafaccia] = []
	for node: Node in get_tree().get_nodes_in_group(&"combat_targets"):
		var other: Voltafaccia = node as Voltafaccia
		if other != null and other != self and other.is_alive() and flat_distance_to(other.global_position) <= HERD_RADIUS:
			result.append(other)
	return result


## Keeps the herd from piling up on one spot.
func _separation() -> Vector3:
	var push: Vector3 = Vector3.ZERO
	for other: Voltafaccia in _herd():
		var offset: Vector3 = global_position - other.global_position
		offset.y = 0.0
		if offset.length() < SEPARATION_DISTANCE and offset.length() > 0.01:
			push += offset.normalized() * (SEPARATION_DISTANCE - offset.length())
	return push


func look_animation() -> String:
	if not is_alive():
		return "defeat"
	match phase:
		Phase.GRAZE:
			return "graze"
		Phase.WINDUP, Phase.ACTIVE:
			return "attack"
		Phase.EXPOSED:
			return "hit"
	return "walk" if velocity.length() > 0.2 else "idle"


## Its muzzle stays toward the sun: it sidles, it does not turn (B31).
func look_direction() -> Vector3:
	return facing


func _on_hit(_hit: CombatHit) -> void:
	play_once("hit", 0.35)


func _on_staggered() -> void:
	_set_phase(Phase.EXPOSED)


func _on_defeated() -> void:
	# The last frame of the defeat stays until the room restarts; without
	# the strips the still sprite goes away as before.
	sprite.visible = look != null


func _on_reset() -> void:
	super._on_reset()
	_set_phase(Phase.GRAZE)


func _set_phase(new_phase: Phase) -> void:
	phase = new_phase
	_time = 0.0
