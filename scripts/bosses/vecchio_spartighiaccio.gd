class_name VecchioSpartighiaccio
extends BossEnemy
## Boss of the Shadow Line (41): an exceptional, old Spartighiaccio (B11)
## with a plough-shaped shield on its head, crusted with ice. It charges in a
## straight line (the path shows on the ground first): Ottavia steps aside
## and strikes its flanks; the shield lets almost nothing through. Its
## charges crack the ice floor and break cracked plates; charging toward a
## hole it stops at the edge, open for longer. Too close, it stomps.

enum Phase { IDLE, AIM, CHARGE, RECOVER, STUCK, STOMP }

const TELEGRAPH_COLOR: Color = Color(0.85, 0.92, 1.0, 0.9)

@export var creature: CreatureTuning

var phase: Phase = Phase.IDLE
var facing: Vector3 = Vector3.LEFT
## The ice floor, set by the arena.
var ice: IceArena
var _time: float = 0.0
var _charge_id: int = 0
var _charge_travel: float = 0.0
var _charge_hit: bool = false


func _ready() -> void:
	max_health = creature.sparti_health
	heavy = true
	radius = 1.0
	super._ready()


func is_exposed() -> bool:
	return phase == Phase.RECOVER or phase == Phase.STUCK or super.is_exposed()


## The front shield stops almost everything, even when it is open.
func damage_multiplier(hit: CombatHit) -> float:
	if rad_to_deg((-hit.direction).angle_to(facing)) <= creature.sparti_shield_degrees:
		return creature.sparti_shield_multiplier
	return 1.0


func _behave(delta: float) -> void:
	_time += delta
	velocity = Vector3.ZERO
	sprite.flip_h = facing.x > 0.0
	if not active or not is_alive():
		return
	var player: OttaviaProto = find_player()
	if player == null or player.health <= 0.0:
		return
	var distance: float = flat_distance_to(player.global_position)
	match phase:
		Phase.IDLE:
			_start_aim(player)
		Phase.AIM:
			# Keeps turning toward Ottavia until the last third of the aim.
			if _time < creature.sparti_aim_seconds * Difficulty.telegraph() * 0.66:
				facing = flat_direction_to(player.global_position)
			flash(0.2 + 0.4 * _time / maxf(creature.sparti_aim_seconds * Difficulty.telegraph(), 0.01), Color(0.8, 0.9, 1.0))
			if _time >= creature.sparti_aim_seconds * Difficulty.telegraph():
				_charge_id += 1
				_charge_travel = 0.0
				_charge_hit = false
				_set_phase(Phase.CHARGE)
		Phase.CHARGE:
			var step: float = creature.sparti_charge_speed * delta
			var ahead: Vector3 = global_position + facing * (radius + 0.3)
			if ice != null and ice.is_broken_at(ahead):
				_set_phase(Phase.STUCK)
				HitFeedback.shake(get_tree(), 0.2)
				return
			velocity = facing * creature.sparti_charge_speed
			_charge_travel += step
			if ice != null:
				ice.crack_at(global_position, _charge_id)
			if not _charge_hit and distance <= radius + 0.5:
				_charge_hit = true
				attack_player(creature.sparti_charge_damage, radius + 0.8, false)
			if _charge_travel >= creature.sparti_charge_max_distance or (is_on_wall() and _charge_travel > 0.5):
				HitFeedback.shake(get_tree(), 0.15)
				_set_phase(Phase.RECOVER)
		Phase.RECOVER:
			if _time >= creature.sparti_recover_seconds and not is_staggered():
				_start_aim(player)
		Phase.STUCK:
			if _time >= creature.sparti_stuck_seconds and not is_staggered():
				_start_aim(player)
		Phase.STOMP:
			if _time >= creature.sparti_stomp_telegraph * Difficulty.telegraph():
				SoundBank.play_sound(get_tree(), &"nemico_sconfitto", 0.2)
				HitFeedback.shake(get_tree(), 0.18)
				var attack_result: int = attack_player(creature.sparti_stomp_damage, creature.sparti_stomp_range, false)
				_set_phase(Phase.RECOVER)
				_time = creature.sparti_recover_seconds * 0.5 if attack_result >= 0 else 0.0


func _start_aim(player: OttaviaProto) -> void:
	if flat_distance_to(player.global_position) < creature.sparti_stomp_range:
		_set_phase(Phase.STOMP)
		CombatEffects.ground_ring(get_tree().current_scene, global_position, creature.sparti_stomp_range, TELEGRAPH_COLOR, creature.sparti_stomp_telegraph * Difficulty.telegraph())
		return
	facing = flat_direction_to(player.global_position)
	_set_phase(Phase.AIM)
	var length: float = creature.sparti_charge_max_distance
	if ice != null:
		length = ice.distance_to_edge(global_position, facing)
	CombatEffects.ground_line(get_tree().current_scene, global_position + facing * radius, facing, maxf(1.0, length - radius), radius * 2.0, TELEGRAPH_COLOR, creature.sparti_aim_seconds * Difficulty.telegraph())


func _on_reset() -> void:
	super._on_reset()
	facing = Vector3.LEFT
	_set_phase(Phase.IDLE)


func _set_phase(new_phase: Phase) -> void:
	phase = new_phase
	_time = 0.0
