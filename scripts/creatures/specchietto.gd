class_name Specchietto
extends CombatEnemy
## B32 Specchietto: a tiny lizard with mirror scales that basks on warm
## stones (chapter 1, 0.4 m, 12 px). Only when the sun is on it and Ottavia
## is within 8 m it flashes: 0.5 s of warning, then she is dazzled for
## 1.2 s, slower and without aim assist. In the shade it hides and cannot
## be hit. One strike. The flash follows the option that reduces flashes
## (96): the white glare is scaled by it, the effect stays.

enum Phase { BASK, WINDUP, COOLDOWN, HIDDEN }

const COLOR: Color = Color(0.7, 0.85, 0.9)
const GLINT_COLOR: Color = Color(1.0, 1.0, 0.9)
const HEIGHT_PIXELS: int = 12

@export var creature: CreatureTuning

var phase: Phase = Phase.BASK
var _time: float = 0.0


func _init() -> void:
	creature = preload("res://assets/combat/creature_tuning.tres")
	world_side = &"day"
	is_small = true
	PlaceholderSprite.build_body(self, 0.22, 0.3, PlaceholderSprite.texture(20, HEIGHT_PIXELS, COLOR), HEIGHT_PIXELS)


func _ready() -> void:
	max_health = CreatureTuning.health_for_hits(creature.specchietto_hits)
	super._ready()


func can_be_targeted() -> bool:
	return super.can_be_targeted() and phase != Phase.HIDDEN


## True when nothing stands between it and the sun (shadows, 51).
func in_sunlight() -> bool:
	var exclude: Array[RID] = [get_rid()]
	var player: OttaviaProto = find_player()
	if player != null:
		exclude.append(player.get_rid())
	return SunLight.is_lit(self, global_position + Vector3.UP * 0.2, exclude)


func attack_in() -> float:
	if phase == Phase.WINDUP:
		return maxf(0.0, creature.specchietto_windup * Difficulty.telegraph() - _time)
	return INF


func _behave(delta: float) -> void:
	_time += delta
	var player: OttaviaProto = find_player()
	if player == null:
		return
	var lit: bool = in_sunlight()
	var distance: float = flat_distance_to(player.global_position)
	match phase:
		Phase.BASK:
			if not lit:
				_set_phase(Phase.HIDDEN)
			elif distance <= creature.specchietto_range and player.health > 0.0:
				_set_phase(Phase.WINDUP)
		Phase.WINDUP:
			flash(0.4 + 0.6 * _time / maxf(creature.specchietto_windup * Difficulty.telegraph(), 0.01), GLINT_COLOR)
			if not lit:
				_set_phase(Phase.HIDDEN)
			elif _time >= creature.specchietto_windup * Difficulty.telegraph():
				_flash_at(player)
				_set_phase(Phase.COOLDOWN)
		Phase.COOLDOWN:
			if not lit:
				_set_phase(Phase.HIDDEN)
			elif _time >= creature.specchietto_cooldown:
				_set_phase(Phase.BASK)
		Phase.HIDDEN:
			if lit and _time > 0.5:
				_set_phase(Phase.BASK)
	sprite.visible = phase != Phase.HIDDEN and is_alive()
	velocity = Vector3.ZERO


## The dazzle, if Ottavia is still in range and looking its way.
func _flash_at(player: OttaviaProto) -> void:
	if flat_distance_to(player.global_position) > creature.specchietto_range:
		return
	player.combat.dazzle_by_flash(creature.specchietto_dazzle_seconds, creature.specchietto_dazzle_speed)
	var screen: CanvasLayer = CanvasLayer.new()
	screen.layer = 30
	var glare: ColorRect = ColorRect.new()
	glare.set_anchors_preset(Control.PRESET_FULL_RECT)
	glare.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glare.color = Color(1.0, 1.0, 0.95, 0.75 * GameOptions.flash_strength)
	screen.add_child(glare)
	get_tree().current_scene.add_child(screen)
	var tween: Tween = screen.create_tween()
	tween.tween_property(glare, "color:a", 0.0, creature.specchietto_dazzle_seconds)
	tween.tween_callback(screen.queue_free)


func _on_defeated() -> void:
	sprite.visible = false


func _on_reset() -> void:
	_set_phase(Phase.BASK)


func _set_phase(new_phase: Phase) -> void:
	phase = new_phase
	_time = 0.0
