class_name CombatEnemy
extends CharacterBody3D
## Base of every creature Ottavia can fight (35, 36): health, hit reactions
## (flash, knockback, sound), stagger after a deflected attack, and the hook
## (pull small creatures, push away, tear shields off). Creatures draw with
## the character sprite billboard (99) and never drift with the palette (51).

signal defeated

const LIT_SHADER: Shader = preload("res://scenes/proto/materials/sprite_billboard_lit.gdshader")
const FLASH_DECAY_PER_SECOND: float = 8.0
const MOVE_SETTLE_SECONDS: float = 0.15
## Warm pulse while the creature is open: a strike now is a counter-hit (33).
const OPEN_COLOR: Color = Color(1.0, 0.9, 0.6)

@export var max_health: float = 50.0
## Body radius in meters, added to the reach of Ottavia's actions.
@export var radius: float = 0.4
## Small creatures are pulled by the hook.
@export var is_small: bool = false
## A shield blocks strikes until the hook tears it off.
@export var has_shield: bool = false
## Heavy creatures do not move when hit or pushed.
@export var heavy: bool = false
## Side of the world it belongs to (day, twilight, night): the coat patches
## against cold and heat (104) act on it.
@export var world_side: StringName = &"twilight"

var health: float = 0.0
## Health before the difficulty scaling (40).
var base_max_health: float = 0.0
## Where the creature starts; it comes back here when the room restarts (105).
var spawn_transform: Transform3D
## Forced target (the lesson makes the dummy swing at Enea), or null.
var target_override: Node3D = null
## Pixel health bar above the head, shown once hit (none for bosses).
var health_bar: EnemyHealthBar

var _material: ShaderMaterial = ShaderMaterial.new()
var _flash: float = 0.0
var _flash_color: Color = Color.WHITE
var _stagger_left: float = 0.0
var _move_velocity: Vector3 = Vector3.ZERO
var _move_left: float = 0.0

@onready var sprite: Sprite3D = $Sprite3D


func _ready() -> void:
	add_to_group(&"combat_targets")
	base_max_health = max_health
	max_health = base_max_health * Difficulty.enemy_health()
	health = max_health
	spawn_transform = global_transform
	_material.shader = LIT_SHADER
	_material.set_shader_parameter(&"sprite_texture", sprite.texture)
	sprite.material_override = _material
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if shows_health_bar():
		health_bar = EnemyHealthBar.new(self)
		add_child(health_bar)


func is_alive() -> bool:
	return health > 0.0


## False while the creature cannot be hit (underground, split apart...).
func can_be_targeted() -> bool:
	return is_alive()


## Back to the start, full health (the room restarts after a defeat, 105).
func reset_enemy() -> void:
	global_transform = spawn_transform
	max_health = base_max_health * Difficulty.enemy_health()
	health = max_health
	_stagger_left = 0.0
	_move_left = 0.0
	sprite.visible = true
	collision_layer = 1
	collision_mask = 1
	_on_reset()


## True while the creature is open after its own attack (counter-hit, 33).
func is_exposed() -> bool:
	return _stagger_left > 0.0


func is_staggered() -> bool:
	return _stagger_left > 0.0


func receive_hit(hit: CombatHit) -> void:
	if not is_alive():
		return
	if has_shield and hit.kind == CombatHit.Kind.STRIKE:
		flash(0.5, Color(0.8, 0.85, 1.0))
		SoundBank.play_sound(get_tree(), &"parata")
		return
	health = maxf(0.0, health - hit.damage * damage_multiplier(hit))
	flash(1.0, Color(1.0, 0.95, 0.85) if not hit.critical else Color(1.0, 0.77, 0.42))
	SoundBank.play_sound(get_tree(), &"nemico_colpito")
	if hit.knockback > 0.0 and not heavy:
		_move_by(hit.direction * hit.knockback)
	_on_hit(hit)
	if health <= 0.0:
		SoundBank.play_sound(get_tree(), &"nemico_sconfitto")
		_become_defeated()
		_on_defeated()
		defeated.emit()


func stagger(seconds: float) -> void:
	_stagger_left = maxf(_stagger_left, seconds)
	flash(0.8, Color(0.85, 0.9, 1.0))
	_on_staggered()


func pull_to(point: Vector3) -> void:
	if not heavy:
		_move_by(Vector3(point.x - global_position.x, 0.0, point.z - global_position.z))


func push_away(direction: Vector3, distance: float) -> void:
	if not heavy:
		_move_by(direction * distance)


func tear_shield() -> void:
	has_shield = false


func flash(amount: float, color: Color) -> void:
	_flash = maxf(_flash, amount * HitFeedback.flash_scale)
	_flash_color = color


func _physics_process(delta: float) -> void:
	_stagger_left = maxf(0.0, _stagger_left - delta)
	_flash = maxf(0.0, _flash - FLASH_DECAY_PER_SECOND * delta)
	if is_alive() and is_exposed() and _flash < 0.2:
		flash(0.3 + 0.15 * sin(Time.get_ticks_msec() * 0.015), OPEN_COLOR)
	_material.set_shader_parameter(&"flash", _flash)
	_material.set_shader_parameter(&"flash_color", _flash_color)
	if _move_left > 0.0:
		_move_left -= delta
		velocity = _move_velocity
	else:
		velocity = Vector3.ZERO
	# A defeated creature does nothing until its room restarts (the dummy
	# gets up by itself, see acts_when_defeated).
	if not is_alive() and not acts_when_defeated():
		velocity = Vector3.ZERO
		return
	# Creatures wait while Ottavia has no control (fades, passages, restarts).
	var player: OttaviaProto = find_player()
	if player == null or player.controls_enabled:
		_behave(delta)
	elif not is_being_moved():
		velocity = Vector3.ZERO
	move_and_slide()


## Knockback, pulls and pushes: a short slide covering `offset`.
func _move_by(offset: Vector3) -> void:
	_move_velocity = offset / MOVE_SETTLE_SECONDS
	_move_left = MOVE_SETTLE_SECONDS


## Attacks the current target (see find_target) if it is within `reach`
## (flat distance); returns how it ended, or -1 when it was out of reach.
func attack_player(damage: float, reach: float, deflectable: bool = true) -> int:
	var target: Node3D = find_target()
	if target == null or flat_distance_to(target.global_position) > reach:
		return -1
	var attack: CombatAttack = CombatAttack.new()
	attack.damage = damage * Difficulty.enemy_damage()
	attack.source = self
	attack.deflectable = deflectable
	if target is OttaviaProto:
		var player: OttaviaProto = target
		if player.health <= 0.0:
			return -1
		return player.combat.receive_attack(attack)
	return target.call(&"receive_attack", attack)


## Who the creature goes for: the forced target, or the nearest fighter on
## its feet (Ottavia, or Enea when he is closer, 81).
func find_target() -> Node3D:
	if target_override != null and is_instance_valid(target_override):
		return target_override
	var best: Node3D = find_player()
	if not targets_companions():
		return best
	var best_distance: float = flat_distance_to(best.global_position) if best != null else INF
	for node: Node in get_tree().get_nodes_in_group(&"fighters"):
		var fighter: Node3D = node as Node3D
		if fighter == null or not fighter.call(&"can_be_attacked"):
			continue
		var distance: float = flat_distance_to(fighter.global_position)
		if distance < best_distance:
			best = fighter
			best_distance = distance
	return best


## Seconds until the telegraphed attack lands, INF when none is coming
## (read by the bot of the videos and by tests).
func attack_in() -> float:
	return INF


## Whether the coming attack can be deflected; if not, it must be dodged.
func attack_deflectable() -> bool:
	return true


## Which way to step to dodge the coming attack, for a fighter at `from`.
func dodge_direction(from: Vector3) -> Vector3:
	return flat_direction_to(from)


## From which side the creature is best struck: the direction from the
## creature toward the spot to attack from, for a fighter at `from`.
func weak_side(from: Vector3) -> Vector3:
	return flat_direction_to(from)


## Bosses go for Ottavia only.
func targets_companions() -> bool:
	return true


## True while a knockback, pull or push is moving the creature.
func is_being_moved() -> bool:
	return _move_left > 0.0


func flat_distance_to(point: Vector3) -> float:
	return Vector2(point.x - global_position.x, point.z - global_position.z).length()


## Horizontal unit vector toward `point`.
func flat_direction_to(point: Vector3) -> Vector3:
	return OttaviaCombat._flat_direction(point - global_position)


# --- For subclasses ----------------------------------------------------------

## False: once defeated the creature stops acting (and stops colliding)
## until reset_enemy(). The training dummy overrides it to get up again.
func acts_when_defeated() -> bool:
	return false


func _become_defeated() -> void:
	velocity = Vector3.ZERO
	_move_left = 0.0
	if not acts_when_defeated():
		collision_layer = 0
		collision_mask = 0


## Bosses show their health in the HUD instead.
func shows_health_bar() -> bool:
	return true


## Multiplier for an incoming hit (weak sides, armor plates, shells).
func damage_multiplier(_hit: CombatHit) -> float:
	return 1.0


func _on_reset() -> void:
	pass


## Per-frame behaviour; may set `velocity` before move_and_slide.
func _behave(_delta: float) -> void:
	pass


func _on_hit(_hit: CombatHit) -> void:
	pass


func _on_staggered() -> void:
	pass


func _on_defeated() -> void:
	pass


## Ottavia, or null.
func find_player() -> OttaviaProto:
	return get_tree().get_first_node_in_group(&"player") as OttaviaProto
