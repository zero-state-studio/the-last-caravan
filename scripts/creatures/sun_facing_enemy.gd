class_name SunFacingEnemy
extends CombatEnemy
## A beast of the Day (36): it keeps its face toward the sun, the Day in the
## west (100), and its right side is in its own shade. Carried round by a
## turning terrace, it turns with it, then turns slowly back toward the
## sun; while it does, its shaded flank faces a new way (chapter 1,
## section 4). Hit on the shaded side it takes more damage.

## Toward the Day (100): where the beast wants to face.
const SUN_DIRECTION: Vector3 = Vector3.LEFT

@export var creature: CreatureTuning

## Where its face points now (flat unit vector).
var facing: Vector3 = SUN_DIRECTION
var _turn_back_from: Vector3 = SUN_DIRECTION
var _turn_back_left: float = 0.0


## Its right: with the face to the west, the north side.
func shaded_side() -> Vector3:
	return facing.cross(Vector3.UP).normalized()


## True while it turns back toward the sun after a turn of the terrace.
func is_turning_back() -> bool:
	return _turn_back_left > 0.0


## Called by TurningPlatform at the end of a turn that carried it.
func carried_turned(angle: float) -> void:
	facing = facing.rotated(Vector3.UP, angle).normalized()
	_turn_back_from = facing
	_turn_back_left = flank_seconds()
	spawn_transform.basis = Basis.IDENTITY


func flank_seconds() -> float:
	return creature.day_beast_flank_seconds if creature != null else 2.0


## True when `hit` comes from within `degrees` of the shaded side.
func hit_on_shaded_side(hit: CombatHit, degrees: float) -> bool:
	return rad_to_deg((-hit.direction).angle_to(shaded_side())) <= degrees


func weak_side(_from: Vector3) -> Vector3:
	return shaded_side()


func _physics_process(delta: float) -> void:
	if _turn_back_left > 0.0:
		_turn_back_left = maxf(0.0, _turn_back_left - delta)
		var weight: float = 1.0 - _turn_back_left / maxf(flank_seconds(), 0.01)
		facing = _turn_back_from.slerp(SUN_DIRECTION, weight).normalized()
		if facing.is_zero_approx():
			facing = SUN_DIRECTION
	sprite.flip_h = facing.x > 0.1
	super._physics_process(delta)


func _on_reset() -> void:
	facing = SUN_DIRECTION
	_turn_back_left = 0.0
