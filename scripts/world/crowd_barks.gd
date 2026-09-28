class_name CrowdBarks
extends Node
## Short lines said by the crowd (121) when Ottavia walks by: one person at
## a time, in a bubble above their head, with long pauses so the camp does
## not chatter. Line IDs are PRO_CROWD_01...; their texts are written by
## the author (TODO-DESIGN #121 until then).

const LINES: Array[StringName] = [
	&"PRO_CROWD_01", &"PRO_CROWD_02", &"PRO_CROWD_03", &"PRO_CROWD_04",
	&"PRO_CROWD_05", &"PRO_CROWD_06", &"PRO_CROWD_07", &"PRO_CROWD_08",
]
const NEAR_METERS: float = 4.5
const LINE_SECONDS: float = 3.2
## Pause between two lines anywhere, and before the same person speaks again.
const PAUSE_SECONDS: float = 7.0
const PERSON_PAUSE_SECONDS: float = 40.0
const CHECK_SECONDS: float = 0.5

var ottavia: OttaviaProto
var dialogue: DialogueBox
var crowd: Array[CrowdMember] = []
var bubble: SpeechBubble
## Off during cutscenes.
var enabled: bool = true

var _random: RandomNumberGenerator = RandomNumberGenerator.new()
var _check_left: float = 0.0
var _pause_left: float = 3.0
var _spoke_at: Dictionary = {}
var _speaker: CrowdMember
var _speaking_left: float = 0.0
var _next_line: int = 0


func _ready() -> void:
	_random.seed = 1210
	_next_line = _random.randi() % LINES.size()
	bubble = SpeechBubble.new()
	add_child(bubble)


func _process(delta: float) -> void:
	if _speaker != null:
		_speaking_left -= delta
		if _speaking_left <= 0.0 or not enabled:
			_end_line()
		return
	_pause_left -= delta
	_check_left -= delta
	if _check_left > 0.0 or _pause_left > 0.0 or not enabled or ottavia == null:
		return
	_check_left = CHECK_SECONDS
	if not ottavia.controls_enabled or (dialogue != null and dialogue.is_showing()):
		return
	var now: float = Time.get_ticks_msec() / 1000.0
	for person: CrowdMember in crowd:
		var flat: Vector2 = Vector2(person.global_position.x - ottavia.global_position.x, person.global_position.z - ottavia.global_position.z)
		if flat.length() > NEAR_METERS or now - float(_spoke_at.get(person, -INF)) < PERSON_PAUSE_SECONDS:
			continue
		say(person, LINES[_next_line])
		_next_line = (_next_line + 1 + _random.randi() % 2) % LINES.size()
		return


func say(person: CrowdMember, line: StringName) -> void:
	_speaker = person
	_speaking_left = LINE_SECONDS
	_spoke_at[person] = Time.get_ticks_msec() / 1000.0
	person.hold_still()
	bubble.show_over(person, line)


func speaking() -> CrowdMember:
	return _speaker


func _end_line() -> void:
	bubble.hide_bubble()
	if is_instance_valid(_speaker):
		_speaker.resume()
	_speaker = null
	_pause_left = PAUSE_SECONDS
