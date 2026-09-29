class_name Frinitore
extends CombatEnemy
## B38 Frinitore: a swarm of chirping insects, a cloud about 1.5 m across
## floating at chest height (chapter 1). Whoever stands inside loses 3
## health a second; every strike thins the cloud (4 base strikes). It
## follows the warmth, not the prey: slowly toward the sunlit spots of the
## room; toward Ottavia only while she is in the sun within 6 m; in the
## shade it loses her, so the turning terraces steer it too. Its song grows
## toward the warm side, the west (sound in phase 4b step 5).

const COLOR: Color = Color(0.86, 0.8, 0.45)
const FLOAT_HEIGHT: float = 0.9
const HEIGHT_PIXELS: int = 45
## Damage is counted and shown every this long, not every frame.
const TICK_SECONDS: float = 0.5
## It looks for warmth this often.
const THINK_SECONDS: float = 0.5
const SEARCH_DIRECTIONS: int = 8

@export var creature: CreatureTuning

var _tick: float = 0.0
var _drift_time: float = 0.0
var _think_left: float = 0.0
var _goal: Vector3 = Vector3.ZERO


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


## Where it wants to be: Ottavia if she is in the sun and near; itself if
## it is in the sun; otherwise the nearest sunlit spot around, else west
## (toward the warm side).
func _choose_goal(player: OttaviaProto, distance: float) -> Vector3:
	var exclude: Array[RID] = [get_rid(), player.get_rid()]
	if player.health > 0.0 and distance <= creature.frinitore_aggro and SunLight.is_lit(self, player.global_position + Vector3.UP * 0.9, exclude):
		return player.global_position
	if SunLight.is_lit(self, global_position + Vector3.UP * FLOAT_HEIGHT, exclude):
		return global_position
	for step: int in [1, 2]:
		for index: int in SEARCH_DIRECTIONS:
			var angle: float = PI + TAU * index / SEARCH_DIRECTIONS
			var spot: Vector3 = global_position + Vector3(cos(angle), 0.0, sin(angle)) * creature.frinitore_search_meters * step * 0.5
			if SunLight.is_lit(self, spot + Vector3.UP * FLOAT_HEIGHT, exclude):
				return spot
	return global_position + Vector3.LEFT * creature.frinitore_search_meters


func in_sunlight() -> bool:
	return SunLight.is_lit(self, global_position + Vector3.UP * FLOAT_HEIGHT, [get_rid()])


## Radius of the cloud now: thinner with every strike.
func cloud_radius() -> float:
	return creature.frinitore_diameter * 0.5 * (0.5 + 0.5 * health / maxf(max_health, 0.01))


func _behave(delta: float) -> void:
	_drift_time += delta
	var player: OttaviaProto = find_player()
	if player == null:
		return
	var distance: float = flat_distance_to(player.global_position)
	_think_left -= delta
	if _think_left <= 0.0:
		_think_left = THINK_SECONDS
		_goal = _choose_goal(player, distance)
	var move: Vector3 = Vector3.ZERO
	if flat_distance_to(_goal) > 0.2:
		move = flat_direction_to(_goal) * creature.frinitore_speed
	else:
		# In the sun it hovers where it is, with a slow sway.
		move = Vector3(sin(_drift_time * 0.9), 0.0, cos(_drift_time * 0.7)) * creature.frinitore_speed * 0.25
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
