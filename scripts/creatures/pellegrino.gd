class_name Pellegrino
extends CombatEnemy
## B2 Pellegrino di feltro: a big wanderer wrapped in felt (chapter 1, 2 m),
## met only in the Truce, asleep by the frozen pond. It does not attack
## unless provoked: the first creature that can also be left alone. First
## the felt takes 3 base strikes, then the body 4; it pushes in front with
## 0.8 s of warning for 15.

enum Phase { ASLEEP, APPROACH, WINDUP, ACTIVE, COOLDOWN }

const FELT_COLOR: Color = Color(0.55, 0.45, 0.5)
const BODY_COLOR: Color = Color(0.62, 0.5, 0.42)
const TELEGRAPH_COLOR: Color = Color(1.0, 0.6, 0.3)
const HEIGHT_PIXELS: int = 60
const LOOK: String = "res://assets/sprites/creatures/c01/pellegrino"
const LOOK_RATES: Dictionary = {"idle": 1.0, "sleep": 3.0, "walk": 6.0, "attack": 10.0, "defeat": 8.0}
## Without its felt the drawn wrap takes the colour of the body under it.
const BODY_DARK: Color = Color(0.3, 0.2, 0.15)
const BODY_LIGHT: Color = Color(0.78, 0.62, 0.48)
const BODY_DYE: float = 0.55

@export var creature: CreatureTuning

var phase: Phase = Phase.ASLEEP
var felt_left: float = 0.0
var _body_shown: bool = false
var _time: float = 0.0


func _init() -> void:
	creature = preload("res://assets/combat/creature_tuning.tres")
	world_side = &"night"
	heavy = true
	PlaceholderSprite.build_body(self, 0.7, 2.0, PlaceholderSprite.texture(36, HEIGHT_PIXELS, FELT_COLOR, "tall"), HEIGHT_PIXELS)


func _ready() -> void:
	max_health = CreatureTuning.health_for_hits(creature.pellegrino_felt_hits + creature.pellegrino_body_hits)
	super._ready()
	use_look(LOOK, LOOK_RATES)
	felt_left = CreatureTuning.health_for_hits(creature.pellegrino_felt_hits)


func is_provoked() -> bool:
	return phase != Phase.ASLEEP


func has_felt() -> bool:
	return felt_left > 0.0


func is_exposed() -> bool:
	return phase == Phase.COOLDOWN and _time < 0.7 or super.is_exposed()


func attack_in() -> float:
	if phase == Phase.WINDUP:
		return maxf(0.0, creature.pellegrino_windup * Difficulty.telegraph() - _time)
	return INF


func _on_hit(_hit: CombatHit) -> void:
	# The felt goes first: once its share is gone, the body shows.
	var felt_share: float = CreatureTuning.health_for_hits(creature.pellegrino_felt_hits)
	felt_left = maxf(0.0, felt_share - (max_health - health))
	if felt_left <= 0.0:
		if look == null:
			sprite.texture = PlaceholderSprite.texture(32, HEIGHT_PIXELS, BODY_COLOR, "tall")
			_material.set_shader_parameter(&"sprite_texture", sprite.texture)
		elif not _body_shown:
			_show_body()
	if phase == Phase.ASLEEP:
		_set_phase(Phase.APPROACH)


func _behave(delta: float) -> void:
	_time += delta
	var target: Node3D = find_target()
	var player: OttaviaProto = find_player()
	var move: Vector3 = Vector3.ZERO
	if target == null or player == null or phase == Phase.ASLEEP:
		velocity = Vector3.ZERO
		return
	var distance: float = flat_distance_to(target.global_position)
	match phase:
		Phase.APPROACH:
			if player.health <= 0.0 or distance > creature.leash_distance:
				_set_phase(Phase.ASLEEP)
			elif distance <= creature.pellegrino_range:
				_set_phase(Phase.WINDUP)
			else:
				move = flat_direction_to(target.global_position) * creature.pellegrino_speed
		Phase.WINDUP:
			flash(0.3 + 0.4 * _time / maxf(creature.pellegrino_windup * Difficulty.telegraph(), 0.01), TELEGRAPH_COLOR)
			if _time >= creature.pellegrino_windup * Difficulty.telegraph():
				_set_phase(Phase.ACTIVE)
				var toward: Vector3 = flat_direction_to(target.global_position)
				CombatEffects.swing(get_tree().current_scene, global_position + Vector3.UP * 1.0, toward, creature.pellegrino_range, 90.0, Color(0.9, 0.85, 0.8, 0.9))
				attack_player(creature.pellegrino_damage, creature.pellegrino_range)
		Phase.ACTIVE:
			if _time >= 0.2:
				_set_phase(Phase.COOLDOWN)
		Phase.COOLDOWN:
			if _time >= creature.pellegrino_cooldown:
				_set_phase(Phase.APPROACH)
	if look == null:
		sprite.flip_h = flat_direction_to(target.global_position).x > 0.0
	if not is_being_moved() and not is_staggered():
		velocity = move


func look_animation() -> String:
	if not is_alive():
		return "defeat"
	match phase:
		Phase.ASLEEP:
			return "sleep"
		Phase.WINDUP, Phase.ACTIVE:
			return "attack"
		Phase.APPROACH:
			return "walk" if velocity.length() > 0.2 else "idle"
	return "idle"


## The felt torn off: bits of felt fly and the wrap shows the body's
## colour (the dye of the sprite shader over the whole figure).
func _show_body() -> void:
	_body_shown = true
	CombatEffects.spark(get_tree().current_scene, global_position + Vector3.UP * 1.2, FELT_COLOR, 24.0)
	var full: Image = Image.create(1, 1, false, Image.FORMAT_L8)
	full.fill(Color.WHITE)
	_material.set_shader_parameter(&"garment_mask", ImageTexture.create_from_image(full))
	_material.set_shader_parameter(&"garment_dark", Vector3(BODY_DARK.r, BODY_DARK.g, BODY_DARK.b))
	_material.set_shader_parameter(&"garment_light", Vector3(BODY_LIGHT.r, BODY_LIGHT.g, BODY_LIGHT.b))
	_material.set_shader_parameter(&"garment_fade", 0.0)
	_material.set_shader_parameter(&"garment_strength", BODY_DYE)


func _on_defeated() -> void:
	sprite.visible = look != null


func _on_reset() -> void:
	felt_left = CreatureTuning.health_for_hits(creature.pellegrino_felt_hits)
	_body_shown = false
	_material.set_shader_parameter(&"garment_strength", 0.0)
	if look == null:
		sprite.texture = PlaceholderSprite.texture(36, HEIGHT_PIXELS, FELT_COLOR, "tall")
		_material.set_shader_parameter(&"sprite_texture", sprite.texture)
	_set_phase(Phase.ASLEEP)


func _set_phase(new_phase: Phase) -> void:
	phase = new_phase
	_time = 0.0
