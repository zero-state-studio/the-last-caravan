class_name RootedFoglione
extends BossEnemy
## The boss of chapter 1 (107, docs/livelli/capitolo-01.md, room 7): a huge,
## very old Foglione (B33) rooted at the centre of the round top of the
## third field-cart, the only place of that cart in full sun. Its closed
## leaves shield it all round and strikes bounce off, with their own sound
## and spark so it reads at once; after every turn of the arena it turns
## back toward the sun, and while it does its flank is open (double
## damage). In phase 3, when it opens its leaves to bask, it can be struck
## from any side at normal damage, and any strike stops the healing. Three phases by health; beaten, it does not die: it
## uproots, rolls off the cart and goes away into the plain (35).
## Look (phase 4b step 4): the Meshy body, the same animal as the
## Foglione sprite, 4 m, with its head, legs and roots; eight big leaves on
## hinges round it, animated in Godot (section 10): closed they lean on
## the body, they lift on the open flank and open wide to bask; the roots
## of its attack come out of the planks.

signal rolled_away

enum Phase { ONE, TWO, THREE }
enum Act { IDLE, LASH_WINDUP, SEED_WINDUP, ROOT_WINDUP, RECOVER, BASK, UPROOTED }

const SUN_DIRECTION: Vector3 = Vector3.LEFT
const TELEGRAPH_COLOR: Color = Color(1.0, 0.6, 0.3)
const ROOT_COLOR: Color = Color(0.95, 0.8, 0.55, 0.9)
const SEED_COLOR: Color = Color(0.95, 0.9, 0.6, 0.9)
const LEAF_COLOR: Color = Color(0.36, 0.56, 0.3)
const BODY_MODEL: PackedScene = preload("res://assets/models/capitolo01/foglione_radicato_v2.glb")
const LEAF_MODEL: PackedScene = preload("res://assets/models/capitolo01/foglia_radicato.glb")
const ROOT_MODEL: PackedScene = preload("res://assets/models/capitolo01/radice_radicato.glb")
## The big leaves hinge on a ring high on its back (radius, height).
const LEAF_RING: float = 1.3
const LEAF_HEIGHT: float = 3.1
const LEAF_SCALE: float = 1.0
## Tilt of a leaf from upright, outward: closed it lies down along the
## back, on the open flank it lifts, basking it stands up open like a
## flower to the sun.
const LEAF_CLOSED: float = 2.45
const LEAF_OPEN: float = 0.45
const LEAF_FLANK: float = 1.2
## Body collision radius: the leaves reach about this far.
const BODY_RADIUS: float = 2.0
## Roots along each line of the attack: distances from the centre.
const ROOT_STEPS: Array[float] = [2.6, 4.4, 6.2]
const BOUNCE_COLOR: Color = Color(0.75, 1.0, 0.55)
const BOUNCE_SOUND: StringName = &"bastone_legno"
const HEIGHT: float = 4.0
const LEAVES: int = 8
## Radius of the arena, for the roots and for the uprooting roll.
const ARENA_RADIUS: float = 8.0
## Frames of the jerky turn back of phase 3.
const JERK_STEPS: int = 3

@export var creature: CreatureTuning

var phase: Phase = Phase.ONE
var act: Act = Act.IDLE
## Where its face (the closed leaves) points.
var facing: Vector3 = SUN_DIRECTION
var voltafaccia_called: bool = false
var _time: float = 0.0
var _attack_timer: float = 0.0
var _attack_count: int = 0
var _window_left: float = 0.0
var _window_total: float = 0.0
var _turn_from: Vector3 = SUN_DIRECTION
var _last_turn_at: float = -100.0
var _clock: float = 0.0
var _bask_timer: float = 0.0
var _bask_interrupted: bool = false
var _pending_lines: Array[Dictionary] = []
var _leaf_rig: Node3D
var _leaves: Array[Node3D] = []
## Additive layer over the leaves for the telegraphs and the bounce.
var _leaf_material: StandardMaterial3D
var _body: Node3D


func _init() -> void:
	creature = preload("res://assets/combat/creature_tuning.tres")
	world_side = &"day"
	heavy = true
	title_key = &"BOSS_FOGLIONE"
	radius = BODY_RADIUS
	PlaceholderSprite.build_body(self, BODY_RADIUS, HEIGHT, PlaceholderSprite.texture(8, 8, LEAF_COLOR), 8)


func _ready() -> void:
	max_health = CreatureTuning.health_for_hits(creature.rooted_hits)
	super._ready()
	sprite.visible = false
	_build_look()


# --- Rules -----------------------------------------------------------------

func phase_for_share(share: float) -> Phase:
	if share > creature.rooted_phase_2_share:
		return Phase.ONE
	if share > creature.rooted_phase_3_share:
		return Phase.TWO
	return Phase.THREE


## Open while it turns back to the sun after a turn, and while it basks.
func flank_open() -> bool:
	return _window_left > 0.0 or act == Act.BASK


func window_seconds() -> float:
	match phase:
		Phase.ONE:
			return creature.rooted_window_1
		Phase.TWO:
			return creature.rooted_window_2
	return creature.rooted_window_3


func damage_multiplier(hit: CombatHit) -> float:
	if act == Act.UPROOTED:
		return 0.0
	# Basking with the leaves open: any side, normal damage.
	if act == Act.BASK:
		return 1.0
	if not flank_open():
		return 0.0
	var from: Vector3 = -hit.direction
	if rad_to_deg(from.angle_to(facing)) <= creature.rooted_front_degrees:
		return 0.0
	return creature.rooted_flank_multiplier


func is_exposed() -> bool:
	return act == Act.RECOVER and _time < 0.5 or super.is_exposed()


func attack_in() -> float:
	match act:
		Act.LASH_WINDUP:
			return maxf(0.0, creature.rooted_lash_windup * Difficulty.telegraph() - _time)
		Act.SEED_WINDUP:
			return maxf(0.0, creature.rooted_seed_windup * Difficulty.telegraph() - _time)
		Act.ROOT_WINDUP:
			return maxf(0.0, creature.rooted_root_windup * Difficulty.telegraph() - _time)
	return INF


func attack_deflectable() -> bool:
	return act == Act.LASH_WINDUP


## Called by the arena platform at the end of every quarter turn.
func carried_turned(angle: float) -> void:
	facing = facing.rotated(Vector3.UP, angle).normalized()
	_turn_from = facing
	var window: float = window_seconds()
	# Phase 3: two turns in a row, less than 2 s apart, give more time.
	if phase == Phase.THREE and _clock - _last_turn_at <= creature.rooted_double_turn_seconds:
		window += creature.rooted_double_turn_bonus
	_last_turn_at = _clock
	_window_total = window
	_window_left = window
	if act != Act.UPROOTED and act != Act.BASK:
		_set_act(Act.IDLE)


## A strike on the closed leaves bounces off: no damage, its own sound
## and spark, not the sound of a hit (it must not look like a mistake).
func receive_hit(hit: CombatHit) -> void:
	if is_alive() and damage_multiplier(hit) == 0.0:
		_bounce(hit)
		return
	super.receive_hit(hit)


func _on_hit(hit: CombatHit) -> void:
	if act == Act.BASK:
		_bask_interrupted = true
		_close_leaves()
		_set_act(Act.RECOVER)
	var next: Phase = phase_for_share(health / maxf(max_health, 0.01))
	if next != phase:
		phase = next


# --- Behaviour ---------------------------------------------------------------

func _behave(delta: float) -> void:
	_clock += delta
	_time += delta
	velocity = Vector3.ZERO
	_turn_back(delta)
	_update_look(delta)
	if not active or act == Act.UPROOTED:
		return
	var player: OttaviaProto = find_player()
	if player == null or player.health <= 0.0:
		return
	match act:
		Act.IDLE:
			if phase == Phase.THREE:
				_bask_timer += delta
				if _bask_timer >= creature.rooted_bask_interval and _window_left <= 0.0:
					_bask_timer = 0.0
					_bask_interrupted = false
					_set_act(Act.BASK)
					return
			if _window_left > 0.0:
				return
			_attack_timer += delta
			var interval: float = creature.rooted_attack_interval_3 if phase == Phase.THREE else creature.rooted_attack_interval
			if _attack_timer >= interval:
				_attack_timer = 0.0
				_choose_attack(player)
		Act.LASH_WINDUP:
			_telegraph(creature.rooted_lash_windup)
			if _time >= creature.rooted_lash_windup * Difficulty.telegraph():
				_lash(player)
		Act.SEED_WINDUP:
			_telegraph(creature.rooted_seed_windup)
			if _time >= creature.rooted_seed_windup * Difficulty.telegraph():
				_seeds(player)
		Act.ROOT_WINDUP:
			if _time >= creature.rooted_root_windup * Difficulty.telegraph():
				_roots(player)
		Act.RECOVER:
			if _time >= 0.8:
				_set_act(Act.IDLE)
		Act.BASK:
			if _time >= creature.rooted_bask_seconds:
				if not _bask_interrupted:
					health = minf(max_health, health + CreatureTuning.health_for_hits(creature.rooted_bask_regain_hits))
					phase = phase_for_share(health / maxf(max_health, 0.01))
				_close_leaves()
				_set_act(Act.IDLE)


func _choose_attack(player: OttaviaProto) -> void:
	_attack_count += 1
	var toward: Vector3 = flat_direction_to(player.global_position)
	var near: bool = flat_distance_to(player.global_position) <= creature.rooted_lash_range
	if phase != Phase.ONE and not voltafaccia_called:
		voltafaccia_called = true
		_pending_lines.append({"call": &"voltafaccia"})
	if phase != Phase.ONE and _attack_count % 2 == 0:
		_set_act(Act.ROOT_WINDUP)
		_root_lines = _root_directions(toward)
		for direction: Vector3 in _root_lines:
			# Cracks in the planks announce the roots.
			CombatEffects.ground_line(get_tree().current_scene, global_position + direction * 1.2, direction, ARENA_RADIUS - 1.2, creature.rooted_root_width, ROOT_COLOR, creature.rooted_root_windup * Difficulty.telegraph())
	elif near and rad_to_deg(toward.angle_to(facing)) <= creature.rooted_lash_degrees * 0.5 + 20.0:
		_set_act(Act.LASH_WINDUP)
	else:
		_seed_direction = toward
		_set_act(Act.SEED_WINDUP)
		CombatEffects.ground_line(get_tree().current_scene, global_position + toward * 1.2, toward, ARENA_RADIUS + 2.0, creature.rooted_seed_width, SEED_COLOR, creature.rooted_seed_windup * Difficulty.telegraph())


var _root_lines: Array[Vector3] = []
var _seed_direction: Vector3 = Vector3.FORWARD


## Three lines 120 degrees apart, one of them toward Ottavia.
func _root_directions(toward: Vector3) -> Array[Vector3]:
	var result: Array[Vector3] = []
	for index: int in 3:
		result.append(toward.rotated(Vector3.UP, TAU * index / 3.0))
	return result


func _lash(player: OttaviaProto) -> void:
	_set_act(Act.RECOVER)
	CombatEffects.swing(get_tree().current_scene, global_position + Vector3.UP * 1.2, facing, creature.rooted_lash_range, creature.rooted_lash_degrees, Color(0.8, 1.0, 0.6, 0.9))
	_whip_leaves()
	var toward: Vector3 = flat_direction_to(player.global_position)
	if rad_to_deg(toward.angle_to(facing)) <= creature.rooted_lash_degrees * 0.5:
		attack_player(creature.rooted_lash_damage, creature.rooted_lash_range)


func _seeds(player: OttaviaProto) -> void:
	_set_act(Act.RECOVER)
	CombatEffects.spark(get_tree().current_scene, global_position + Vector3.UP * 1.5 + _seed_direction, SEED_COLOR, 16.0)
	if _in_line(player.global_position, _seed_direction, 1.0, ARENA_RADIUS + 2.0, creature.rooted_seed_width):
		var attack: CombatAttack = CombatAttack.new()
		attack.damage = creature.rooted_seed_damage * Difficulty.enemy_damage()
		attack.source = self
		attack.deflectable = false
		player.combat.receive_attack(attack)


func _roots(player: OttaviaProto) -> void:
	_set_act(Act.RECOVER)
	SoundBank.play_sound(get_tree(), &"uncino", 0.2)
	var hit: bool = false
	for direction: Vector3 in _root_lines:
		CombatEffects.spark(get_tree().current_scene, global_position + direction * ARENA_RADIUS * 0.6 + Vector3.UP * 0.3, ROOT_COLOR, 18.0)
		_raise_roots(direction)
		hit = hit or _in_line(player.global_position, direction, 1.2, ARENA_RADIUS, creature.rooted_root_width)
	if hit:
		var attack: CombatAttack = CombatAttack.new()
		attack.damage = creature.rooted_root_damage * Difficulty.enemy_damage()
		attack.source = self
		attack.deflectable = false
		attack.ground = true
		player.combat.receive_attack(attack)


func _in_line(point: Vector3, direction: Vector3, start: float, length: float, width: float) -> bool:
	var offset: Vector3 = point - global_position
	offset.y = 0.0
	var along: float = offset.dot(direction)
	if along < start or along > start + length:
		return false
	return (offset - direction * along).length() <= width * 0.5 + 0.3


## The arena asks for the reinforcements once (phase 2).
func take_pending_call() -> StringName:
	if _pending_lines.is_empty():
		return &""
	return _pending_lines.pop_front()["call"]


## After a turn it turns back toward the sun over the window: smoothly in
## phases 1 and 2, in jerks in phase 3.
func _turn_back(delta: float) -> void:
	if _window_left <= 0.0:
		return
	_window_left = maxf(0.0, _window_left - delta)
	var weight: float = 1.0 - _window_left / maxf(_window_total, 0.01)
	if phase == Phase.THREE:
		weight = floorf(weight * JERK_STEPS) / JERK_STEPS if _window_left > 0.0 else 1.0
	facing = _turn_from.slerp(SUN_DIRECTION, weight).normalized()
	if facing.is_zero_approx():
		facing = SUN_DIRECTION


func _telegraph(windup: float) -> void:
	var share: float = clampf(_time / maxf(windup * Difficulty.telegraph(), 0.01), 0.0, 1.0)
	_leaf_material.emission_energy_multiplier = 0.2 + 1.2 * share
	_leaf_material.emission = TELEGRAPH_COLOR


func _bounce(hit: CombatHit) -> void:
	var toward: Vector3 = -hit.direction if not hit.direction.is_zero_approx() else facing
	CombatEffects.spark(get_tree().current_scene, global_position + Vector3.UP * 1.6 + toward * 1.4, BOUNCE_COLOR, 22.0)
	_leaf_material.emission = BOUNCE_COLOR
	_leaf_material.emission_energy_multiplier = 1.4
	create_tween().tween_property(_leaf_material, "emission_energy_multiplier", 0.0, 0.25)
	# Provisional: a dull wooden knock, unlike a hit; its own sound in step 5.
	SoundBank.play_sound(get_tree(), BOUNCE_SOUND, 0.1)


# --- The end ---------------------------------------------------------------

## Beaten, it does not die (35): it uproots, rolls off the cart and goes.
func _on_defeated() -> void:
	deactivate()
	_set_act(Act.UPROOTED)
	_window_left = 0.0
	var away: Vector3 = Vector3.RIGHT
	var tween: Tween = create_tween()
	tween.tween_property(_leaf_rig, "rotation:z", -PI * 0.5, 1.2).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "global_position", global_position + away * (ARENA_RADIUS + 3.0) + Vector3.DOWN * 5.0, 3.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(_leaf_rig, "rotation:x", TAU * 2.0, 3.0)
	tween.tween_property(_leaf_rig, "scale", Vector3.ONE * 0.01, 0.8)
	tween.tween_callback(func() -> void:
		visible = false
		rolled_away.emit())


func _on_reset() -> void:
	super._on_reset()
	visible = true
	phase = Phase.ONE
	facing = SUN_DIRECTION
	voltafaccia_called = false
	_window_left = 0.0
	_attack_timer = 0.0
	_attack_count = 0
	_bask_timer = 0.0
	_pending_lines.clear()
	if _leaf_rig != null:
		_leaf_rig.rotation = Vector3.ZERO
		_leaf_rig.scale = Vector3.ONE
		_close_leaves()
	_set_act(Act.IDLE)


func _set_act(new_act: Act) -> void:
	act = new_act
	_time = 0.0
	if _leaf_material != null and new_act != Act.LASH_WINDUP and new_act != Act.SEED_WINDUP:
		_leaf_material.emission_energy_multiplier = 0.0
	if new_act == Act.BASK:
		_open_leaves()


# --- Look: body, leaves, roots -------------------------------------------------

func _build_look() -> void:
	_leaf_rig = Node3D.new()
	add_child(_leaf_rig)
	_body = BODY_MODEL.instantiate()
	_leaf_rig.add_child(_body)
	var box: AABB = VehicleKit.bounds(_body)
	_body.position = -Vector3(box.get_center().x, box.position.y, box.get_center().z)
	_leaf_material = StandardMaterial3D.new()
	_leaf_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_leaf_material.albedo_color = Color.BLACK
	_leaf_material.emission_enabled = true
	_leaf_material.emission_energy_multiplier = 0.0
	_leaf_material.emission = TELEGRAPH_COLOR
	for index: int in LEAVES:
		# Each hinge on the ring, its leaf standing up outward (local +Z).
		var hinge: Node3D = Node3D.new()
		hinge.rotation.y = TAU * index / LEAVES
		_leaf_rig.add_child(hinge)
		var pivot: Node3D = Node3D.new()
		pivot.position = Vector3(0.0, LEAF_HEIGHT, LEAF_RING)
		hinge.add_child(pivot)
		var leaf: Node3D = LEAF_MODEL.instantiate()
		pivot.add_child(leaf)
		leaf.scale = Vector3.ONE * LEAF_SCALE
		# The leaf model lies flat: stand it up, its base on the pivot.
		var leaf_box: AABB = VehicleKit.bounds(leaf)
		leaf.rotation.x = -PI * 0.5
		leaf.position = Vector3(-leaf_box.get_center().x, leaf_box.end.z, 0.0) * LEAF_SCALE
		for node: Node in leaf.find_children("*", "MeshInstance3D", true, false):
			(node as MeshInstance3D).material_overlay = _leaf_material
		_leaves.append(hinge)
	for node: Node in _body.find_children("*", "MeshInstance3D", true, false):
		(node as MeshInstance3D).material_overlay = _leaf_material
	_close_leaves()


## Roots out of the planks along a line of the attack: up fast, a moment,
## back down.
func _raise_roots(direction: Vector3) -> void:
	for step: float in ROOT_STEPS:
		var root_look: Node3D = ROOT_MODEL.instantiate()
		get_parent().add_child(root_look)
		var height: float = VehicleKit.bounds(root_look).size.y
		var at: Vector3 = global_position + direction * step
		root_look.global_position = at + Vector3.DOWN * height
		root_look.rotation.y = atan2(direction.x, direction.z) + PI * 0.5
		var tween: Tween = root_look.create_tween()
		tween.tween_property(root_look, "global_position", at + Vector3.DOWN * 0.2, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(step * 0.03)
		tween.tween_interval(0.5)
		tween.tween_property(root_look, "global_position", at + Vector3.DOWN * height, 0.4).set_ease(Tween.EASE_IN)
		tween.tween_callback(root_look.queue_free)


func _update_look(_delta: float) -> void:
	if _leaf_rig == null or act == Act.UPROOTED:
		return
	# The leaf rig looks along `facing` (its local +Z).
	_leaf_rig.rotation.y = atan2(facing.x, facing.z)
	if act == Act.BASK:
		return
	# While it turns back, the leaves on its flanks lift: the open side.
	for index: int in LEAVES:
		var side: float = absf(wrapf(TAU * index / LEAVES, -PI, PI))
		var on_flank: bool = side > deg_to_rad(creature.rooted_front_degrees) and side < PI - deg_to_rad(40.0)
		var leaf: Node3D = _leaves[index].get_child(0)
		leaf.rotation.x = lerpf(leaf.rotation.x, LEAF_FLANK if flank_open() and on_flank else LEAF_CLOSED, 0.25)


func _close_leaves() -> void:
	for hinge: Node3D in _leaves:
		hinge.get_child(0).rotation.x = LEAF_CLOSED


## Basking: the leaves open wide to the sun.
func _open_leaves() -> void:
	for hinge: Node3D in _leaves:
		var tween: Tween = create_tween()
		tween.tween_property(hinge.get_child(0), "rotation:x", LEAF_OPEN, 0.5)


func _whip_leaves() -> void:
	for index: int in [0, 1, LEAVES - 1]:
		var leaf: Node3D = _leaves[index].get_child(0)
		var tween: Tween = create_tween()
		tween.tween_property(leaf, "rotation:x", LEAF_OPEN, 0.12)
		tween.tween_property(leaf, "rotation:x", LEAF_CLOSED, 0.35)
