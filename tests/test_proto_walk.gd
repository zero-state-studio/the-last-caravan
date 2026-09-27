extends SceneTree
## Walks the prototype Ottavia through the diorama levels (32):
## up the stairs to the terrace, across the bridge, off the platform edge.
## Usage: godot --headless --path . --script res://tests/test_proto_walk.gd

const STEPS: Array[Dictionary] = [
	{"start": Vector3(-7.5, 0.05, 2.5), "action": &"move_up", "seconds": 3.0,
		"check": "stairs", "min_y": 2.9, "max_y": 3.1},
	{"start": Vector3(-4.0, 3.05, -10.0), "action": &"move_right", "seconds": 3.5,
		"check": "bridge", "min_y": 2.9, "max_y": 3.1, "min_x": 4.5},
	{"start": Vector3(6.5, 3.05, -10.0), "action": &"move_down", "seconds": 2.0,
		"check": "fall from the platform", "min_y": -0.1, "max_y": 0.1},
]

var _ottavia: OttaviaProto
var _step: int = -1
var _elapsed: float = 0.0
var _failures: int = 0


func _initialize() -> void:
	change_scene_to_file("res://scenes/proto/diorama.tscn")


func _physics_process(delta: float) -> bool:
	if current_scene == null:
		return false
	if _ottavia == null:
		_ottavia = current_scene.get_node("Ottavia")
		# The walk is about the level: no creatures in the way.
		current_scene.get_node("Creatures").free()
		_start_step(0)
		return false
	_elapsed += delta
	var step: Dictionary = STEPS[_step]
	if _elapsed < float(step["seconds"]):
		return false
	Input.action_release(step["action"])
	var position: Vector3 = _ottavia.global_position
	var ok: bool = position.y >= float(step["min_y"]) and position.y <= float(step["max_y"])
	if step.has("min_x"):
		ok = ok and position.x >= float(step["min_x"])
	if not ok:
		_failures += 1
		printerr("FAIL: walk %s ended at %s" % [step["check"], position])
	if _step + 1 < STEPS.size():
		_start_step(_step + 1)
		return false
	print("TESTS: walk %d checks, %d failures" % [STEPS.size(), _failures])
	quit(1 if _failures > 0 else 0)
	return true


func _start_step(index: int) -> void:
	_step = index
	_elapsed = 0.0
	_ottavia.global_position = STEPS[index]["start"]
	_ottavia.velocity = Vector3.ZERO
	Input.action_press(STEPS[index]["action"])
