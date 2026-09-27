class_name HitFeedback
extends RefCounted
## Feel of the hits (33): freeze frames on impact, camera shake, flashes.
## Shake and flashes can be turned down in the options (96).

## 0-1 from the options: 0 turns the camera shake off.
static var shake_scale: float = 1.0
## 0-1 from the options: 0 turns the flashes off.
static var flash_scale: float = 1.0

static var _stop_depth: int = 0


## Freezes the game for a few frames (real time), then resumes.
static func hitstop(tree: SceneTree, seconds: float) -> void:
	if seconds <= 0.0:
		return
	_stop_depth += 1
	Engine.time_scale = 0.02
	await tree.create_timer(seconds, true, false, true).timeout
	_stop_depth -= 1
	if _stop_depth <= 0:
		_stop_depth = 0
		Engine.time_scale = 1.0


static func shake(tree: SceneTree, meters: float, seconds: float = 0.18) -> void:
	var rig: FollowCameraRig = tree.get_first_node_in_group(&"camera_rig") as FollowCameraRig
	if rig != null:
		rig.shake(meters * shake_scale, seconds)
