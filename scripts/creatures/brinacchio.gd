class_name Brinacchio
extends CombatEnemy
## B1 Brinacchio: a fist-sized parasite of the Twilight Margin (89) that
## clings to warm animals. It comes in swarms, drawn by the heat of the
## lantern: with the shutter open it senses Ottavia from far away, and
## closing it makes the swarm lose her track (36). Clinging, it slows her and
## drains a little health. A sidestep shakes them all off, a strike knocks
## one off. Coming off, it crusts over with frost and lies on the ground: a
## strike of the staff cracks the crust (the hook tears it too) and leaves it
## stunned, so the next strike defeats it; left alone, the crust melts.

enum Phase { WANDER, CHASE, LATCHED, CRUSTED, STUNNED }

const CRUST_COLOR: Color = Color(0.85, 0.92, 1.0)
## Cracked out of its crust, it lies stunned this long before chasing again.
const STUN_SECONDS: float = 1.6
const WANDER_RADIUS: float = 1.2
## Fist-sized, so it needs help to be seen (B1): a pale outline, a frost
## glint, a shadow on the ground and a trail of frost where it runs.
const OUTLINE_COLOR: Color = Color(0.86, 0.95, 1.0)
const GLINT_COLOR: Color = Color(0.7, 0.85, 1.0)
const TRAIL_STEP_METERS: float = 0.35
const TRAIL_SECONDS: float = 1.6
const TRAIL_MAX: int = 8

## Parasites clinging to Ottavia right now (they share one slowdown).
static var latched: Array[Brinacchio] = []

@export var creature: CreatureTuning

var phase: Phase = Phase.WANDER
var _time: float = 0.0
var _latch_offset: Vector3 = Vector3.ZERO
var _wander_goal: Vector3
var _connected: bool = false
var _trail_from: Vector3
var _trail: Array[Sprite3D] = []


func _ready() -> void:
	max_health = creature.brinacchio_health
	is_small = true
	radius = 0.2
	super._ready()
	_wander_goal = global_position
	_material.set_shader_parameter(&"outline_color", OUTLINE_COLOR)
	var glint: OmniLight3D = OmniLight3D.new()
	glint.light_color = GLINT_COLOR
	glint.light_energy = 0.6
	glint.omni_range = 1.4
	glint.position = Vector3.UP * 0.25
	add_child(glint)
	var shadow: Sprite3D = _ground_disc(Color(0.05, 0.05, 0.1, 0.45), 0.42)
	add_child(shadow)
	_trail_from = global_position


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not is_alive() or phase == Phase.LATCHED:
		return
	var moved: Vector3 = global_position - _trail_from
	moved.y = 0.0
	if moved.length() >= TRAIL_STEP_METERS:
		_trail_from = global_position
		_leave_frost()


## A pale patch of frost left on the ground, fading out.
func _leave_frost() -> void:
	var scene: Node = get_tree().current_scene
	if scene == null:
		return
	# Patches free themselves when faded: drop those first.
	_trail = _trail.filter(func(patch: Variant) -> bool: return is_instance_valid(patch))
	if _trail.size() >= TRAIL_MAX:
		var oldest: Variant = _trail.pop_front()
		(oldest as Node).queue_free()
	var patch: Sprite3D = _ground_disc(Color(0.85, 0.93, 1.0, 0.55), 0.3)
	scene.add_child(patch)
	patch.global_position = Vector3(global_position.x, 0.02, global_position.z)
	_trail.append(patch)
	var tween: Tween = patch.create_tween()
	tween.tween_property(patch, "modulate:a", 0.0, TRAIL_SECONDS)
	tween.tween_callback(patch.queue_free)


## A flat disc on the ground, `size` metres across.
static func _ground_disc(color: Color, size: float) -> Sprite3D:
	var disc: Sprite3D = Sprite3D.new()
	var image: Image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	for y: int in 8:
		for x: int in 8:
			var inside: bool = Vector2(x - 3.5, y - 3.5).length() < 3.6
			image.set_pixel(x, y, Color(1, 1, 1, 1) if inside else Color(1, 1, 1, 0))
	disc.texture = ImageTexture.create_from_image(image)
	disc.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	disc.pixel_size = size / 8.0
	disc.modulate = color
	disc.shaded = false
	disc.transparent = true
	disc.rotation.x = -PI * 0.5
	disc.position = Vector3.UP * 0.02
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return disc


func can_be_targeted() -> bool:
	return is_alive() and phase != Phase.LATCHED


func _behave(delta: float) -> void:
	_time += delta
	var player: OttaviaProto = find_player()
	if player == null:
		return
	_connect(player)
	var distance: float = flat_distance_to(player.global_position)
	var sense: float = creature.brinacchio_lantern_aggro if player.lantern_open else creature.brinacchio_aggro
	var move: Vector3 = Vector3.ZERO
	match phase:
		Phase.WANDER:
			if flat_distance_to(_wander_goal) < 0.15 or _time > 2.0:
				_time = 0.0
				var angle: float = randf() * TAU
				_wander_goal = spawn_transform.origin + Vector3(cos(angle), 0.0, sin(angle)) * randf() * WANDER_RADIUS
			move = flat_direction_to(_wander_goal) * creature.brinacchio_speed * 0.3
			if distance < sense and player.health > 0.0:
				_set_phase(Phase.CHASE)
		Phase.CHASE:
			var lost: bool = not player.lantern_open and distance > creature.brinacchio_lose_track
			if lost or distance > creature.leash_distance or player.health <= 0.0:
				_wander_goal = global_position
				_set_phase(Phase.WANDER)
			elif distance <= creature.brinacchio_latch_range:
				_latch(player)
			else:
				move = flat_direction_to(player.global_position) * creature.brinacchio_speed
		Phase.LATCHED:
			global_position = player.global_position + _latch_offset
			if creature.brinacchio_latch_damage_per_second > 0.0:
				player.take_damage(creature.brinacchio_latch_damage_per_second * delta)
			velocity = Vector3.ZERO
			return
		Phase.CRUSTED:
			flash(0.45, CRUST_COLOR)
			if not has_shield or _time >= creature.brinacchio_crust_seconds:
				has_shield = false
				_set_phase(Phase.STUNNED)
		Phase.STUNNED:
			if _time >= STUN_SECONDS:
				_set_phase(Phase.CHASE)
	if not is_being_moved():
		velocity = move
	sprite.flip_h = velocity.x > 0.1


## A strike on the crust cracks it: ice chips, and the parasite lies there
## stunned for the next strike.
func receive_hit(hit: CombatHit) -> void:
	if phase == Phase.CRUSTED and has_shield and hit.kind == CombatHit.Kind.STRIKE:
		has_shield = false
		SoundBank.play_sound(get_tree(), &"crosta_spezza")
		CombatEffects.spark(get_tree().current_scene, global_position + Vector3.UP * 0.2, CRUST_COLOR, 12.0)
		flash(1.0, CRUST_COLOR)
		_set_phase(Phase.STUNNED)
		return
	super.receive_hit(hit)


func _latch(player: OttaviaProto) -> void:
	_set_phase(Phase.LATCHED)
	var angle: float = randf() * TAU
	_latch_offset = Vector3(cos(angle) * 0.25, 0.6 + randf() * 0.5, sin(angle) * 0.1 + 0.05)
	collision_layer = 0
	collision_mask = 0
	latched.append(self)
	_update_slowdown(player)
	# Say it the first time one clings: they are small and easy to miss.
	if latched.size() == 1:
		player.combat.message.emit(&"COMBAT_CLINGING")


## Comes off Ottavia with a frost crust, thrown a little away.
func detach() -> void:
	if phase != Phase.LATCHED:
		return
	latched.erase(self)
	var player: OttaviaProto = find_player()
	if player != null:
		_update_slowdown(player)
		global_position = Vector3(player.global_position.x, spawn_transform.origin.y, player.global_position.z)
	collision_layer = 1
	collision_mask = 1
	has_shield = true
	_set_phase(Phase.CRUSTED)
	var angle: float = randf() * TAU
	_move_by(Vector3(cos(angle), 0.0, sin(angle)) * 1.2)
	flash(1.0, CRUST_COLOR)


func _connect(player: OttaviaProto) -> void:
	if _connected:
		return
	_connected = true
	player.combat.jumped.connect(_on_jumped)
	player.combat.struck.connect(_on_struck)


func _on_jumped() -> void:
	detach()


func _on_struck() -> void:
	# One strike knocks off one parasite: the first of the list.
	if not latched.is_empty() and latched[0] == self:
		detach()


func _update_slowdown(player: OttaviaProto) -> void:
	var patch: float = CoatPatches.COLD_SLOW if player.combat.has_patch(&"cold") else 1.0
	player.combat.slowdown = minf(latched.size() * creature.brinacchio_slow, creature.brinacchio_max_slow) * patch


func _on_defeated() -> void:
	sprite.visible = false


func _on_reset() -> void:
	if phase == Phase.LATCHED:
		latched.erase(self)
		var player: OttaviaProto = find_player()
		if player != null:
			_update_slowdown(player)
	collision_layer = 1
	collision_mask = 1
	has_shield = false
	_set_phase(Phase.WANDER)


func _exit_tree() -> void:
	latched.erase(self)


func _set_phase(new_phase: Phase) -> void:
	phase = new_phase
	_time = 0.0
