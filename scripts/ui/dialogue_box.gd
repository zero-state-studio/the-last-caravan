class_name DialogueBox
extends CanvasLayer
## Provisional dialogue box: speaker name and line, both translation keys.
## Every line has a unique ID (its key), which links the voice acting (59):
## a line with a recorded voice plays it (GameAudio.play_voice).

var _panel: PanelContainer
var _speaker: Label
var _line: Label


func _ready() -> void:
	layer = 8
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(&"dialogue_box")
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_panel.custom_minimum_size = Vector2(760.0, 110.0)
	_panel.position = Vector2(-380.0, -140.0)
	add_child(_panel)
	var box: VBoxContainer = VBoxContainer.new()
	_panel.add_child(box)
	_speaker = Label.new()
	_speaker.add_theme_color_override(&"font_color", Color(1.0, 0.77, 0.42))
	box.add_child(_speaker)
	_line = Label.new()
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line.custom_minimum_size = Vector2(740.0, 0.0)
	box.add_child(_line)
	_panel.visible = false


## Shows a line and plays its voice; returns the voice length in seconds
## (0 when the line has no voice).
func show_line(speaker_key: StringName, line_key: StringName, voice_db: float = 0.0) -> float:
	_speaker.text = speaker_key
	_line.text = line_key
	_panel.visible = true
	return GameAudio.play_voice(line_key, voice_db)


## How long a line stays up: `seconds`, or longer if its voice needs it.
## Short dev pacing (under a second, tests) is kept as it is.
## `pause` is the silence after the voice (the music comes back up in it).
static func line_wait(seconds: float, voice_seconds: float, pause: float = 0.6) -> float:
	return seconds if seconds < 1.0 else maxf(seconds, voice_seconds + pause)


func hide_box() -> void:
	_panel.visible = false


func is_showing() -> bool:
	return _panel.visible


func current_line() -> String:
	return _line.text
