class_name LessonParry
extends Node
## Lesson of the parry (82): the player guides Enea against the training
## dummy while Ottavia explains. For the player it is a tutorial, for the
## story a real lesson. Two deflections end it and Enea learns the parry.
## Lines are provisional translation keys with unique IDs (59).

signal finished

const LINE_SECONDS: float = 3.4
const SUCCESSES_NEEDED: int = 2
const SPEAKER: StringName = &"NAME_OTTAVIA"

## Paths, not typed node exports (hand-written .tscn paths, see tecnica.md).
@export var enea_path: NodePath
@export var dummy_path: NodePath

var enea: Enea
var dummy: TrainingDummy
var active: bool = false
var done: bool = false
var successes: int = 0
var _talk: LessonTalk


func _ready() -> void:
	enea = get_node(enea_path) as Enea
	dummy = get_node(dummy_path) as TrainingDummy
	_talk = enea.get_node("Talk") as LessonTalk
	_talk.used.connect(start)
	enea.deflected.connect(_on_deflected)
	enea.hit_taken.connect(_on_hit)


func start() -> void:
	if active or done:
		return
	active = true
	successes = 0
	_talk.available = false
	var ottavia: OttaviaProto = _ottavia()
	ottavia.controls_enabled = false
	enea.global_position = dummy.global_position + Vector3(0.0, 0.1, 2.0)
	ottavia.global_position = dummy.global_position + Vector3(-2.0, 0.05, 2.8)
	ottavia.face_toward(Vector3.FORWARD)
	var rig: FollowCameraRig = get_tree().get_first_node_in_group(&"camera_rig") as FollowCameraRig
	rig.target = enea
	rig.snap_to_target()
	dummy.reset_enemy()
	dummy.paused = true
	dummy.target_override = enea
	await _say(&"DLG_LESSON_PARRY_001")
	await _say(&"DLG_LESSON_PARRY_002")
	await _say(&"DLG_LESSON_PARRY_003")
	enea.state = Enea.State.CONTROLLED
	dummy.paused = false
	_box().show_line(SPEAKER, &"DLG_LESSON_PARRY_004")
	while successes < SUCCESSES_NEEDED and active:
		await get_tree().physics_frame
	enea.state = Enea.State.FOLLOW
	enea.release_parry()
	dummy.paused = true
	await _say(&"DLG_LESSON_PARRY_008")
	enea.learn(&"parry")
	_finish()


## Called by the lesson signals, and by tests.
func _on_deflected() -> void:
	if not active or enea.state != Enea.State.CONTROLLED:
		return
	successes += 1
	if successes < SUCCESSES_NEEDED:
		_box().show_line(SPEAKER, &"DLG_LESSON_PARRY_007")


func _on_hit() -> void:
	if not active or enea.state != Enea.State.CONTROLLED:
		return
	var too_early: bool = enea.parry_time > dummy.tuning.deflect_window
	_box().show_line(SPEAKER, &"DLG_LESSON_PARRY_006" if too_early else &"DLG_LESSON_PARRY_005")


func _finish() -> void:
	active = false
	done = true
	dummy.target_override = null
	dummy.paused = false
	var ottavia: OttaviaProto = _ottavia()
	var rig: FollowCameraRig = get_tree().get_first_node_in_group(&"camera_rig") as FollowCameraRig
	rig.target = ottavia
	rig.snap_to_target()
	ottavia.controls_enabled = true
	_box().hide_box()
	finished.emit()


## Shows a line for LINE_SECONDS, or until the interact button skips it.
func _say(line_key: StringName) -> void:
	_box().show_line(SPEAKER, line_key)
	var left: float = LINE_SECONDS
	while left > 0.0:
		await get_tree().process_frame
		left -= get_process_delta_time()
		if Input.is_action_just_pressed(&"interact"):
			break


func _box() -> DialogueBox:
	return get_tree().get_first_node_in_group(&"dialogue_box") as DialogueBox


func _ottavia() -> OttaviaProto:
	return get_tree().get_first_node_in_group(&"player") as OttaviaProto
