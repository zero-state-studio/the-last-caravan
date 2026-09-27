class_name InputRemap
extends RefCounted
## Remappable controls (96, 67). Every game action has a main keyboard or
## mouse binding and a main gamepad binding; the options menu replaces them.
## Changes are saved in user://controls.cfg and loaded at start.

enum Device { KEYBOARD, GAMEPAD }

const PATH: String = "user://controls.cfg"
const SECTION: String = "controls"
## Actions shown in the options menu, with their translation keys.
const ACTIONS: Array[Dictionary] = [
	{"action": &"move_up", "key": "INPUT_MOVE_UP"},
	{"action": &"move_down", "key": "INPUT_MOVE_DOWN"},
	{"action": &"move_left", "key": "INPUT_MOVE_LEFT"},
	{"action": &"move_right", "key": "INPUT_MOVE_RIGHT"},
	{"action": &"attack", "key": "INPUT_ATTACK"},
	{"action": &"hook", "key": "INPUT_HOOK"},
	{"action": &"parry", "key": "INPUT_PARRY"},
	{"action": &"jump", "key": "INPUT_JUMP"},
	{"action": &"run", "key": "INPUT_RUN"},
	{"action": &"lantern", "key": "INPUT_LANTERN"},
	{"action": &"call", "key": "INPUT_CALL"},
	{"action": &"interact", "key": "INPUT_INTERACT"},
]
const PAD_BUTTON_NAMES: Dictionary = {
	JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
	JOY_BUTTON_BACK: "View", JOY_BUTTON_START: "Menu",
	JOY_BUTTON_LEFT_STICK: "L3", JOY_BUTTON_RIGHT_STICK: "R3",
	JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_DPAD_UP: "D-pad ↑", JOY_BUTTON_DPAD_DOWN: "D-pad ↓",
	JOY_BUTTON_DPAD_LEFT: "D-pad ←", JOY_BUTTON_DPAD_RIGHT: "D-pad →",
}


static func is_device_event(event: InputEvent, device: Device) -> bool:
	if device == Device.KEYBOARD:
		return event is InputEventKey or event is InputEventMouseButton
	return event is InputEventJoypadButton or event is InputEventJoypadMotion


## The main binding of `action` for a device (the first one), or null.
static func main_event(action: StringName, device: Device) -> InputEvent:
	for event: InputEvent in InputMap.action_get_events(action):
		if is_device_event(event, device):
			return event
	return null


## Replaces the main binding of `action` for the device of `event`.
static func rebind(action: StringName, event: InputEvent) -> void:
	var device: Device = Device.KEYBOARD if is_device_event(event, Device.KEYBOARD) else Device.GAMEPAD
	var old: InputEvent = main_event(action, device)
	var events: Array[InputEvent] = InputMap.action_get_events(action)
	InputMap.action_erase_events(action)
	var replaced: bool = false
	for existing: InputEvent in events:
		if existing == old and not replaced:
			InputMap.action_add_event(action, event)
			replaced = true
		else:
			InputMap.action_add_event(action, existing)
	if not replaced:
		InputMap.action_add_event(action, event)


static func save_controls() -> void:
	var config: ConfigFile = ConfigFile.new()
	for entry: Dictionary in ACTIONS:
		var action: StringName = entry["action"]
		config.set_value(SECTION, String(action), InputMap.action_get_events(action))
	config.save(PATH)


static func load_controls() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(PATH) != OK:
		return
	for entry: Dictionary in ACTIONS:
		var action: StringName = entry["action"]
		var events: Variant = config.get_value(SECTION, String(action), null)
		if events is Array and not (events as Array).is_empty():
			InputMap.action_erase_events(action)
			for event: Variant in events:
				if event is InputEvent:
					InputMap.action_add_event(action, event)


## Resets every action to the project defaults and forgets saved changes.
static func reset_controls() -> void:
	InputMap.load_from_project_settings()
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


## Short name of a binding for the menu (key names come from the engine).
static func event_label(event: InputEvent) -> String:
	if event == null:
		return "-"
	if event is InputEventKey:
		var key: InputEventKey = event
		var code: Key = key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
		return OS.get_keycode_string(code)
	if event is InputEventMouseButton:
		var button: InputEventMouseButton = event
		match button.button_index:
			MOUSE_BUTTON_LEFT:
				return TranslationServer.translate(&"INPUT_MOUSE_LEFT")
			MOUSE_BUTTON_RIGHT:
				return TranslationServer.translate(&"INPUT_MOUSE_RIGHT")
			MOUSE_BUTTON_MIDDLE:
				return TranslationServer.translate(&"INPUT_MOUSE_MIDDLE")
		return TranslationServer.translate(&"INPUT_MOUSE_BUTTON").format({"n": button.button_index})
	if event is InputEventJoypadButton:
		var pad: InputEventJoypadButton = event
		return PAD_BUTTON_NAMES.get(pad.button_index, "#%d" % pad.button_index)
	if event is InputEventJoypadMotion:
		var motion: InputEventJoypadMotion = event
		match motion.axis:
			JOY_AXIS_TRIGGER_LEFT:
				return "LT"
			JOY_AXIS_TRIGGER_RIGHT:
				return "RT"
		return "%s%s" % [["LX", "LY", "RX", "RY"][clampi(motion.axis, 0, 3)], "+" if motion.axis_value > 0.0 else "-"]
	return event.as_text()
