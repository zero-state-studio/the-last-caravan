class_name OttaviaCombat
extends Node
## Ottavia's six actions, the breath and the counter-hit (33). Child of
## OttaviaProto, which calls physics_update() every physics frame and asks
## for the movement allowed by the current action.
##
## Strike: slow, precise swings in a combo of up to `combo_length` hits.
## Hook: tap pulls small creatures (or tears shields off), hold pushes away.
## Parry: hold to block (costs breath per hit); a hit right after the press
## is deflected and the attacker is left staggered.
## Jump: a real jump that also dodges: a moment of invulnerability at
## takeoff, and attacks along the ground miss while in the air; costs breath.
## Run: hold to run; drains breath while running, stops when it is empty.
## Lantern: tap opens or closes the shutter, hold raises it to light farther.
## Call: calls the companion present in the chapter (20).
## Breath is the only resource. Empty breath: breathless for an instant.
## Counter-hit: striking a creature that is open after its own attack.

signal message(key: StringName)
## Emitted when a jump starts (it shakes off clinging creatures).
signal jumped
## Emitted at the active moment of every strike.
signal struck
## A move done well by the player (81): parry, counter, combo, jump, hook.
## Enea counts them to learn the move.
signal technique_done(technique: StringName)

enum State { FREE, STRIKE, HOOK, PARRY, JUMP, HITSTUN, BREATHLESS }

const ACTIONS: Array[StringName] = [&"attack", &"hook", &"parry", &"jump", &"run", &"lantern", &"call"]
const SWING_COLOR: Color = Color(1.0, 0.95, 0.8, 0.9)
const COUNTER_COLOR: Color = Color(1.0, 0.77, 0.42, 1.0)
const DEFLECT_COLOR: Color = Color(0.85, 0.9, 1.0, 1.0)

@export var tuning: CombatTuning

var ottavia: OttaviaProto
var state: State = State.FREE
var stamina: float = 100.0
## The companion present in the chapter (20), or null.
var companion: Node = null
## Index of the current strike in the combo (0 = first).
var combo_index: int = 0

var _state_time: float = 0.0
var _hit_done: bool = false
var _combo_queued: bool = false
var _buffer: Dictionary = {}
var _since_action: float = 10.0
var _aim: Vector3 = Vector3.BACK
var _hook_push: bool = false
var _hook_charge: float = -1.0
## True while Ottavia runs (run held, moving, free, with breath).
var running: bool = false
var _run_held: bool = false
var _jump_from_run: bool = false
## Upward speed of a jump just started, taken once by OttaviaProto.
var _jump_impulse: float = 0.0
var _invulnerable_left: float = 0.0
var _knock_velocity: Vector3 = Vector3.ZERO
var _lantern_charge: float = -1.0
var _lantern_raised: bool = false
var _parry_held: bool = false
## Share of speed taken by creatures clinging to Ottavia (B1), 0-1.
var slowdown: float = 0.0
var _moving: bool = false
## Stick (or keys) direction this frame; zero when untouched.
var _input: Vector2 = Vector2.ZERO
## Only a fresh press opens the deflect window, not a parry held through
## another action.
var _parry_can_deflect: bool = false
## Chapter of Ottavia's life (34): what she has lost and learned.
var chapter: int = 1
## Coat patches sewn in the three slots (104).
var patches: Array[StringName] = []
var _return_strike_left: float = 0.0
var _dazzle_cooldown: float = 0.0


func _ready() -> void:
	ottavia = get_parent() as OttaviaProto
	stamina = max_stamina()


## Full breath and no action in progress (after a defeat, 105).
func reset() -> void:
	stamina = max_stamina()
	_enter(State.FREE)
	_buffer.clear()
	_parry_held = false
	_run_held = false
	running = false
	_knock_velocity = Vector3.ZERO
	_hook_charge = -1.0


func physics_update(delta: float, input: Vector2, controls_enabled: bool) -> void:
	_moving = controls_enabled and not input.is_zero_approx()
	_input = input if controls_enabled else Vector2.ZERO
	if controls_enabled:
		_read_input(input)
	_update_charges(delta)
	for action: StringName in _buffer.keys():
		_buffer[action] = float(_buffer[action]) - delta
		if float(_buffer[action]) <= 0.0:
			_buffer.erase(action)
	_state_time += delta
	_since_action += delta
	_return_strike_left = maxf(0.0, _return_strike_left - delta)
	_dazzle_cooldown = maxf(0.0, _dazzle_cooldown - delta)
	_invulnerable_left = maxf(0.0, _invulnerable_left - delta)
	_knock_velocity = _knock_velocity.move_toward(Vector3.ZERO, 8.0 * delta)
	_advance_state(input)
	_update_run(delta, controls_enabled)
	_regenerate(delta)


# --- Input ---------------------------------------------------------------

func _read_input(input: Vector2) -> void:
	for action: StringName in ACTIONS:
		if Input.is_action_just_pressed(action):
			press(action, input)
		elif Input.is_action_just_released(action):
			release(action)


## One button press; public so tests and cutscenes can drive Ottavia.
func press(action: StringName, input: Vector2 = Vector2.ZERO) -> void:
	match action:
		&"attack":
			_buffer[&"attack"] = tuning.input_buffer_seconds
		&"hook":
			_hook_charge = 0.0
		&"parry":
			_buffer[&"parry"] = tuning.input_buffer_seconds
			_parry_held = true
		&"jump":
			_buffer[&"jump"] = tuning.input_buffer_seconds
		&"run":
			_run_held = true
		&"lantern":
			_lantern_charge = 0.0
		&"call":
			_call_companion()


func release(action: StringName) -> void:
	match action:
		&"run":
			_run_held = false
		&"hook":
			if _hook_charge >= 0.0:
				_buffer[&"hook_pull"] = tuning.input_buffer_seconds
			_hook_charge = -1.0
		&"parry":
			_buffer.erase(&"parry")
			_parry_held = false
			if state == State.PARRY:
				_enter(State.FREE)
		&"lantern":
			if _lantern_charge >= 0.0 and not _lantern_raised:
				ottavia.set_lantern_open(not ottavia.lantern_open)
				SoundBank.play_sound(get_tree(), &"sportello_lanterna")
			_lantern_charge = -1.0
			if _lantern_raised:
				_lantern_raised = false
				ottavia.set_lantern_raised(false)


func _update_charges(delta: float) -> void:
	if _hook_charge >= 0.0:
		_hook_charge += delta
		if _hook_charge >= tuning.hook_hold_seconds:
			_buffer[&"hook_push"] = tuning.input_buffer_seconds
			_hook_charge = -1.0
	if _lantern_charge >= 0.0 and not _lantern_raised:
		_lantern_charge += delta
		if _lantern_charge >= tuning.lantern_hold_seconds:
			_lantern_raised = true
			if not ottavia.lantern_open:
				ottavia.set_lantern_open(true)
				SoundBank.play_sound(get_tree(), &"sportello_lanterna")
			ottavia.set_lantern_raised(true)
			dazzle()


# --- State machine ---------------------------------------------------------

func _advance_state(input: Vector2) -> void:
	match state:
		State.FREE:
			_start_buffered_action(input)
		State.STRIKE:
			_advance_strike()
		State.HOOK:
			_advance_hook()
		State.PARRY:
			if _buffer.has(&"jump"):
				_start_jump()
		State.JUMP:
			if _state_time >= 0.05 and ottavia.is_on_floor():
				_enter(State.FREE)
		State.HITSTUN:
			if _state_time >= tuning.hitstun_seconds:
				_enter(State.FREE)
		State.BREATHLESS:
			if _state_time >= tuning.breathless_seconds:
				_enter(State.FREE)


func _start_buffered_action(_input: Vector2) -> void:
	if _buffer.has(&"jump") and ottavia.is_on_floor():
		_start_jump()
	elif _buffer.has(&"parry") or _parry_held:
		_parry_can_deflect = _buffer.has(&"parry")
		_buffer.erase(&"parry")
		_enter(State.PARRY)
		# Only a fresh press costs breath: holding through breathlessness
		# must not loop back into it.
		if _parry_can_deflect:
			_spend(tuning.parry_press_cost)
	elif _buffer.has(&"attack"):
		_buffer.erase(&"attack")
		combo_index = 0
		_start_strike()
	elif _buffer.has(&"hook_push"):
		_buffer.erase(&"hook_push")
		_start_hook(true)
	elif _buffer.has(&"hook_pull"):
		_buffer.erase(&"hook_pull")
		_start_hook(false)


func _start_strike() -> void:
	_aim = _aim_direction(tuning.strike_reach)
	_enter(State.STRIKE)
	_combo_queued = false
	_spend(tuning.strike_stamina_cost)


func _advance_strike() -> void:
	var active_start: float = tuning.strike_startup
	var recovery_start: float = active_start + tuning.strike_active
	var end: float = recovery_start + tuning.strike_recovery
	if not _hit_done and _state_time >= active_start:
		_hit_done = true
		_strike_hit()
	if _state_time >= active_start and _buffer.has(&"attack") and combo_index + 1 < combo_length():
		_combo_queued = true
	if _combo_queued and _state_time >= recovery_start:
		_buffer.erase(&"attack")
		combo_index += 1
		_start_strike()
		return
	if _state_time >= end:
		combo_index = 0
		_enter(State.FREE)


func _start_hook(push: bool) -> void:
	_hook_push = push
	_aim = ottavia.facing_vector()
	var target: CombatEnemy = hook_target()
	if target != null:
		_aim = _flat_direction(target.global_position - ottavia.global_position)
		ottavia.face_toward(_aim)
	_enter(State.HOOK)
	_spend(tuning.hook_stamina_cost)


func _advance_hook() -> void:
	if not _hit_done and _state_time >= tuning.hook_startup:
		_hit_done = true
		_hook_hit()
	if _state_time >= tuning.hook_startup + tuning.hook_active + tuning.hook_recovery:
		_enter(State.FREE)


func _start_jump() -> void:
	_buffer.erase(&"jump")
	if stamina <= 0.0 or not ottavia.is_on_floor():
		return
	# Run held while moving counts even if the run starts with the jump.
	_jump_from_run = _run_held and _moving and stamina > 0.0
	_enter(State.JUMP)
	_invulnerable_left = jump_invulnerable_seconds()
	_jump_impulse = sqrt(2.0 * ottavia.gravity * tuning.jump_height)
	SoundBank.play_sound(get_tree(), &"passo")
	jumped.emit()
	_spend(tuning.jump_stamina_cost)


## The upward speed of a jump just started (0 when none); read once.
## Seconds spent in the current state (animations follow it).
func state_time() -> float:
	return _state_time


func take_jump_impulse() -> float:
	var impulse: float = _jump_impulse
	_jump_impulse = 0.0
	return impulse


## Running drains breath and keeps it from coming back; with no breath
## left Ottavia just walks (no breathlessness).
func _update_run(delta: float, controls_enabled: bool) -> void:
	running = controls_enabled and _run_held and _moving and state == State.FREE and stamina > 0.0
	if not running:
		return
	stamina = maxf(0.0, stamina - tuning.run_stamina_per_second * delta)
	_since_action = 0.0


func _enter(new_state: State) -> void:
	state = new_state
	_state_time = 0.0
	_hit_done = false
	if new_state != State.FREE and new_state != State.HITSTUN and new_state != State.BREATHLESS:
		_since_action = 0.0
	if new_state == State.PARRY:
		ottavia.face_toward(_aim_direction(tuning.strike_reach))


# --- Hits ------------------------------------------------------------------

func _strike_hit() -> void:
	var finisher: bool = combo_index == combo_length() - 1 and combo_length() > 1
	var origin: Vector3 = ottavia.global_position
	CombatEffects.swing(get_tree().current_scene, origin + Vector3.UP * 0.9, _aim, tuning.strike_reach, tuning.strike_arc_degrees, SWING_COLOR)
	struck.emit()
	var return_strike: bool = _return_strike_left > 0.0
	var landed: bool = false
	var critical_any: bool = false
	for target: CombatEnemy in targets_in_arc(tuning.strike_reach, tuning.strike_arc_degrees):
		var hit: CombatHit = CombatHit.new()
		hit.kind = CombatHit.Kind.STRIKE
		hit.source = ottavia
		hit.direction = _flat_direction(target.global_position - origin)
		hit.knockback = tuning.strike_knockback
		hit.critical = target.is_exposed() or _return_strike_left > 0.0
		hit.damage = tuning.strike_damage * Progression.power(chapter) * (tuning.combo_finisher_multiplier if finisher else 1.0) * (counter_multiplier() if hit.critical else 1.0)
		target.receive_hit(hit)
		if finisher and knows(&"heavy_finisher") and target.is_alive():
			target.stagger(Progression.HEAVY_FINISHER_STAGGER)
		landed = true
		critical_any = critical_any or hit.critical
		CombatEffects.spark(get_tree().current_scene, target.global_position + Vector3.UP * 0.9, COUNTER_COLOR if hit.critical else Color.WHITE)
	SoundBank.play_sound(get_tree(), &"colpo_bastone")
	if landed:
		var tree: SceneTree = get_tree()
		HitFeedback.hitstop(tree, tuning.hitstop_critical_seconds if critical_any else tuning.hitstop_seconds)
		HitFeedback.shake(tree, tuning.shake_critical_meters if critical_any else tuning.shake_meters)
		if return_strike:
			_return_strike_left = 0.0
		if critical_any:
			message.emit(&"COMBAT_COUNTER")
			technique_done.emit(&"counter")
		if finisher:
			technique_done.emit(&"combo")


func _hook_hit() -> void:
	SoundBank.play_sound(get_tree(), &"uncino")
	var origin: Vector3 = ottavia.global_position
	CombatEffects.swing(get_tree().current_scene, origin + Vector3.UP * 0.9, _aim, hook_reach(), tuning.hook_arc_degrees, SWING_COLOR)
	var target: CombatEnemy = hook_target()
	if target == null:
		return
	var hit: CombatHit = CombatHit.new()
	hit.kind = CombatHit.Kind.HOOK_PUSH if _hook_push else CombatHit.Kind.HOOK_PULL
	hit.source = ottavia
	hit.direction = _flat_direction(target.global_position - origin)
	hit.damage = tuning.hook_damage
	target.receive_hit(hit)
	if _hook_push:
		target.push_away(hit.direction, tuning.hook_push_distance)
	elif target.has_shield:
		target.tear_shield()
	elif target.is_small:
		target.pull_to(origin + hit.direction * tuning.hook_pull_distance)
	HitFeedback.hitstop(get_tree(), tuning.hitstop_seconds)
	technique_done.emit(&"hook")


## The creature the hook catches: the same aim rule as the strike (33).
func hook_target() -> CombatEnemy:
	return aim_target(hook_reach())


## The creature an action goes for (33). Stick held: the nearest creature
## within `reach` inside the aim cone around the stick direction. Stick
## still: the nearest creature within reach in any direction (Ottavia turns
## to it). Null when there is none, or when aim assist is off (options, 96).
func aim_target(reach: float) -> CombatEnemy:
	if not GameOptions.aim_assist:
		return null
	var origin: Vector3 = ottavia.global_position
	var stick: Vector3 = _stick_direction()
	var half_cone: float = aim_cone_degrees() * 0.5
	var best: CombatEnemy = null
	var best_distance: float = INF
	for node: Node in get_tree().get_nodes_in_group(&"combat_targets"):
		var target: CombatEnemy = node as CombatEnemy
		if target == null or not target.can_be_targeted():
			continue
		var offset: Vector3 = target.global_position - origin
		offset.y = 0.0
		var distance: float = offset.length()
		if distance > reach + target.radius or distance >= best_distance:
			continue
		if not stick.is_zero_approx() and distance > 0.01 and rad_to_deg(stick.angle_to(offset / distance)) > half_cone:
			continue
		best = target
		best_distance = distance
	return best


## Whole aim cone angle; wider at the easy level (40).
func aim_cone_degrees() -> float:
	return tuning.aim_cone_easy_degrees if Difficulty.is_easy() else tuning.aim_cone_degrees


func _stick_direction() -> Vector3:
	if _input.is_zero_approx():
		return Vector3.ZERO
	return Vector3(_input.x, 0.0, _input.y).normalized()


## Creatures within `reach` and `arc_degrees` around the current aim,
## nearest first.
func targets_in_arc(reach: float, arc_degrees: float) -> Array[CombatEnemy]:
	var result: Array[CombatEnemy] = []
	var origin: Vector3 = ottavia.global_position
	for node: Node in get_tree().get_nodes_in_group(&"combat_targets"):
		var target: CombatEnemy = node as CombatEnemy
		if target == null or not target.can_be_targeted():
			continue
		var offset: Vector3 = target.global_position - origin
		offset.y = 0.0
		if offset.length() > reach + target.radius:
			continue
		if offset.length() > 0.01 and rad_to_deg(_aim.angle_to(offset.normalized())) > arc_degrees * 0.5:
			continue
		result.append(target)
	result.sort_custom(func(a: CombatEnemy, b: CombatEnemy) -> bool:
		return a.global_position.distance_squared_to(origin) < b.global_position.distance_squared_to(origin))
	return result


## An attack from a creature. Returns how it ended (CombatAttack.Result).
func receive_attack(attack: CombatAttack) -> CombatAttack.Result:
	if _invulnerable_left > 0.0 or (attack.ground and is_airborne()):
		if state == State.JUMP:
			technique_done.emit(&"jump")
		return CombatAttack.Result.EVADED
	if state == State.PARRY:
		if attack.deflectable and _parry_can_deflect and _state_time <= deflect_window():
			if attack.source != null:
				attack.source.stagger(tuning.deflect_stagger_seconds)
				CombatEffects.spark(get_tree().current_scene, ottavia.global_position.lerp(attack.source.global_position, 0.5) + Vector3.UP * 1.0, DEFLECT_COLOR, 14.0)
			# A deflection costs no breath: the press cost is given back.
			stamina = minf(max_stamina(), stamina + tuning.parry_press_cost)
			SoundBank.play_sound(get_tree(), &"deviazione")
			HitFeedback.hitstop(get_tree(), tuning.hitstop_critical_seconds)
			HitFeedback.shake(get_tree(), tuning.shake_meters)
			message.emit(&"COMBAT_DEFLECT")
			technique_done.emit(&"parry")
			if knows(&"return_strike"):
				_return_strike_left = Progression.RETURN_STRIKE_SECONDS
			return CombatAttack.Result.DEFLECTED
		SoundBank.play_sound(get_tree(), &"parata")
		_spend(tuning.block_hit_cost)
		HitFeedback.shake(get_tree(), tuning.shake_meters * 0.5)
		return CombatAttack.Result.BLOCKED
	var damage: float = attack.damage * (tuning.breathless_damage_multiplier if state == State.BREATHLESS else 1.0) * patch_damage_taken(attack.source)
	ottavia.take_damage(damage)
	ottavia.flash(1.0, Color(1.0, 0.45, 0.4))
	SoundBank.play_sound(get_tree(), &"colpo_subito")
	HitFeedback.hitstop(get_tree(), tuning.hitstop_seconds)
	HitFeedback.shake(get_tree(), tuning.shake_critical_meters)
	if attack.source != null:
		_knock_velocity = _flat_direction(ottavia.global_position - attack.source.global_position) * tuning.hit_knockback / 0.15
	if ottavia.health > 0.0 and state != State.BREATHLESS:
		_enter(State.HITSTUN)
	return CombatAttack.Result.HIT


# --- Breath ----------------------------------------------------------------

func _spend(amount: float) -> void:
	stamina = maxf(0.0, stamina - amount)
	_since_action = 0.0
	if stamina <= 0.0 and state != State.BREATHLESS:
		_enter(State.BREATHLESS)
		SoundBank.play_sound(get_tree(), &"fiato_esaurito")
		message.emit(&"COMBAT_BREATHLESS")


func _regenerate(delta: float) -> void:
	# Never while parrying; half as fast while walking as standing still.
	if state == State.FREE and _since_action >= regen_delay():
		var rate: float = tuning.stamina_regen_per_second * (tuning.walking_regen_multiplier if _moving else 1.0) * (CoatPatches.BREATH_REGEN if has_patch(&"breath") else 1.0)
		stamina = minf(max_stamina(), stamina + rate * delta)


# --- Movement queries (used by OttaviaProto) --------------------------------

# --- Chapter, patches and difficulty (34, 104, 40) ---------------------------

func set_chapter(new_chapter: int) -> void:
	chapter = Progression.clamp_chapter(new_chapter)
	stamina = minf(stamina, max_stamina())


func knows(technique: StringName) -> bool:
	return Progression.knows(chapter, technique)


func has_patch(patch: StringName) -> bool:
	return patch in patches


func max_stamina() -> float:
	return tuning.max_stamina * float(Progression.entry(chapter)["stamina"])


func move_speed() -> float:
	return tuning.move_speed * float(Progression.entry(chapter)["speed"])


func combo_length() -> int:
	return mini(tuning.combo_length, int(Progression.entry(chapter)["combo"]))


func deflect_window() -> float:
	return (tuning.deflect_window + (Progression.KEEN_EYE_WINDOW if knows(&"keen_eye") else 0.0)) * Difficulty.deflect_window()


func jump_invulnerable_seconds() -> float:
	return maxf(tuning.jump_invulnerable_seconds, Progression.SURE_JUMP_INVULNERABLE) if knows(&"sure_jump") else tuning.jump_invulnerable_seconds


## In the air after a jump: attacks along the ground miss.
func is_airborne() -> bool:
	return state == State.JUMP and not ottavia.is_on_floor()


func counter_multiplier() -> float:
	return maxf(tuning.counter_multiplier, Progression.DEEP_COUNTER_MULTIPLIER) if knows(&"deep_counter") else tuning.counter_multiplier


func hook_reach() -> float:
	return tuning.hook_reach + (Progression.LONG_HOOK_EXTRA_REACH if knows(&"long_hook") else 0.0)


func regen_delay() -> float:
	return maxf(0.0, tuning.stamina_regen_delay - (Progression.VETERAN_BREATH_DELAY if knows(&"veteran_breath") else 0.0))


## Damage taken multiplier from the patches, by the side of the attacker.
func patch_damage_taken(source: CombatEnemy) -> float:
	if source == null:
		return 1.0
	var multiplier: float = 1.0
	if has_patch(&"cold") and source.world_side == &"night":
		multiplier *= CoatPatches.COLD_DAMAGE_TAKEN
	if has_patch(&"heat") and source.world_side == &"day":
		multiplier *= CoatPatches.HEAT_DAMAGE_TAKEN
	return multiplier


## Raised lantern that dazzles (a technique): nearby creatures stagger.
func dazzle() -> void:
	if not knows(&"dazzling_lantern") or _dazzle_cooldown > 0.0:
		return
	_dazzle_cooldown = Progression.DAZZLE_COOLDOWN
	for node: Node in get_tree().get_nodes_in_group(&"combat_targets"):
		var creature: CombatEnemy = node as CombatEnemy
		if creature != null and creature.can_be_targeted() and creature.flat_distance_to(ottavia.global_position) <= Progression.DAZZLE_RADIUS:
			creature.stagger(Progression.DAZZLE_STAGGER)
			creature.flash(1.0, Color(1.0, 0.95, 0.7))


func move_speed_multiplier() -> float:
	var free: float = 1.0 - clampf(slowdown, 0.0, 1.0)
	match state:
		State.FREE:
			return free * (tuning.run_speed_multiplier if running else 1.0)
		State.JUMP:
			return free * (tuning.run_speed_multiplier if _jump_from_run else 1.0)
		State.PARRY:
			return tuning.parry_speed_multiplier * free
		State.BREATHLESS:
			return tuning.breathless_speed_multiplier * free
	return 0.0


## Extra velocity from the current action: strike lunge, knockback.
func forced_velocity() -> Vector3:
	var velocity: Vector3 = _knock_velocity
	if state == State.STRIKE and _state_time >= tuning.strike_startup and _state_time < tuning.strike_startup + tuning.strike_active:
		velocity += _aim * tuning.strike_lunge / maxf(tuning.strike_active, 0.01)
	return velocity


func can_turn() -> bool:
	return state == State.FREE or state == State.BREATHLESS or state == State.JUMP


func is_acting() -> bool:
	return state == State.STRIKE or state == State.HOOK or state == State.JUMP


# --- Helpers ---------------------------------------------------------------

## Where an action goes (33): toward the aim target if there is one,
## otherwise the stick direction, otherwise where Ottavia already faces.
func _aim_direction(reach: float) -> Vector3:
	var target: CombatEnemy = aim_target(reach)
	var direction: Vector3 = ottavia.facing_vector()
	if target != null:
		direction = _flat_direction(target.global_position - ottavia.global_position)
	elif not _stick_direction().is_zero_approx():
		direction = _stick_direction()
	ottavia.face_toward(direction)
	return direction


func _call_companion() -> void:
	if companion != null and companion.has_method(&"call_in"):
		companion.call(&"call_in")
	else:
		message.emit(&"COMBAT_NO_COMPANION")


static func _flat_direction(offset: Vector3) -> Vector3:
	offset.y = 0.0
	return offset.normalized() if offset.length_squared() > 0.0001 else Vector3.BACK
