class_name Brinacchio
extends CombatEnemy
## B1 Brinacchio: a fist-sized parasite of the Twilight Margin (89) that
## clings to warm animals. It comes in swarms, drawn by the heat of the
## lantern: with the shutter open it senses Ottavia from far away, and
## closing it makes the swarm lose her track (36). Clinging, it slows her and
## drains a little health. A sidestep shakes them all off, a strike knocks
## one off. Coming off, it crusts over with frost: the crust blocks strikes
## until the hook tears it or it melts.

enum Phase { WANDER, CHASE, LATCHED, CRUSTED }

const CRUST_COLOR: Color = Color(0.85, 0.92, 1.0)
const WANDER_RADIUS: float = 1.2

## Parasites clinging to Ottavia right now (they share one slowdown).
static var latched: Array[Brinacchio] = []

@export var creature: CreatureTuning

var phase: Phase = Phase.WANDER
var _time: float = 0.0
var _latch_offset: Vector3 = Vector3.ZERO
var _wander_goal: Vector3
var _connected: bool = false


func _ready() -> void:
	max_health = creature.brinacchio_health
	is_small = true
	radius = 0.2
	super._ready()
	_wander_goal = global_position


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
				_set_phase(Phase.CHASE)
	if not is_being_moved():
		velocity = move
	sprite.flip_h = velocity.x > 0.1


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
	player.combat.stepped.connect(_on_stepped)
	player.combat.struck.connect(_on_struck)


func _on_stepped() -> void:
	detach()


func _on_struck() -> void:
	# One strike knocks off one parasite: the first of the list.
	if not latched.is_empty() and latched[0] == self:
		detach()


func _update_slowdown(player: OttaviaProto) -> void:
	player.combat.slowdown = minf(latched.size() * creature.brinacchio_slow, creature.brinacchio_max_slow)


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
