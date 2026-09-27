class_name FoglioneArena
extends BossArena
## The field of the Foglione Radicato (83). The beast is rooted with its back
## to the east wall, leaves toward the sun in the west: from the reachable
## side only the leaves can be hit. The lever tilts the field toward the
## east: the sun moves there, the beast slowly turns after it and uncovers
## its west flank, until the field tilts back.

const TILT_DEGREES: float = 4.0

@export var lever_path: NodePath
@export var sun_path: NodePath
## The field floor, tilted a little while the lever holds it.
@export var field_path: NodePath

var lever: FieldLever
var sun: DirectionalLight3D
var field: Node3D
var tilted: bool = false
var _tilt_left: float = 0.0
var _sun_west_rotation: Vector3


func _ready() -> void:
	super._ready()
	lever = get_node(lever_path) as FieldLever
	sun = get_node(sun_path) as DirectionalLight3D
	field = get_node(field_path) as Node3D
	var tuning: CreatureTuning = (boss as FoglioneRadicato).creature
	lever.cooldown = tuning.field_lever_cooldown
	lever.used.connect(tilt_field)


func tilt_field() -> void:
	if tilted:
		return
	tilted = true
	_tilt_left = (boss as FoglioneRadicato).creature.field_tilt_seconds
	_sun_west_rotation = sun.rotation_degrees
	_set_sun(Vector3.RIGHT, Vector3(_sun_west_rotation.x, 360.0 - _sun_west_rotation.y, 0.0), TILT_DEGREES)
	_show(&"FIELD_TILTS")


func _process(delta: float) -> void:
	if tilted:
		_tilt_left -= delta
		if _tilt_left <= 0.0:
			_untilt()


func _untilt() -> void:
	if not tilted:
		return
	tilted = false
	_set_sun(Vector3.LEFT, _sun_west_rotation, 0.0)
	_show(&"FIELD_TILTS_BACK")


## Moves the sun (and the shadow proxy of Ottavia) and tilts the floor.
func _set_sun(direction: Vector3, sun_rotation: Vector3, tilt: float) -> void:
	(boss as FoglioneRadicato).sun_direction = direction
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(sun, "rotation_degrees", sun_rotation, 1.0)
	tween.tween_property(field, "rotation_degrees:z", -tilt if direction.x > 0.0 else 0.0, 1.0)
	var ottavia: OttaviaProto = player()
	if ottavia != null:
		ottavia.set_sun_azimuth(sun_rotation.y)


func _reset_arena() -> void:
	_untilt()
	lever.reset_lever()


func _on_left() -> void:
	_untilt()
