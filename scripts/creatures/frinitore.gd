class_name Frinitore
extends CombatEnemy
## B38 Frinitore: a swarm of chirping insects, a cloud about 1.5 m across
## floating at chest height (chapter 1). Whoever stands inside loses 3
## health a second; every strike thins the cloud (4 base strikes). Its song
## grows toward the warm side, the west (sound in phase 4b step 5).

const COLOR: Color = Color(0.86, 0.8, 0.45)
const FLOAT_HEIGHT: float = 0.9
const HEIGHT_PIXELS: int = 45
## Damage is counted and shown every this long, not every frame.
const TICK_SECONDS: float = 0.5

@export var creature: CreatureTuning

var _tick: float = 0.0
var _drift_time: float = 0.0


func _init() -> void:
	creature = preload("res://assets/combat/creature_tuning.tres")
	world_side = &"day"
	PlaceholderSprite.build_body(self, 0.6, 1.2, PlaceholderSprite.texture(45, HEIGHT_PIXELS, COLOR, "cloud"), HEIGHT_PIXELS)


func _ready() -> void:
	max_health = CreatureTuning.health_for_hits(creature.frinitore_hits)
	super._ready()
	# It floats: nothing bumps into it, strikes still reach it.
	collision_mask = 0
	sprite.position.y = FLOAT_HEIGHT - 0.6


## Radius of the cloud now: thinner with every strike.
func cloud_radius() -> float:
	return creature.frinitore_diameter * 0.5 * (0.5 + 0.5 * health / maxf(max_health, 0.01))


func _behave(delta: float) -> void:
	_drift_time += delta
	var player: OttaviaProto = find_player()
	if player == null:
		return
	var move: Vector3 = Vector3.ZERO
	var distance: float = flat_distance_to(player.global_position)
	if distance < creature.frinitore_aggro and player.health > 0.0:
		if distance > 0.2:
			move = flat_direction_to(player.global_position) * creature.frinitore_speed
	else:
		# Hovers around its place, leaning to the warm side.
		var wander: Vector3 = spawn_transform.origin + Vector3(sin(_drift_time * 0.7) * 1.2 - 0.5, 0.0, cos(_drift_time * 0.5) * 0.8)
		move = flat_direction_to(wander) * creature.frinitore_speed * 0.5
	if not is_being_moved() and not is_staggered():
		velocity = move
	var scale_now: float = cloud_radius() / (creature.frinitore_diameter * 0.5)
	sprite.scale = Vector3.ONE * scale_now
	sprite.modulate.a = 0.55 + 0.45 * health / maxf(max_health, 0.01)
	if distance <= cloud_radius() + 0.3 and player.health > 0.0:
		_tick += delta
		if _tick >= TICK_SECONDS:
			_tick = 0.0
			player.take_damage(creature.frinitore_damage_per_second * TICK_SECONDS * Difficulty.enemy_damage() * player.combat.patch_damage_taken(self))
			player.flash(0.5, Color(1.0, 0.85, 0.5))
	else:
		_tick = 0.0


func _on_defeated() -> void:
	sprite.visible = false


func _on_reset() -> void:
	sprite.scale = Vector3.ONE
	sprite.modulate.a = 1.0
