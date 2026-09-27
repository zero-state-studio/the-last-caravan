class_name CombatHud
extends CanvasLayer
## On-screen measures of the combat prototype (phase 3), switched on from
## the F1 panel: health, breath, and a signal when a deflection or a
## counter-hit succeeds. Every text is a translation key. The UI never
## drifts with the world palette (51).

const BAR_SIZE: Vector2 = Vector2(220.0, 14.0)
const MESSAGE_SECONDS: float = 1.6
const HEALTH_COLOR: Color = Color(0.93, 0.7, 0.35)
const BREATH_COLOR: Color = Color(0.65, 0.66, 0.83)
const MESSAGE_COLORS: Dictionary = {
	&"COMBAT_DEFLECT": Color(0.85, 0.9, 1.0),
	&"COMBAT_COUNTER": Color(1.0, 0.77, 0.42),
	&"COMBAT_BREATHLESS": Color(0.6, 0.65, 1.0),
	&"COMBAT_NO_COMPANION": Color(0.9, 0.87, 0.8),
}

var ottavia: OttaviaProto

var _health_bar: ProgressBar
var _breath_bar: ProgressBar
var _message: Label
var _message_left: float = 0.0
var _boss_box: VBoxContainer
var _boss_label: Label
var _boss_bar: ProgressBar


func _ready() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(&"combat_hud")
	var box: VBoxContainer = VBoxContainer.new()
	box.position = Vector2(16.0, 16.0)
	add_child(box)
	_health_bar = _add_bar(box, "HUD_HEALTH", HEALTH_COLOR)
	_breath_bar = _add_bar(box, "HUD_BREATH", BREATH_COLOR)
	_message = Label.new()
	_message.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_message.position = Vector2(-200.0, 96.0)
	_message.size = Vector2(400.0, 40.0)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.add_theme_font_size_override(&"font_size", 28)
	_message.add_theme_constant_override(&"outline_size", 6)
	_message.add_theme_color_override(&"font_outline_color", Color(0.08, 0.07, 0.13))
	add_child(_message)
	# Boss name and health, bottom center, only while a boss fight is on.
	_boss_box = VBoxContainer.new()
	_boss_box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_boss_box.position = Vector2(-220.0, -70.0)
	_boss_box.custom_minimum_size = Vector2(440.0, 0.0)
	add_child(_boss_box)
	_boss_label = Label.new()
	_boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_label.add_theme_constant_override(&"outline_size", 4)
	_boss_label.add_theme_color_override(&"font_outline_color", Color(0.08, 0.07, 0.13))
	_boss_box.add_child(_boss_label)
	_boss_bar = ProgressBar.new()
	_boss_bar.custom_minimum_size = Vector2(440.0, 12.0)
	_boss_bar.show_percentage = false
	var fill: StyleBoxFlat = StyleBoxFlat.new()
	fill.bg_color = Color(0.83, 0.54, 0.23)
	_boss_bar.add_theme_stylebox_override(&"fill", fill)
	var background: StyleBoxFlat = StyleBoxFlat.new()
	background.bg_color = Color(0.08, 0.07, 0.13, 0.75)
	_boss_bar.add_theme_stylebox_override(&"background", background)
	_boss_box.add_child(_boss_bar)
	_boss_box.visible = false


func bind(target: OttaviaProto) -> void:
	ottavia = target
	ottavia.combat.message.connect(show_message)


func show_message(key: StringName) -> void:
	_message.text = key
	_message.add_theme_color_override(&"font_color", MESSAGE_COLORS.get(key, Color.WHITE))
	_message.modulate.a = 1.0
	_message_left = MESSAGE_SECONDS


func _process(delta: float) -> void:
	if ottavia == null:
		return
	_health_bar.max_value = ottavia.max_health
	_health_bar.value = ottavia.health
	_breath_bar.max_value = ottavia.combat.tuning.max_stamina
	_breath_bar.value = ottavia.combat.stamina
	# Real time: messages stay readable during freeze frames.
	_message_left = maxf(0.0, _message_left - delta / maxf(Engine.time_scale, 0.001))
	_message.modulate.a = clampf(_message_left / 0.3, 0.0, 1.0)
	var boss: BossEnemy = get_tree().get_first_node_in_group(&"active_boss") as BossEnemy
	_boss_box.visible = boss != null
	if boss != null:
		_boss_label.text = boss.title_key
		_boss_bar.max_value = boss.max_health
		_boss_bar.value = boss.health


func _add_bar(box: VBoxContainer, label_key: String, color: Color) -> ProgressBar:
	var label: Label = Label.new()
	label.text = label_key
	label.add_theme_constant_override(&"outline_size", 4)
	label.add_theme_color_override(&"font_outline_color", Color(0.08, 0.07, 0.13))
	box.add_child(label)
	var bar: ProgressBar = ProgressBar.new()
	bar.custom_minimum_size = BAR_SIZE
	bar.show_percentage = false
	var fill: StyleBoxFlat = StyleBoxFlat.new()
	fill.bg_color = color
	bar.add_theme_stylebox_override(&"fill", fill)
	var background: StyleBoxFlat = StyleBoxFlat.new()
	background.bg_color = Color(0.08, 0.07, 0.13, 0.75)
	bar.add_theme_stylebox_override(&"background", background)
	box.add_child(bar)
	return bar
