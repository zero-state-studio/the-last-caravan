class_name HintBanner
extends CanvasLayer
## On-screen hints (106, 125): short text at the bottom centre after the
## icon of the key on the device used last (a key cap for the keyboard, a
## round button for the gamepad), fading in and out.

const FADE_SECONDS: float = 0.35
const ROW_WIDTH: float = 700.0
const BOTTOM_OFFSET: float = 196.0

var _row: HBoxContainer
var _goal: Label
var _goal_key: StringName = &""
var _goal_tween: Tween
var _caps: HBoxContainer
var _label: Label
var _text_key: StringName = &""
var _action: StringName = &""
var _device: InputRemap.Device = InputRemap.Device.KEYBOARD
var _tween: Tween


func _ready() -> void:
	layer = 9
	add_to_group(&"hint_banner")
	_row = HBoxContainer.new()
	_row.add_theme_constant_override(&"separation", 10)
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_row.custom_minimum_size = Vector2(ROW_WIDTH, 44.0)
	_row.position = Vector2(-ROW_WIDTH * 0.5, -BOTTOM_OFFSET)
	_row.modulate.a = 0.0
	add_child(_row)
	# The goal in words (106), above the key: where to go and why.
	_goal = Label.new()
	_goal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_goal.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_goal.custom_minimum_size = Vector2(ROW_WIDTH, 36.0)
	_goal.position = Vector2(-ROW_WIDTH * 0.5, -BOTTOM_OFFSET - 40.0)
	_goal.add_theme_color_override(&"font_outline_color", UiStyle.OUTLINE)
	_goal.add_theme_constant_override(&"outline_size", 6)
	_goal.modulate.a = 0.0
	add_child(_goal)
	_caps = HBoxContainer.new()
	_caps.add_theme_constant_override(&"separation", 4)
	_row.add_child(_caps)
	_label = Label.new()
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_color_override(&"font_outline_color", UiStyle.OUTLINE)
	_label.add_theme_constant_override(&"outline_size", 6)
	_row.add_child(_label)
	if Input.get_connected_joypads().size() > 0:
		_device = InputRemap.Device.GAMEPAD


func _input(event: InputEvent) -> void:
	var device: InputRemap.Device = _device
	if InputRemap.is_device_event(event, InputRemap.Device.GAMEPAD):
		device = InputRemap.Device.GAMEPAD
	elif InputRemap.is_device_event(event, InputRemap.Device.KEYBOARD):
		device = InputRemap.Device.KEYBOARD
	if device != _device:
		_device = device
		_refresh()


## Shows `text_key` with the key of `action` (&"move" for the movement keys).
func show_hint(text_key: StringName, action: StringName) -> void:
	_text_key = text_key
	_action = action
	_refresh()
	_fade_to(1.0)


func hide_hint() -> void:
	_text_key = &""
	_fade_to(0.0)


## The current goal, shown above the hint until changed or hidden.
func show_goal(goal_key: StringName) -> void:
	if goal_key == _goal_key:
		return
	_goal_key = goal_key
	UiStyle.style_label(_goal, UiStyle.text_size(), UiStyle.SPEAKER)
	_goal.text = goal_key
	_fade_goal(1.0)


func hide_goal() -> void:
	_goal_key = &""
	_fade_goal(0.0)


func current_goal() -> StringName:
	return _goal_key


func _fade_goal(alpha: float) -> void:
	if _goal_tween != null:
		_goal_tween.kill()
	_goal_tween = create_tween()
	_goal_tween.tween_property(_goal, "modulate:a", alpha, FADE_SECONDS)


func current_hint() -> StringName:
	return _text_key


func _refresh() -> void:
	if _text_key == &"":
		return
	UiStyle.style_label(_label, UiStyle.text_size())
	_label.text = tr(_text_key)
	for cap: Node in _caps.get_children():
		cap.queue_free()
	for key: String in key_caps(_action, _device):
		_caps.add_child(_key_cap(key, _device == InputRemap.Device.GAMEPAD))


## The key names to draw for an action (four for &"move" on the keyboard).
static func key_caps(action: StringName, device: InputRemap.Device) -> PackedStringArray:
	if action == &"move":
		if device == InputRemap.Device.GAMEPAD:
			return PackedStringArray([TranslationServer.translate(&"HINT_LEFT_STICK")])
		var keys: PackedStringArray = []
		for move: StringName in [&"move_up", &"move_left", &"move_down", &"move_right"]:
			keys.append(InputRemap.event_label(InputRemap.main_event(move, device)))
		return keys
	return PackedStringArray([InputRemap.event_label(InputRemap.main_event(action, device))])


func _key_cap(key: String, round_button: bool) -> PanelContainer:
	var cap: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.9, 0.86, 0.78)
	style.border_color = UiStyle.OUTLINE
	style.set_border_width_all(2)
	style.border_width_bottom = 4
	style.anti_aliasing = false
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 2.0
	style.content_margin_bottom = 2.0
	if round_button:
		style.set_corner_radius_all(14)
	cap.add_theme_stylebox_override(&"panel", style)
	cap.custom_minimum_size = Vector2(30.0, 30.0)
	var label: Label = Label.new()
	label.text = key
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UiStyle.style_label(label, UiStyle.text_size(UiStyle.SMALL_SIZE), UiStyle.OUTLINE)
	cap.add_child(label)
	return cap


func _fade_to(alpha: float) -> void:
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_row, "modulate:a", alpha, FADE_SECONDS)
