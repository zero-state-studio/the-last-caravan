class_name GrappoloBit
extends CombatEnemy
## One soft creature of a broken Grappolo (B7): it scurries away from
## Ottavia until the colony calls it back together.

const SCATTER_DISTANCE: float = 1.4

var creature: CreatureTuning
var colony: Grappolo
var _gather_point: Vector3
var _gathering: bool = false


func _ready() -> void:
	max_health = creature.grappolo_member_health
	is_small = true
	radius = 0.2
	super._ready()


func scatter(direction: Vector3) -> void:
	_move_by(direction * SCATTER_DISTANCE)


func gather_to(point: Vector3) -> void:
	_gather_point = point
	_gathering = true


func _behave(_delta: float) -> void:
	if is_being_moved():
		return
	var player: OttaviaProto = find_player()
	var move: Vector3 = Vector3.ZERO
	if _gathering:
		move = flat_direction_to(_gather_point) * creature.grappolo_bit_speed * 2.0
	elif player != null and flat_distance_to(player.global_position) < 3.0:
		move = -flat_direction_to(player.global_position) * creature.grappolo_bit_speed
	velocity = move
	sprite.flip_h = move.x > 0.1


func _on_defeated() -> void:
	sprite.visible = false
	queue_free.call_deferred()


## Pieces are not creatures of the room: the colony resets them.
func reset_enemy() -> void:
	queue_free()
