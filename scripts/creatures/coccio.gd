class_name Coccio
extends CombatEnemy
## B39 Coccio: a small, slow shelled creature of the fields (chapter 1,
## 0.5 m, 15 px). At every strike its shell shows one more crack; at the
## third it breaks. A pinch in front with 0.5 s of warning.

enum Phase { IDLE, APPROACH, WINDUP, ACTIVE, COOLDOWN }

const COLOR: Color = Color(0.72, 0.52, 0.36)
const TELEGRAPH_COLOR: Color = Color(1.0, 0.6, 0.3)
const HEIGHT_PIXELS: int = 15
const LOOK: String = "res://assets/sprites/creatures/c01/coccio"
const LOOK_RATES: Dictionary = {"walk": 7.0, "pinch": 12.0, "defeat": 10.0}
## The dark of a crack in the fired clay.
const CRACK_COLOR: Color = Color(0.04, 0.02, 0.02)
## Rows a crack runs down the shell, from its top.
const CRACK_LENGTH: int = 8
## Where each crack starts across the shell, as a share of its width.
const CRACK_PLACES: Array[float] = [0.28, 0.68, 0.48]

## Crack masks by strip and number of cracks, drawn once.
static var _crack_masks: Dictionary = {}

@export var creature: CreatureTuning

var phase: Phase = Phase.IDLE
var cracks: int = 0
var _time: float = 0.0


func _init() -> void:
	creature = preload("res://assets/combat/creature_tuning.tres")
	world_side = &"twilight"
	is_small = true
	PlaceholderSprite.build_body(self, 0.3, 0.5, PlaceholderSprite.texture(18, HEIGHT_PIXELS, COLOR), HEIGHT_PIXELS)


func _ready() -> void:
	max_health = CreatureTuning.health_for_hits(creature.coccio_hits)
	super._ready()
	use_look(LOOK, LOOK_RATES)


func is_exposed() -> bool:
	return phase == Phase.COOLDOWN and _time < 0.6 or super.is_exposed()


func attack_in() -> float:
	if phase == Phase.WINDUP:
		return maxf(0.0, creature.coccio_windup * Difficulty.telegraph() - _time)
	return INF


func _on_hit(_hit: CombatHit) -> void:
	# One crack for each base strike of damage taken.
	var taken: float = max_health - health
	var per_crack: float = max_health / maxf(creature.coccio_hits, 1.0)
	var new_cracks: int = mini(int(floor(taken / maxf(per_crack, 0.01) + 0.001)), int(creature.coccio_hits) - 1)
	if new_cracks != cracks:
		cracks = new_cracks
		if look == null:
			sprite.texture = PlaceholderSprite.texture(18, HEIGHT_PIXELS, COLOR, "round", cracks)
			_material.set_shader_parameter(&"sprite_texture", sprite.texture)
		CombatEffects.spark(get_tree().current_scene, global_position + Vector3.UP * 0.3, COLOR, 10.0)


func _behave(delta: float) -> void:
	_time += delta
	var target: Node3D = find_target()
	var player: OttaviaProto = find_player()
	if target == null or player == null:
		return
	var distance: float = flat_distance_to(target.global_position)
	var move: Vector3 = Vector3.ZERO
	match phase:
		Phase.IDLE:
			if distance < creature.coccio_aggro and player.health > 0.0:
				_set_phase(Phase.APPROACH)
		Phase.APPROACH:
			if distance > creature.leash_distance or player.health <= 0.0:
				_set_phase(Phase.IDLE)
			elif distance <= creature.coccio_attack_range:
				_set_phase(Phase.WINDUP)
			else:
				move = flat_direction_to(target.global_position) * creature.coccio_speed
		Phase.WINDUP:
			flash(0.3 + 0.4 * _time / maxf(creature.coccio_windup * Difficulty.telegraph(), 0.01), TELEGRAPH_COLOR)
			if _time >= creature.coccio_windup * Difficulty.telegraph():
				_set_phase(Phase.ACTIVE)
				CombatEffects.swing(get_tree().current_scene, global_position + Vector3.UP * 0.3, flat_direction_to(target.global_position), creature.coccio_attack_range, 60.0, Color(1.0, 0.8, 0.55, 0.85))
				attack_player(creature.coccio_damage, creature.coccio_attack_range + 0.2)
		Phase.ACTIVE:
			if _time >= 0.1:
				_set_phase(Phase.COOLDOWN)
		Phase.COOLDOWN:
			if _time >= creature.coccio_cooldown:
				_set_phase(Phase.APPROACH)
	if look == null:
		sprite.flip_h = flat_direction_to(target.global_position).x > 0.0
	if not is_being_moved() and not is_staggered():
		velocity = move


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_show_cracks()


func look_animation() -> String:
	if not is_alive():
		return "defeat"
	if phase == Phase.WINDUP or phase == Phase.ACTIVE:
		return "pinch"
	return "walk"


## The shell's cracks over the current strip (one more at every base
## strike): a mask of dark pixels on the upper part of the body, through
## the dye of the sprite shader.
func _show_cracks() -> void:
	if look == null or sprite.texture == null:
		return
	if cracks <= 0 or not is_alive():
		_material.set_shader_parameter(&"garment_strength", 0.0)
		return
	var key: String = "%s|%d" % [sprite.texture.resource_path, cracks]
	if not _crack_masks.has(key):
		_crack_masks[key] = _crack_mask(sprite.texture, cracks)
	_material.set_shader_parameter(&"garment_mask", _crack_masks[key])
	_material.set_shader_parameter(&"garment_dark", Vector3(CRACK_COLOR.r, CRACK_COLOR.g, CRACK_COLOR.b))
	_material.set_shader_parameter(&"garment_light", Vector3(CRACK_COLOR.r, CRACK_COLOR.g, CRACK_COLOR.b))
	_material.set_shader_parameter(&"garment_fade", 0.0)
	_material.set_shader_parameter(&"garment_strength", 1.0)


## White where a crack runs, cell by cell, at the same places of the body
## in every frame so the cracks stay put while it walks.
static func _crack_mask(strip: Texture2D, count: int) -> ImageTexture:
	var image: Image = strip.get_image()
	image.decompress()
	var mask: Image = Image.create(image.get_width(), image.get_height(), false, Image.FORMAT_L8)
	for cell: int in image.get_width() / CreatureLook.CELL:
		var left: int = cell * CreatureLook.CELL
		var used: Rect2i = image.get_region(Rect2i(left, 0, CreatureLook.CELL, CreatureLook.CELL)).get_used_rect()
		if used.size.x <= 0:
			continue
		for crack: int in count:
			var random: RandomNumberGenerator = RandomNumberGenerator.new()
			random.seed = 39 + crack
			# Apart from each other, slanting opposite ways.
			var x: int = left + used.position.x + int(used.size.x * CRACK_PLACES[crack % CRACK_PLACES.size()])
			var slant: int = 1 if crack % 2 == 0 else -1
			var y: int = used.position.y + 1
			for step: int in CRACK_LENGTH:
				if x >= left and x < left + CreatureLook.CELL and y < CreatureLook.CELL and image.get_pixel(x, y).a > 0.5:
					mask.set_pixel(x, y, Color.WHITE)
				y += 1
				if step % 2 == 1:
					x += slant
				x += random.randi_range(-1, 1) if step % 3 == 2 else 0
	return ImageTexture.create_from_image(mask)


func _on_defeated() -> void:
	sprite.visible = look != null
	# The third strike breaks the shell: shards of fired clay fly off.
	CombatEffects.spark(get_tree().current_scene, global_position + Vector3.UP * 0.3, COLOR, 26.0)


func _on_reset() -> void:
	cracks = 0
	if look == null:
		sprite.texture = PlaceholderSprite.texture(18, HEIGHT_PIXELS, COLOR)
		_material.set_shader_parameter(&"sprite_texture", sprite.texture)
	_set_phase(Phase.IDLE)


func _set_phase(new_phase: Phase) -> void:
	phase = new_phase
	_time = 0.0
