class_name ChapterScreen
extends CanvasLayer
## End-of-chapter screen (34): one screen, two lines, what Ottavia loses and
## what she learns. No skill tree: it is her life that changes. Pauses the
## game; any action button closes it after a moment.

signal closed

const MIN_SECONDS: float = 1.0

var _root: ColorRect
var _title: Label
var _lose: Label
var _learn: Label
var _open_time: float = 0.0


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(&"chapter_screen")
	_root = ColorRect.new()
	_root.color = Color(0.06, 0.05, 0.1, 0.92)
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var box: VBoxContainer = VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.position = Vector2(-320.0, -90.0)
	box.custom_minimum_size = Vector2(640.0, 180.0)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	_root.add_child(box)
	_title = _label(box, UiStyle.BODY_SIZE, UiStyle.SPEAKER)
	_lose = _label(box, UiStyle.BODY_SIZE, Color(0.75, 0.75, 0.9))
	_learn = _label(box, UiStyle.BODY_SIZE, Color(0.97, 0.9, 0.7))
	_root.visible = false


func is_open() -> bool:
	return _root.visible


## Shows the lines for arriving at `chapter`.
func show_chapter(chapter: int) -> void:
	var lines: PackedStringArray = Progression.chapter_lines(chapter)
	_title.text = tr(&"CHAPTER_END_TITLE").format({"n": chapter - 1})
	_lose.text = tr(&"CHAPTER_LOSES").format({"text": lines[0]}) if lines[0] != "" else ""
	_learn.text = tr(&"CHAPTER_LEARNS").format({"text": lines[1]}) if lines[1] != "" else ""
	_root.visible = true
	_open_time = Time.get_ticks_msec() / 1000.0
	get_tree().paused = true


func close() -> void:
	_root.visible = false
	get_tree().paused = false
	closed.emit()


func _input(event: InputEvent) -> void:
	if not is_open() or Time.get_ticks_msec() / 1000.0 - _open_time < MIN_SECONDS:
		return
	for action: StringName in [&"interact", &"attack", &"open_options"]:
		if event.is_action_pressed(action):
			close()
			get_viewport().set_input_as_handled()
			return


func _label(box: VBoxContainer, size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	label.add_theme_font_size_override(&"font_size", size)
	label.add_theme_color_override(&"font_color", color)
	box.add_child(label)
	return label
