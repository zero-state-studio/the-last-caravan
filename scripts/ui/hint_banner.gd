class_name HintBanner
extends CanvasLayer
## On-screen hints of the prologue (106, 125): short text at the bottom
## centre with the key of the device used last, fading in and out.

const FADE_SECONDS: float = 0.35

var _label: Label
var _text_key: StringName = &""
var _action: StringName = &""
var _device: InputRemap.Device = InputRemap.Device.KEYBOARD
var _tween: Tween


func _ready() -> void:
	layer = 9
	add_to_group(&"hint_banner")
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.custom_minimum_size = Vector2(600.0, 40.0)
	_label.position = Vector2(-300.0, -200.0)
	_label.add_theme_font_size_override(&"font_size", 22)
	_label.add_theme_color_override(&"font_outline_color", Color(0.05, 0.04, 0.08))
	_label.add_theme_constant_override(&"outline_size", 6)
	_label.modulate.a = 0.0
	add_child(_label)
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


func current_hint() -> StringName:
	return _text_key


func _refresh() -> void:
	if _text_key == &"":
		return
	_label.text = "%s   [%s]" % [tr(_text_key), key_label(_action, _device)]


static func key_label(action: StringName, device: InputRemap.Device) -> String:
	if action == &"move":
		if device == InputRemap.Device.GAMEPAD:
			return TranslationServer.translate(&"HINT_LEFT_STICK")
		var keys: PackedStringArray = []
		for move: StringName in [&"move_up", &"move_left", &"move_down", &"move_right"]:
			keys.append(InputRemap.event_label(InputRemap.main_event(move, device)))
		return " ".join(keys)
	return InputRemap.event_label(InputRemap.main_event(action, device))


func _fade_to(alpha: float) -> void:
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_label, "modulate:a", alpha, FADE_SECONDS)
