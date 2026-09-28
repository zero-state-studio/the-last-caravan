class_name DialogueBox
extends CanvasLayer
## Dialogue box (125): dark, at the bottom, with the name of who speaks; no
## portraits for now. Speaker name and line are translation keys; the text
## size follows the player's option (96).
## Every line has a unique ID (its key), which links the voice acting (59):
## a line with a recorded voice plays it (GameAudio.play_voice).

const WIDTH: float = 780.0
const BOTTOM_MARGIN: float = 24.0

var _panel: PanelContainer
var _speaker: Label
var _line: Label


func _ready() -> void:
	layer = 8
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(&"dialogue_box")
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override(&"panel", UiStyle.panel_style(14.0))
	# Anchored to the bottom centre, growing upward with bigger text.
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = -WIDTH * 0.5
	_panel.offset_right = WIDTH * 0.5
	_panel.offset_bottom = -BOTTOM_MARGIN
	_panel.offset_top = -BOTTOM_MARGIN - 100.0
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(_panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 6)
	_panel.add_child(box)
	_speaker = Label.new()
	box.add_child(_speaker)
	_line = Label.new()
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line.custom_minimum_size = Vector2(WIDTH - 32.0, 0.0)
	box.add_child(_line)
	_panel.visible = false


## Shows a line and plays its voice; returns the voice length in seconds
## (0 when the line has no voice).
func show_line(speaker_key: StringName, line_key: StringName, voice_db: float = 0.0) -> float:
	_speaker.text = speaker_key
	_speaker.visible = not String(speaker_key).is_empty()
	_line.text = line_key
	UiStyle.style_label(_speaker, UiStyle.text_size(), UiStyle.SPEAKER)
	UiStyle.style_label(_line, UiStyle.text_size())
	_panel.offset_top = -BOTTOM_MARGIN - 60.0
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
