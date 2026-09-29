class_name OptionsMenu
extends CanvasLayer
## The pause menu (96, 125, 128): the pages of the bisaccia, then the
## options. The coat (patches sewn in three slots, changed only at the
## caravan), the bisaccia (warm stones and tools), the memories, the
## farewell lantern filling piece by piece (88, once the verdict has shown
## it), and the options: screen shake, flashes, aim assist, difficulty,
## text size and remappable controls, one keyboard or mouse binding and one
## gamepad binding per action. Opens with `open_options` (Esc, Menu/Start)
## and pauses the game; LB and RB turn the pages. Every visible text is a
## translation key.

const PANEL_SIZE: Vector2 = Vector2(860.0, 700.0)
enum Page { COAT, SATCHEL, MEMORIES, LANTERN, OPTIONS }

var _root: PanelContainer
var _tabs: TabContainer
var _lantern_box: VBoxContainer
var lantern: LanternEmblem
var _coat_box: VBoxContainer
var _satchel_box: VBoxContainer
var _memories_box: VBoxContainer
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
	lantern.pieces = LanternProgress.pieces
	_tabs.set_tab_hidden(Page.LANTERN, not LanternProgress.revealed)
	_refresh_pages()
	get_tree().paused = true
	_refresh_bindings()


func open_page(page: Page) -> void:
	if not is_open():
		open()
	if not _tabs.is_tab_hidden(page):
		_tabs.current_tab = page


## The lantern page exists only once the verdict has shown the lantern.
func has_page(page: Page) -> bool:
	return not _tabs.is_tab_hidden(page)


func current_page() -> Page:
	return _tabs.current_tab as Page


func close() -> void:
	_cancel_wait()
	_root.visible = false
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
	elif is_open() and event is InputEventJoypadButton and event.is_pressed():
		var button: JoyButton = (event as InputEventJoypadButton).button_index
		if button == JOY_BUTTON_LEFT_SHOULDER or button == JOY_BUTTON_RIGHT_SHOULDER:
			_turn_page(-1 if button == JOY_BUTTON_LEFT_SHOULDER else 1)
			get_viewport().set_input_as_handled()


func _turn_page(step: int) -> void:
	var page: int = _tabs.current_tab
	for attempt: int in _tabs.get_tab_count():
		page = posmod(page + step, _tabs.get_tab_count())
		if not _tabs.is_tab_hidden(page):
			_tabs.current_tab = page
			return


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
	_root = PanelContainer.new()
	_root.add_theme_stylebox_override(&"panel", UiStyle.panel_style(16.0))
	_root.custom_minimum_size = PANEL_SIZE
	_root.set_anchors_preset(Control.PRESET_CENTER)
	_root.position = -PANEL_SIZE * 0.5
	add_child(_root)
	_tabs = TabContainer.new()
	_root.add_child(_tabs)
	_coat_box = _add_page("PAUSE_TAB_COAT")
	_satchel_box = _add_page("PAUSE_TAB_SATCHEL")
	_memories_box = _add_page("PAUSE_TAB_MEMORIES")
	_lantern_box = VBoxContainer.new()
	_lantern_box.name = "PAUSE_TAB_LANTERN"
	_lantern_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_tabs.add_child(_lantern_box)
	lantern = LanternEmblem.new()
	lantern.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_lantern_box.add_child(lantern)
	var caption: Label = Label.new()
	caption.text = "PAUSE_LANTERN"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.style_label(caption, UiStyle.SMALL_SIZE, LanternEmblem.LINE)
	_lantern_box.add_child(caption)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.name = "PAUSE_TAB_OPTIONS"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_tabs.add_child(scroll)
	var box: VBoxContainer = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)

	var title: Label = Label.new()
	title.text = "OPTIONS_TITLE"
	UiStyle.style_label(title, UiStyle.BODY_SIZE, UiStyle.SPEAKER)
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
	var goals: CheckBox = CheckBox.new()
	goals.text = "OPTIONS_SHOW_GOALS"
	goals.button_pressed = GameOptions.show_goals
	goals.toggled.connect(func(pressed: bool) -> void:
		GameOptions.show_goals = pressed
		for node: Node in get_tree().get_nodes_in_group(&"hint_banner"):
			(node as HintBanner).apply_goal_option())
	box.add_child(goals)
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
			button.custom_minimum_size = Vector2(260.0, 0.0)
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


func _add_page(title_key: String) -> VBoxContainer:
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.name = title_key
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_tabs.add_child(scroll)
	var box: VBoxContainer = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override(&"separation", 10)
	scroll.add_child(box)
	return box


# --- Pages of the bisaccia (128) --------------------------------------------

func _refresh_pages() -> void:
	_refresh_coat()
	_refresh_satchel()
	_refresh_memories()


## Three slots, each a choice among the patches found; away from the
## caravan the slots can be read but not changed.
func _refresh_coat() -> void:
	_clear(_coat_box)
	var catalog: ItemCatalog = ItemCatalog.main()
	_coat_box.add_child(_text("PAUSE_COAT_INTRO" if GameState.at_caravan else "PAUSE_COAT_AWAY", UiStyle.LIGHT))
	for slot: int in GameState.COAT_SLOTS:
		var row: HBoxContainer = HBoxContainer.new()
		var label: Label = Label.new()
		label.text = tr(&"PAUSE_COAT_SLOT").format({"n": slot + 1})
		label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		label.custom_minimum_size = Vector2(180.0, 0.0)
		row.add_child(label)
		var picker: OptionButton = OptionButton.new()
		picker.custom_minimum_size = Vector2(360.0, 0.0)
		var options: Array[StringName] = [GameState.EMPTY_SLOT]
		picker.add_item("PATCH_NONE")
		for patch: StringName in GameState.found_patches:
			var item: ItemDefinition = catalog.find(patch)
			if item != null:
				options.append(patch)
				picker.add_item(item.name_key)
		picker.selected = maxi(0, options.find(GameState.sewn_patches[slot]))
		picker.disabled = not GameState.at_caravan
		var this_slot: int = slot
		picker.item_selected.connect(func(index: int) -> void:
			GameState.sew(this_slot, options[index])
			_refresh_coat.call_deferred())
		row.add_child(picker)
		_coat_box.add_child(row)
	_coat_box.add_child(HSeparator.new())
	if GameState.found_patches.is_empty():
		_coat_box.add_child(_text("PAUSE_COAT_NONE", UiStyle.LIGHT))
	for patch: StringName in GameState.found_patches:
		var item: ItemDefinition = catalog.find(patch)
		if item != null:
			_coat_box.add_child(_text(item.name_key, UiStyle.SPEAKER))
			_coat_box.add_child(_text(item.text_key, UiStyle.TEXT))


func _refresh_satchel() -> void:
	_clear(_satchel_box)
	var catalog: ItemCatalog = ItemCatalog.main()
	var stone: ItemDefinition = catalog.find(&"warm_stone")
	var max_stones: int = 3
	var player: OttaviaProto = get_tree().get_first_node_in_group(&"player") as OttaviaProto
	if player != null:
		max_stones = player.combat.tuning.warm_stone_max
	var count: Label = _text("", UiStyle.SPEAKER)
	count.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	count.text = tr(&"PAUSE_SATCHEL_STONES").format({"n": GameState.warm_stones, "max": max_stones})
	_satchel_box.add_child(count)
	if stone != null:
		_satchel_box.add_child(_text(stone.text_key, UiStyle.TEXT))
	_satchel_box.add_child(HSeparator.new())
	if GameState.tools.is_empty():
		_satchel_box.add_child(_text("PAUSE_SATCHEL_NO_TOOLS", UiStyle.LIGHT))
	for tool_id: StringName in GameState.tools:
		var item: ItemDefinition = catalog.find(tool_id)
		if item != null:
			_satchel_box.add_child(_text(item.name_key, UiStyle.SPEAKER))
			_satchel_box.add_child(_text(item.text_key, UiStyle.TEXT))


func _refresh_memories() -> void:
	_clear(_memories_box)
	if GameState.memories.is_empty():
		_memories_box.add_child(_text("PAUSE_MEMORIES_NONE", UiStyle.LIGHT))
	var catalog: ItemCatalog = ItemCatalog.main()
	for memory: StringName in GameState.memories:
		var item: ItemDefinition = catalog.find(memory)
		if item != null:
			_memories_box.add_child(_text(item.name_key, UiStyle.SPEAKER))
			_memories_box.add_child(_text(item.text_key, UiStyle.TEXT))


func _text(key: String, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = key
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(PANEL_SIZE.x - 80.0, 0.0)
	UiStyle.style_label(label, UiStyle.text_size(), color)
	return label


func _clear(box: Container) -> void:
	for child: Node in box.get_children():
		box.remove_child(child)
		child.queue_free()
