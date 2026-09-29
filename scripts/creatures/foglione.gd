class_name Foglione
extends SunFacingEnemy
## B33 Foglione: a big leafy beast of the Day side (chapter 1, 1.4 m,
## 42 px) that stands still feeding on light, calm until disturbed. Its
## closed leaves cover its front: frontal strikes bounce off. Its flank
## takes double damage; a turning terrace forces it to show it. When
## disturbed it strikes with its leaves in front (0.8 s of warning, 12).

enum Phase { CALM, ALERT, WINDUP, ACTIVE, COOLDOWN }

const COLOR: Color = Color(0.42, 0.62, 0.36)
const TELEGRAPH_COLOR: Color = Color(1.0, 0.6, 0.3)
const HEIGHT_PIXELS: int = 42

var phase: Phase = Phase.CALM
var _time: float = 0.0
var _calm_left: float = 0.0


func _init() -> void:
	creature = preload("res://assets/combat/creature_tuning.tres")
	world_side = &"day"
	heavy = true
	PlaceholderSprite.build_body(self, 0.6, 1.4, PlaceholderSprite.texture(40, HEIGHT_PIXELS, COLOR), HEIGHT_PIXELS)


func _ready() -> void:
	max_health = CreatureTuning.health_for_hits(creature.foglione_hits)
	super._ready()


## Front (toward its face): the leaves; the shaded right and the sunlit
## left are its flanks.
func damage_multiplier(hit: CombatHit) -> float:
	var from: Vector3 = -hit.direction
	if rad_to_deg(from.angle_to(facing)) <= creature.foglione_front_degrees:
		return 0.0
	if rad_to_deg(from.angle_to(shaded_side())) <= 60.0 or rad_to_deg(from.angle_to(-shaded_side())) <= 60.0:
		return creature.foglione_flank_multiplier
	return 1.0


## A strike on the closed leaves in front bounces off, with its own sound
## and spark (as the boss's), not the sound of a hit.
func receive_hit(hit: CombatHit) -> void:
	if is_alive() and damage_multiplier(hit) == 0.0:
		flash(0.6, RootedFoglione.BOUNCE_COLOR)
		CombatEffects.spark(get_tree().current_scene, global_position + Vector3.UP * 0.8 + facing * 0.7, RootedFoglione.BOUNCE_COLOR, 16.0)
		SoundBank.play_sound(get_tree(), RootedFoglione.BOUNCE_SOUND, 0.1)
		_disturb()
		return
	super.receive_hit(hit)


func _on_hit(_hit: CombatHit) -> void:
	_disturb()


func is_exposed() -> bool:
	return phase == Phase.COOLDOWN and _time < 0.6 or super.is_exposed()


func attack_in() -> float:
	if phase == Phase.WINDUP:
		return maxf(0.0, creature.foglione_windup * Difficulty.telegraph() - _time)
	return INF


func _disturb() -> void:
	_calm_left = creature.foglione_calm_seconds
	if phase == Phase.CALM:
		_set_phase(Phase.ALERT)


func _behave(delta: float) -> void:
	_time += delta
	velocity = Vector3.ZERO
	var target: Node3D = find_target()
	var player: OttaviaProto = find_player()
	if target == null or player == null:
		return
	var distance: float = flat_distance_to(target.global_position)
	var in_front: bool = rad_to_deg(flat_direction_to(target.global_position).angle_to(facing)) <= 75.0
	match phase:
		Phase.CALM:
			if player.health > 0.0 and in_front and distance <= creature.foglione_disturb_distance:
				_disturb()
		Phase.ALERT:
			_calm_left -= delta
			if _calm_left <= 0.0 or player.health <= 0.0:
				_set_phase(Phase.CALM)
			elif in_front and distance <= creature.foglione_range:
				_set_phase(Phase.WINDUP)
		Phase.WINDUP:
			flash(0.3 + 0.4 * _time / maxf(creature.foglione_windup * Difficulty.telegraph(), 0.01), TELEGRAPH_COLOR)
			if _time >= creature.foglione_windup * Difficulty.telegraph():
				_set_phase(Phase.ACTIVE)
				CombatEffects.swing(get_tree().current_scene, global_position + Vector3.UP * 0.8, facing, creature.foglione_range, 120.0, Color(0.8, 1.0, 0.6, 0.9))
				if rad_to_deg(flat_direction_to(target.global_position).angle_to(facing)) <= 60.0:
					attack_player(creature.foglione_damage, creature.foglione_range)
		Phase.ACTIVE:
			if _time >= 0.15:
				_set_phase(Phase.COOLDOWN)
		Phase.COOLDOWN:
			if _time >= creature.foglione_cooldown:
				_set_phase(Phase.ALERT)


func _on_defeated() -> void:
	sprite.visible = false


func _on_reset() -> void:
	super._on_reset()
	_calm_left = 0.0
	_set_phase(Phase.CALM)


func _set_phase(new_phase: Phase) -> void:
	phase = new_phase
	_time = 0.0
