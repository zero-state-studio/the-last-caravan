class_name ChapterTitle
extends CanvasLayer
## Black screen with a big title that fades in and out (125), for example
## «Ne restano dieci». Also shows, once, the empty silhouette of the
## farewell lantern in the menu (88).

## Title timing (125): 1.5 s to appear, 4 still, 1.5 to go.
const TITLE_IN_SECONDS: float = 1.5
const TITLE_HOLD_SECONDS: float = 4.0
const TITLE_OUT_SECONDS: float = 1.5
## Any of these skips the title straight to its fade-out.
const SKIP_ACTIONS: Array[StringName] = [&"interact", &"attack", &"ui_accept"]

## The title starts fading out (after the hold, or skipped): the music
## that goes with it can stop in the same time.
signal title_leaving(seconds: float)
signal _title_gone

var _black: ColorRect
var _title: Label
var _lantern: LanternEmblem
var _title_tween: Tween
var _out_seconds: float = TITLE_OUT_SECONDS
var _leaving: bool = false


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_black = ColorRect.new()
	_black.color = Color(0.0, 0.0, 0.0, 0.0)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_black.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_black)
	_title = Label.new()
	_title.set_anchors_preset(Control.PRESET_FULL_RECT)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override(&"font_size", 52)
	_title.modulate.a = 0.0
	add_child(_title)
	_lantern = LanternEmblem.new()
	_lantern.set_anchors_preset(Control.PRESET_CENTER)
	_lantern.position = -LanternEmblem.SIZE * 0.5
	_lantern.modulate.a = 0.0
	add_child(_lantern)


func fade_to_black(seconds: float) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_black, "color:a", 1.0, seconds)
	await tween.finished


## The title on black: in, hold, out; a skip key jumps to the fade-out.
func show_title(key: StringName, hold_seconds: float = TITLE_HOLD_SECONDS, in_seconds: float = TITLE_IN_SECONDS, out_seconds: float = TITLE_OUT_SECONDS) -> void:
	_title.text = key
	_out_seconds = out_seconds
	_leaving = false
	_title_tween = create_tween()
	_title_tween.tween_property(_title, "modulate:a", 1.0, in_seconds)
	_title_tween.tween_interval(hold_seconds)
	_title_tween.tween_callback(_leave)
	await _title_gone


## Skips the title: straight to its fade-out.
func skip_title() -> void:
	if _title_tween != null and not _leaving:
		_title_tween.kill()
		_leave()


func _leave() -> void:
	if _leaving:
		return
	_leaving = true
	title_leaving.emit(_out_seconds)
	var out: Tween = create_tween()
	out.tween_property(_title, "modulate:a", 0.0, _out_seconds)
	out.tween_callback(_title_gone.emit)


func _unhandled_input(event: InputEvent) -> void:
	if _title_tween == null or not _title_tween.is_valid() or _leaving:
		return
	for action: StringName in SKIP_ACTIONS:
		if InputMap.has_action(action) and event.is_action_pressed(action):
			skip_title()
			get_viewport().set_input_as_handled()
			return


func is_title_visible() -> bool:
	return _title.modulate.a > 0.01


## The farewell lantern (88), still empty: only its outline.
func show_lantern_silhouette(seconds: float) -> void:
	LanternProgress.revealed = true
	_lantern.pieces = LanternProgress.pieces
	var tween: Tween = create_tween()
	tween.tween_property(_black, "color:a", 0.75, 0.6)
	tween.parallel().tween_property(_lantern, "modulate:a", 1.0, 0.8)
	tween.tween_interval(seconds)
	tween.tween_property(_lantern, "modulate:a", 0.0, 0.6)
	await tween.finished
