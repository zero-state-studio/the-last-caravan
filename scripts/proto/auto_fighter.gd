class_name AutoFighter
extends Node
## A simple bot that plays Ottavia for videos and measures (phase 3, step 7),
## not part of the game: it walks to the nearest creature, on the shaded side
## of the beasts of the Day (36), strikes, and deflects telegraphed attacks.
## It reads only public creature state (attack_in, is_exposed), so the same
## play runs at every chapter and difficulty.

signal finished(seconds: float, health_left: float, defeats: int)

const PARRY_HOLD_SECONDS: float = 0.3
const STRIKE_INTERVAL: float = 0.22
## Distance from the creature of the spot on its shaded side.
const SIDE_OFFSET: float = 1.1
const THREAT_DISTANCE: float = 3.0
## How early the bot jumps away from an attack it cannot deflect.
const STEP_LEAD_SECONDS: float = 0.2
## Distance kept from a boss while it is not open (beyond its stomp).
const BOSS_WAIT_DISTANCE: float = 4.5
const DODGE_PAUSE_SECONDS: float = 0.5
## About how far a running jump carries Ottavia.
const JUMP_DISTANCE: float = 2.3

var ottavia: OttaviaProto
## The bot stays within `home_radius` of `home` (an arena), when set.
var home: Vector3 = Vector3.ZERO
var home_radius: float = INF
## Human timing: each parry or jump comes up to this many seconds early or
## late, drawn with a fixed seed so every run of a fight is the same.
var timing_error: float = 0.0
var targets: Array[CombatEnemy] = []
var elapsed: float = 0.0
var defeats: int = 0
var _parry_left: float = 0.0
var _strike_left: float = 0.0
var _dodge_left: float = 0.0
var _dodge_direction: Vector3 = Vector3.ZERO
var _run_pressed: bool = false
var _was_down: bool = false
var _done: bool = false
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Timing offset drawn for the attack each creature is winding up.
var _offsets: Dictionary[CombatEnemy, float] = {}


func _ready() -> void:
	_rng.seed = 1


func _physics_process(delta: float) -> void:
	if _done or ottavia == null:
		return
	elapsed += delta
	var down: bool = ottavia.health <= 0.0
	if down and not _was_down:
		defeats += 1
	_was_down = down
	var alive: Array[CombatEnemy] = []
	for target: CombatEnemy in targets:
		if is_instance_valid(target) and target.is_alive():
			alive.append(target)
	if alive.is_empty():
		_done = true
		_steer(Vector3.ZERO)
		finished.emit(elapsed, ottavia.health, defeats)
		return
	var combat: OttaviaCombat = ottavia.combat
	_strike_left -= delta
	_dodge_left -= delta
	if _dodge_left > 0.0 and (combat.state == OttaviaCombat.State.JUMP or _dodge_left > DODGE_PAUSE_SECONDS - 0.1):
		_steer(_dodge_direction)
		return
	if _run_pressed:
		_run_pressed = false
		combat.release(&"run")
	if _parry_left > 0.0:
		_parry_left -= delta
		if _parry_left <= 0.0:
			combat.release(&"parry")
		return
	for target: CombatEnemy in alive:
		var soon: float = target.attack_in()
		if is_inf(soon):
			_offsets.erase(target)
			continue
		if not _offsets.has(target):
			_offsets[target] = _rng.randf_range(-timing_error, timing_error)
		soon -= _offsets[target]
		if target.flat_distance_to(ottavia.global_position) > THREAT_DISTANCE and target.attack_deflectable():
			continue
		if target.attack_deflectable() and soon <= combat.deflect_window() * 0.5:
			_steer(Vector3.ZERO)
			combat.press(&"parry")
			_parry_left = PARRY_HOLD_SECONDS
			return
		if not target.attack_deflectable() and soon <= STEP_LEAD_SECONDS:
			if _dodge_left <= 0.0:
				_dodge_left = DODGE_PAUSE_SECONDS
				_dodge_direction = _keep_home(target.dodge_direction(ottavia.global_position), JUMP_DISTANCE)
				_steer(_dodge_direction)
				# A running jump carries farther.
				combat.press(&"run")
				_run_pressed = true
				combat.press(&"jump")
			return
	var nearest: CombatEnemy = alive[0]
	for target: CombatEnemy in alive:
		if target.flat_distance_to(ottavia.global_position) < nearest.flat_distance_to(ottavia.global_position):
			nearest = target
	var distance: float = nearest.flat_distance_to(ottavia.global_position)
	var open: bool = nearest.is_exposed() or nearest.is_staggered()
	# Bosses: wait out of the stomp until they are open.
	if nearest is BossEnemy and not open:
		var away: Vector3 = nearest.flat_direction_to(ottavia.global_position)
		var wait: Vector3 = away if distance < BOSS_WAIT_DISTANCE else Vector3.ZERO
		if _home_offset().length() > home_radius:
			wait = -_home_offset().normalized()
		_steer(wait)
		return
	var spot: Vector3 = nearest.global_position + nearest.weak_side(ottavia.global_position) * (SIDE_OFFSET + nearest.radius)
	var to_spot: Vector3 = spot - ottavia.global_position
	to_spot.y = 0.0
	var in_reach: bool = distance <= combat.tuning.strike_reach * 0.85 + nearest.radius
	if in_reach and (to_spot.length() < 0.5 or open and not nearest is BossEnemy):
		_steer(Vector3.ZERO)
		if _strike_left <= 0.0:
			combat.press(&"attack")
			_strike_left = STRIKE_INTERVAL
	else:
		_steer(to_spot.normalized() if to_spot.length() > 0.2 else Vector3.ZERO)


## Flips a move that would leave the arena, when the flipped one stays in.
func _keep_home(direction: Vector3, distance: float) -> Vector3:
	var ahead: Vector3 = _home_offset() + direction * distance
	var flipped: Vector3 = _home_offset() - direction * distance
	if ahead.length() > home_radius and flipped.length() < ahead.length():
		return -direction
	return direction


func _home_offset() -> Vector3:
	var offset: Vector3 = ottavia.global_position - home
	offset.y = 0.0
	return offset


## Moves through the input actions, so Ottavia plays as with a stick
## (camera yaw 0: screen right is world +X, down is +Z).
func _steer(direction: Vector3) -> void:
	_set_axis(&"move_left", &"move_right", direction.x)
	_set_axis(&"move_up", &"move_down", direction.z)


func _set_axis(negative: StringName, positive: StringName, value: float) -> void:
	if value > 0.01:
		Input.action_release(negative)
		Input.action_press(positive, value)
	elif value < -0.01:
		Input.action_release(positive)
		Input.action_press(negative, -value)
	else:
		Input.action_release(negative)
		Input.action_release(positive)
