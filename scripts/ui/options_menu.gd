class_name OptionsMenu
extends CanvasLayer
## Pause and options menu (96, 125): screen shake, flashes, aim assist,
## text size and remappable controls, one keyboard or mouse binding and one
## gamepad binding per action. Beside it, once the verdict has shown it, the
## farewell lantern filling piece by piece (88). Opens with `open_options`
## (Esc, Menu/Start) and pauses the game. Every visible text is a
## translation key.

const PANEL_SIZE: Vector2 = Vector2(620.0, 640.0)

var _root: PanelContainer
var _lantern_box: VBoxContainer
var lantern: LanternEmblem
var _waiting_action: StringName = &""
var _waiting_device: InputRemap.Device = InputRemap.Device.KEYBOARD
var _waiting_button: Button
var _binding_buttons: Array[Dictionary] = []


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_root.visible = false


func is_open() -> bool:
	return _root.visible


func open() -> void:
	_root.visible = true
	_lantern_box.visible = LanternProgress.revealed
	lantern.pieces = LanternProgress.pieces
	get_tree().paused = true
	_refresh_bindings()


func close() -> void:
	_cancel_wait()
	_root.visible = false
	_lantern_box.visible = false
	get_tree().paused = false
	GameOptions.save_options()


func _input(event: InputEvent) -> void:
	if _waiting_action != &"":
		_capture(event)
		return
	if event.is_action_pressed(&"open_options"):
		if is_open():
			close()
		else:
			open()
		get_viewport().set_input_as_handled()


func _capture(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).keycode == KEY_ESCAPE and event.is_pressed():
		_cancel_wait()
		get_viewport().set_input_as_handled()
		return
	if not InputRemap.is_device_event(event, _waiting_device) or not event.is_pressed() or event.is_echo():
		return
	if event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) < 0.6:
		return
	var binding: InputEvent = event.duplicate()
	if binding is InputEventJoypadMotion:
		var motion: InputEventJoypadMotion = binding
		motion.axis_value = signf(motion.axis_value)
	# Any device, not only the one that was used to set it.
	binding.device = -1
	InputRemap.rebind(_waiting_action, binding)
	InputRemap.save_controls()
	_cancel_wait()
	_refresh_bindings()
	get_viewport().set_input_as_handled()


func _cancel_wait() -> void:
	_waiting_action = &""
	_waiting_button = null
	_refresh_bindings()


func _build() -> void:
	_lantern_box = VBoxContainer.new()
	_lantern_box.set_anchors_preset(Control.PRESET_CENTER)
	_lantern_box.position = Vector2(-PANEL_SIZE.x * 0.5 - LanternEmblem.SIZE.x - 40.0, -LanternEmblem.SIZE.y * 0.5 - 20.0)
	_lantern_box.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_lantern_box)
	lantern = LanternEmblem.new()
	_lantern_box.add_child(lantern)
	var caption: Label = Label.new()
	caption.text = "PAUSE_LANTERN"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.custom_minimum_size = Vector2(LanternEmblem.SIZE.x, 0.0)
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.style_label(caption, UiStyle.SMALL_SIZE, LanternEmblem.LINE)
	_lantern_box.add_child(caption)
	_lantern_box.visible = false
	_root = PanelContainer.new()
	_root.add_theme_stylebox_override(&"panel", UiStyle.panel_style(16.0))
	_root.custom_minimum_size = PANEL_SIZE
	_root.set_anchors_preset(Control.PRESET_CENTER)
	_root.position = -PANEL_SIZE * 0.5
	add_child(_root)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_root.add_child(scroll)
	var box: VBoxContainer = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)

	var title: Label = Label.new()
	title.text = "OPTIONS_TITLE"
	title.add_theme_font_size_override(&"font_size", 24)
	box.add_child(title)
	_add_slider(box, "OPTIONS_SHAKE", GameOptions.shake_strength, func(value: float) -> void:
		GameOptions.shake_strength = value
		GameOptions.apply())
	_add_slider(box, "OPTIONS_FLASH", GameOptions.flash_strength, func(value: float) -> void:
		GameOptions.flash_strength = value
		GameOptions.apply())
	var aim: CheckBox = CheckBox.new()
	aim.text = "OPTIONS_AIM_ASSIST"
	aim.button_pressed = GameOptions.aim_assist
	aim.toggled.connect(func(pressed: bool) -> void: GameOptions.aim_assist = pressed)
	box.add_child(aim)
	var difficulty_row: HBoxContainer = HBoxContainer.new()
	var difficulty_label: Label = Label.new()
	difficulty_label.text = "OPTIONS_DIFFICULTY"
	difficulty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	difficulty_row.add_child(difficulty_label)
	var difficulty: OptionButton = OptionButton.new()
	for key: String in ["DIFFICULTY_EASY", "DIFFICULTY_MEDIUM", "DIFFICULTY_HARD"]:
		difficulty.add_item(key)
	difficulty.selected = GameOptions.difficulty
	difficulty.item_selected.connect(func(index: int) -> void: GameOptions.difficulty = index)
	difficulty_row.add_child(difficulty)
	box.add_child(difficulty_row)
	var text_row: HBoxContainer = HBoxContainer.new()
	var text_label: Label = Label.new()
	text_label.text = "OPTIONS_TEXT_SIZE"
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_row.add_child(text_label)
	var text_size: OptionButton = OptionButton.new()
	for key: String in ["TEXT_SIZE_NORMAL", "TEXT_SIZE_LARGE", "TEXT_SIZE_LARGEST"]:
		text_size.add_item(key)
	text_size.selected = maxi(0, GameOptions.TEXT_SCALES.find(GameOptions.text_scale))
	text_size.item_selected.connect(func(index: int) -> void: GameOptions.text_scale = GameOptions.TEXT_SCALES[index])
	text_row.add_child(text_size)
	box.add_child(text_row)

	box.add_child(HSeparator.new())
	var controls: Label = Label.new()
	controls.text = "OPTIONS_CONTROLS"
	box.add_child(controls)
	var grid: GridContainer = GridContainer.new()
	grid.columns = 3
	box.add_child(grid)
	for header: String in ["", "OPTIONS_KEYBOARD", "OPTIONS_GAMEPAD"]:
		var label: Label = Label.new()
		label.text = header
		grid.add_child(label)
	for entry: Dictionary in InputRemap.ACTIONS:
		var name_label: Label = Label.new()
		name_label.text = entry["key"]
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(name_label)
		for device: InputRemap.Device in [InputRemap.Device.KEYBOARD, InputRemap.Device.GAMEPAD]:
			var button: Button = Button.new()
			button.custom_minimum_size = Vector2(170.0, 0.0)
			button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
			var action: StringName = entry["action"]
			button.pressed.connect(func() -> void: _start_wait(action, device, button))
			grid.add_child(button)
			_binding_buttons.append({"action": action, "device": device, "button": button})

	var row: HBoxContainer = HBoxContainer.new()
	box.add_child(row)
	var reset: Button = Button.new()
	reset.text = "OPTIONS_RESET"
	reset.pressed.connect(func() -> void:
		InputRemap.reset_controls()
		_refresh_bindings())
	row.add_child(reset)
	var close_button: Button = Button.new()
	close_button.text = "OPTIONS_CLOSE"
	close_button.pressed.connect(close)
	row.add_child(close_button)


func _start_wait(action: StringName, device: InputRemap.Device, button: Button) -> void:
	_waiting_action = action
	_waiting_device = device
	_waiting_button = button
	button.text = tr(&"OPTIONS_PRESS")


func _refresh_bindings() -> void:
	for entry: Dictionary in _binding_buttons:
		var button: Button = entry["button"]
		if button == _waiting_button:
			continue
		button.text = InputRemap.event_label(InputRemap.main_event(entry["action"], entry["device"]))


func _add_slider(box: VBoxContainer, key: String, value: float, on_change: Callable) -> void:
	var label: Label = Label.new()
	label.text = key
	box.add_child(label)
	var slider: HSlider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.value_changed.connect(on_change)
	box.add_child(slider)
