class_name FoglioneRadicato
extends BossEnemy
## Boss of the Field-Wagons (83): a huge, very old Foglione (B33) that has
## put down roots in the field and sucks its harvest. It keeps its leaves
## always toward the sun: they cover that side like a shield. Tilting the
## field with the lever moves the light, and the rooted beast turns slowly
## after it, uncovering its flank (the rule of the Day, 36). Roots burst out
## under Ottavia; close up it sweeps with its leaves; hit too much, it
## closes its leaves all around for a moment.

enum Phase { IDLE, FIGHT, SWEEP_WINDUP, SWEEP, CLOSED }

const TELEGRAPH_COLOR: Color = Color(1.0, 0.6, 0.3)
const ROOT_COLOR: Color = Color(0.95, 0.8, 0.55, 0.9)
const LEAF_COLOR: Color = Color(0.7, 0.95, 0.6)

@export var creature: CreatureTuning

var phase: Phase = Phase.IDLE
## Where its leaves point (flat unit vector); turns toward sun_direction.
var facing: Vector3 = Vector3.LEFT
## Toward the sun, set by the arena (west, or east while the field is tilted).
var sun_direction: Vector3 = Vector3.LEFT
var _time: float = 0.0
var _root_timer: float = 0.0
var _damage_since_close: float = 0.0
var _roots: Array[Dictionary] = []


func _ready() -> void:
	max_health = creature.foglione_health
	heavy = true
	radius = 1.2
	super._ready()


func is_exposed() -> bool:
	return (phase == Phase.SWEEP and _time < creature.foglione_sweep_exposed) or super.is_exposed()


## Leaves on the sun side (and all around while closed) let little through.
func damage_multiplier(hit: CombatHit) -> float:
	if phase == Phase.CLOSED:
		return creature.foglione_leaf_multiplier
	if rad_to_deg((-hit.direction).angle_to(facing)) <= creature.foglione_leaf_degrees:
		return creature.foglione_leaf_multiplier
	return 1.0


func _on_hit(hit: CombatHit) -> void:
	_damage_since_close += hit.damage * damage_multiplier(hit)
	if _damage_since_close >= creature.foglione_close_after_damage and phase != Phase.CLOSED:
		_damage_since_close = 0.0
		_set_phase(Phase.CLOSED)


func _behave(delta: float) -> void:
	_time += delta
	velocity = Vector3.ZERO
	_turn_toward_sun(delta)
	_update_roots(delta)
	if not active or not is_alive():
		return
	var player: OttaviaProto = find_player()
	if player == null or player.health <= 0.0:
		return
	var distance: float = flat_distance_to(player.global_position)
	match phase:
		Phase.IDLE:
			_set_phase(Phase.FIGHT)
		Phase.FIGHT:
			_root_timer += delta
			if _root_timer >= creature.foglione_root_interval:
				_root_timer = 0.0
				_start_root(player.global_position)
			var toward: Vector3 = flat_direction_to(player.global_position)
			if distance <= creature.foglione_sweep_range and rad_to_deg(toward.angle_to(facing)) <= 100.0:
				_set_phase(Phase.SWEEP_WINDUP)
		Phase.SWEEP_WINDUP:
			flash(0.3 + 0.4 * _time / maxf(creature.foglione_sweep_windup * Difficulty.telegraph(), 0.01), TELEGRAPH_COLOR)
			if _time >= creature.foglione_sweep_windup * Difficulty.telegraph():
				_set_phase(Phase.SWEEP)
				CombatEffects.swing(get_tree().current_scene, global_position + Vector3.UP * 1.0, facing, creature.foglione_sweep_range, 200.0, Color(0.8, 1.0, 0.6, 0.9))
				SoundBank.play_sound(get_tree(), &"colpo_bastone", 0.2)
				var toward_player: Vector3 = flat_direction_to(player.global_position)
				if rad_to_deg(toward_player.angle_to(facing)) <= 100.0:
					attack_player(creature.foglione_sweep_damage, creature.foglione_sweep_range)
		Phase.SWEEP:
			if _time >= creature.foglione_sweep_exposed + 0.4 and not is_staggered():
				_set_phase(Phase.FIGHT)
		Phase.CLOSED:
			flash(0.35, LEAF_COLOR)
			if _time >= creature.foglione_close_seconds:
				_set_phase(Phase.FIGHT)


## Rooted: it can only turn, slowly, to keep its leaves toward the sun.
func _turn_toward_sun(delta: float) -> void:
	var angle: float = facing.signed_angle_to(sun_direction, Vector3.UP)
	var step: float = deg_to_rad(creature.foglione_turn_degrees_per_second) * delta
	facing = facing.rotated(Vector3.UP, clampf(angle, -step, step)).normalized()
	sprite.flip_h = facing.x > 0.0


func _start_root(point: Vector3) -> void:
	var center: Vector3 = Vector3(point.x, global_position.y, point.z)
	CombatEffects.ground_ring(get_tree().current_scene, center, creature.foglione_root_radius, ROOT_COLOR, creature.foglione_root_telegraph * Difficulty.telegraph())
	_roots.append({"center": center, "left": creature.foglione_root_telegraph * Difficulty.telegraph()})


func _update_roots(delta: float) -> void:
	for index: int in range(_roots.size() - 1, -1, -1):
		var root: Dictionary = _roots[index]
		root["left"] = float(root["left"]) - delta
		if float(root["left"]) > 0.0:
			continue
		_roots.remove_at(index)
		if not active or not is_alive():
			continue
		var center: Vector3 = root["center"]
		CombatEffects.spark(get_tree().current_scene, center + Vector3.UP * 0.3, ROOT_COLOR, 18.0)
		SoundBank.play_sound(get_tree(), &"uncino", 0.2)
		var player: OttaviaProto = find_player()
		if player != null and Vector2(player.global_position.x - center.x, player.global_position.z - center.z).length() <= creature.foglione_root_radius:
			var attack: CombatAttack = CombatAttack.new()
			attack.damage = creature.foglione_root_damage * Difficulty.enemy_damage()
			attack.source = self
			attack.deflectable = false
			attack.ground = true
			player.combat.receive_attack(attack)


func _on_staggered() -> void:
	if phase == Phase.SWEEP_WINDUP:
		_set_phase(Phase.SWEEP)


func _on_reset() -> void:
	super._on_reset()
	facing = Vector3.LEFT
	sun_direction = Vector3.LEFT
	_roots.clear()
	_root_timer = 0.0
	_damage_since_close = 0.0
	_set_phase(Phase.IDLE)


func _set_phase(new_phase: Phase) -> void:
	phase = new_phase
	_time = 0.0
