class_name CrowdMember
extends NpcSprite
## Someone of the generic crowd (121) going about the camp: short walks
## between free spots, pauses facing a nearby job, a turn now and then. The
## walk and still views are the generic ones of its type; the nearest of
## the drawn directions is shown.

## Views drawn for the walk, and their facing angle on the ground
## (atan2(z, x): east 0, south +90, west 180).
const WALK_VIEWS: Dictionary = {"east": 0.0, "south-east": 45.0, "south-west": 135.0, "west": 180.0, "north-east": -45.0}
const STILL_VIEWS: Dictionary = {"south": 90.0, "south-west": 135.0, "west": 180.0, "north-west": -135.0}
const WALK_SPEED: float = 1.1
const WALK_FPS: float = 8.0
const PAUSE_SECONDS: Vector2 = Vector2(2.0, 6.0)
const STRIDE_METERS: Vector2 = Vector2(3.0, 9.0)

## Generic type, for example "donna_adulta".
var kind: String = ""
## Where it may walk: a point is refused when this returns true.
var blocked: Callable = func(_point: Vector3) -> bool: return false
## False while it is saying something: it stands still.
var wandering: bool = true

var _random: RandomNumberGenerator = RandomNumberGenerator.new()
var _target: Vector3
var _walking: bool = false
var _pause_left: float = 0.0
var _home: Vector3
var _walk_strips: Dictionary = {}
var _still_strips: Dictionary = {}


func setup(generic_kind: String, seed_value: int, is_blocked: Callable) -> void:
	kind = generic_kind
	blocked = is_blocked
	_random.seed = seed_value
	for view: String in WALK_VIEWS:
		var path: String = "res://assets/sprites/folla/%s_walk_%s.png" % [kind, view]
		if ResourceLoader.exists(path):
			_walk_strips[view] = load(path)
	for view: String in STILL_VIEWS:
		var path: String = "res://assets/sprites/folla/%s_%s.png" % [kind, view]
		if ResourceLoader.exists(path):
			_still_strips[view] = load(path)
	var first: String = STILL_VIEWS.keys()[_random.randi() % STILL_VIEWS.size()]
	sprite_texture = _still_strips.get(first, sprite_texture)
	_pause_left = _random.randf_range(0.0, PAUSE_SECONDS.y)


func _ready() -> void:
	super._ready()
	_home = position


func _physics_process(delta: float) -> void:
	if not wandering:
		return
	if not _walking:
		_pause_left -= delta
		if _pause_left <= 0.0:
			_choose_target()
		return
	var offset: Vector3 = _target - position
	offset.y = 0.0
	if offset.length() < 0.15:
		_stop(offset)
		return
	var step: Vector3 = offset.normalized() * WALK_SPEED * delta
	position += step if step.length() < offset.length() else offset


## A free spot a few strides away, not too far from where it started.
func _choose_target() -> void:
	for attempt: int in 8:
		var angle: float = _random.randf_range(-PI, PI)
		var distance: float = _random.randf_range(STRIDE_METERS.x, STRIDE_METERS.y)
		var point: Vector3 = position + Vector3(cos(angle), 0.0, sin(angle)) * distance
		if point.distance_to(_home) > 14.0:
			point = _home + (point - _home).normalized() * 6.0
		if _path_free(position, point):
			_target = point
			_walking = true
			var view: String = _nearest(WALK_VIEWS, rad_to_deg(atan2(point.z - position.z, point.x - position.x)))
			if _walk_strips.has(view):
				set_strip(_walk_strips[view], WALK_FPS)
			return
	_pause_left = _random.randf_range(PAUSE_SECONDS.x, PAUSE_SECONDS.y)


func _stop(last_move: Vector3) -> void:
	_walking = false
	_pause_left = _random.randf_range(PAUSE_SECONDS.x, PAUSE_SECONDS.y)
	var view: String = _nearest(STILL_VIEWS, rad_to_deg(atan2(last_move.z, last_move.x)))
	if _still_strips.has(view):
		set_strip(_still_strips[view])


## Stops where it is and faces the camera side, to say something.
func hold_still() -> void:
	wandering = false
	if _walking:
		_stop(Vector3(0.0, 0.0, 1.0))


func resume() -> void:
	wandering = true


func is_walking() -> bool:
	return _walking


func _path_free(from: Vector3, to: Vector3) -> bool:
	for step: int in range(1, 9):
		if blocked.call(from.lerp(to, step / 8.0)):
			return false
	return true


static func _nearest(views: Dictionary, angle_degrees: float) -> String:
	var best: String = ""
	var best_gap: float = INF
	for view: String in views:
		var gap: float = absf(wrapf(angle_degrees - float(views[view]), -180.0, 180.0))
		if gap < best_gap:
			best_gap = gap
			best = view
	return best
