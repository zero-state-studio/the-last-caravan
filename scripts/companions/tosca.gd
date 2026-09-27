class_name Tosca
extends Node3D
## Tosca, the Frost-worker (79, 20), as a companion called in a fight: she
## appears beside Ottavia, hooks the nearest creature in front of her with
## the ice grappling hook and drags it close; heavy creatures and bosses only
## stagger. Then she needs `tosca_cooldown` seconds. Present only in the
## chapters where she travels with Ottavia.

const CHAIN_COLOR: Color = Color(0.8, 0.85, 0.95, 1.0)
const SHOW_SECONDS: float = 1.2
const FRONT_DEGREES: float = 100.0

@export var tuning: CombatTuning

var present: bool = true
var _cooldown_left: float = 0.0
var _show_left: float = 0.0

@onready var sprite: Sprite3D = $Sprite3D


func _ready() -> void:
	sprite.visible = false
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = preload("res://scenes/proto/materials/sprite_billboard_lit.gdshader")
	material.set_shader_parameter(&"sprite_texture", sprite.texture)
	sprite.material_override = material


## 0 = ready, 1 = just used.
func cooldown_ratio() -> float:
	return clampf(_cooldown_left / maxf(tuning.tosca_cooldown, 0.01), 0.0, 1.0)


func is_ready() -> bool:
	return present and _cooldown_left <= 0.0


## Called by the Call action (33). Returns false if she could not help.
func call_in() -> bool:
	var hud: CombatHud = get_tree().get_first_node_in_group(&"combat_hud") as CombatHud
	if not is_ready():
		if hud != null:
			hud.show_message(&"COMPANION_NOT_READY")
		return false
	var player: OttaviaProto = get_tree().get_first_node_in_group(&"player") as OttaviaProto
	var target: CombatEnemy = _target(player)
	if target == null:
		if hud != null:
			hud.show_message(&"COMPANION_NO_TARGET")
		return false
	_cooldown_left = tuning.tosca_cooldown
	_show_left = SHOW_SECONDS
	var side: Vector3 = player.facing_vector().rotated(Vector3.UP, PI * 0.5)
	global_position = player.global_position + side * 1.1
	sprite.visible = true
	SoundBank.play_sound(get_tree(), &"rampone_tosca", 0.0)
	var toward: Vector3 = OttaviaCombat._flat_direction(target.global_position - global_position)
	var length: float = Vector2(target.global_position.x - global_position.x, target.global_position.z - global_position.z).length()
	CombatEffects.ground_line(get_tree().current_scene, global_position + Vector3.UP * 0.9, toward, length, 0.15, CHAIN_COLOR, 0.35)
	var hit: CombatHit = CombatHit.new()
	hit.kind = CombatHit.Kind.HOOK_PULL
	hit.source = self
	hit.direction = toward
	hit.damage = tuning.tosca_damage
	target.receive_hit(hit)
	if target.heavy or target is BossEnemy:
		target.stagger(tuning.tosca_heavy_stagger)
	else:
		target.pull_to(player.global_position + player.facing_vector() * tuning.tosca_pull_distance)
	HitFeedback.hitstop(get_tree(), tuning.hitstop_seconds)
	HitFeedback.shake(get_tree(), tuning.shake_meters)
	return true


func _process(delta: float) -> void:
	_cooldown_left = maxf(0.0, _cooldown_left - delta)
	if _show_left > 0.0:
		_show_left -= delta
		if _show_left <= 0.0:
			sprite.visible = false


## The nearest creature within range, in front of Ottavia.
func _target(player: OttaviaProto) -> CombatEnemy:
	var best: CombatEnemy = null
	var best_distance: float = tuning.tosca_range
	for node: Node in get_tree().get_nodes_in_group(&"combat_targets"):
		var creature: CombatEnemy = node as CombatEnemy
		if creature == null or not creature.can_be_targeted() or creature is TrainingDummy:
			continue
		var offset: Vector3 = creature.global_position - player.global_position
		offset.y = 0.0
		var distance: float = offset.length()
		if distance > best_distance:
			continue
		if distance > 0.01 and rad_to_deg(player.facing_vector().angle_to(offset / distance)) > FRONT_DEGREES:
			continue
		best = creature
		best_distance = distance
	return best
