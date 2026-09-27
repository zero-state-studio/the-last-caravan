class_name TuningPanel
extends CanvasLayer
## F1 panel of the visual prototype: sliders bound to ProtoSettings.
## Every visible text is a translation key (see localization/translations.csv).

signal settings_changed
signal save_requested

const SLIDERS: Array[Dictionary] = [
	{"key": "DEV_CAMERA_PITCH", "property": "camera_pitch", "min": 30.0, "max": 70.0, "step": 0.5},
	{"key": "DEV_CAMERA_DISTANCE", "property": "camera_distance", "min": 4.0, "max": 40.0, "step": 0.5},
	{"key": "DEV_CAMERA_FOV", "property": "camera_fov", "min": 10.0, "max": 75.0, "step": 0.5},
	{"key": "DEV_DOF_NEAR", "property": "dof_near_offset", "min": 0.0, "max": 20.0, "step": 0.5},
	{"key": "DEV_DOF_FAR", "property": "dof_far_offset", "min": 0.0, "max": 40.0, "step": 0.5},
	{"key": "DEV_DOF_AMOUNT", "property": "dof_amount", "min": 0.0, "max": 0.5, "step": 0.01},
	{"key": "DEV_SPRITE_PIXEL_SIZE", "property": "sprite_pixel_size", "min": 0.02, "max": 0.06, "step": 0.0001},
	{"key": "DEV_WORLD_TEXELS", "property": "world_texels_per_meter", "min": 12.0, "max": 48.0, "step": 1.0},
	{"key": "DEV_SUN_ELEVATION", "property": "sun_elevation", "min": 2.0, "max": 60.0, "step": 0.5},
	{"key": "DEV_SUN_AZIMUTH", "property": "sun_azimuth", "min": 0.0, "max": 360.0, "step": 1.0},
	{"key": "DEV_SUN_ENERGY", "property": "sun_energy", "min": 0.0, "max": 5.0, "step": 0.05},
	{"key": "DEV_FOG_DENSITY", "property": "fog_density", "min": 0.0, "max": 0.05, "step": 0.001},
	{"key": "DEV_PALETTE_STRENGTH", "property": "palette_strength", "min": 0.0, "max": 2.0, "step": 0.05},
]
const TOGGLES: Array[Dictionary] = [
	{"key": "DEV_CAMERA_ORTHOGRAPHIC", "property": "camera_orthographic"},
	{"key": "DEV_SPRITE_BILLBOARD_FIXED_Y", "property": "sprite_billboard_fixed_y"},
	{"key": "DEV_SPRITE_UPRIGHT_DEPTH", "property": "sprite_upright_depth"},
	{"key": "DEV_SPRITE_SHADED", "property": "sprite_shaded"},
]
const PANEL_WIDTH: float = 380.0

var settings: ProtoSettings

var _root: PanelContainer
var _fps_label: Label
var _status_label: Label


func _init(target_settings: ProtoSettings) -> void:
	settings = target_settings
	layer = 10


func _ready() -> void:
	_build()
	_root.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_tuning_panel"):
		_root.visible = not _root.visible
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if _root.visible:
		_fps_label.text = tr(&"DEV_FPS").format({"fps": Engine.get_frames_per_second()})


func set_panel_visible(value: bool) -> void:
	_root.visible = value


func is_panel_visible() -> bool:
	return _root.visible


func show_saved(file_name: String) -> void:
	_status_label.text = tr(&"DEV_SAVED").format({"file": file_name})


func _build() -> void:
	_root = PanelContainer.new()
	_root.anchor_bottom = 1.0
	_root.custom_minimum_size = Vector2(PANEL_WIDTH, 0.0)
	add_child(_root)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_root.add_child(scroll)
	var box: VBoxContainer = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)

	var title: Label = Label.new()
	title.text = "DEV_PANEL_TITLE"
	box.add_child(title)
	_fps_label = Label.new()
	_fps_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	box.add_child(_fps_label)

	for definition: Dictionary in SLIDERS:
		_add_slider(box, definition)
	for definition: Dictionary in TOGGLES:
		_add_toggle(box, definition)
	_add_color(box, "DEV_SUN_COLOR", "sun_color")

	var save_button: Button = Button.new()
	save_button.text = "DEV_SAVE"
	save_button.pressed.connect(func() -> void: save_requested.emit())
	box.add_child(save_button)
	_status_label = Label.new()
	_status_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_status_label)


func _add_slider(box: VBoxContainer, definition: Dictionary) -> void:
	var property: String = definition["property"]
	var header: HBoxContainer = HBoxContainer.new()
	var label: Label = Label.new()
	label.text = definition["key"]
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(label)
	var value_label: Label = Label.new()
	value_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	header.add_child(value_label)
	box.add_child(header)
	var slider: HSlider = HSlider.new()
	slider.min_value = definition["min"]
	slider.max_value = definition["max"]
	slider.step = definition["step"]
	slider.value = float(settings.get(property))
	value_label.text = _format_value(slider.value, slider.step)
	slider.value_changed.connect(func(value: float) -> void:
		settings.set(property, value)
		value_label.text = _format_value(value, slider.step)
		settings_changed.emit())
	box.add_child(slider)


func _add_toggle(box: VBoxContainer, definition: Dictionary) -> void:
	var property: String = definition["property"]
	var check: CheckBox = CheckBox.new()
	check.text = definition["key"]
	check.button_pressed = bool(settings.get(property))
	check.toggled.connect(func(pressed: bool) -> void:
		settings.set(property, pressed)
		settings_changed.emit())
	box.add_child(check)


func _add_color(box: VBoxContainer, key: String, property: String) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	var label: Label = Label.new()
	label.text = key
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var picker: ColorPickerButton = ColorPickerButton.new()
	picker.custom_minimum_size = Vector2(64.0, 0.0)
	picker.edit_alpha = false
	picker.color = settings.get(property)
	picker.color_changed.connect(func(color: Color) -> void:
		settings.set(property, color)
		settings_changed.emit())
	row.add_child(picker)
	box.add_child(row)


func _format_value(value: float, step: float) -> String:
	if step >= 1.0:
		return "%d" % roundi(value)
	if step >= 0.1:
		return "%.1f" % value
	if step >= 0.01:
		return "%.2f" % value
	if step >= 0.001:
		return "%.3f" % value
	return "%.4f" % value
