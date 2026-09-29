class_name ItemToast
extends CanvasLayer
## A short line when an item goes into the bisaccia (128): «Found: Felt
## patch», top centre, fading in and out. Listens to GameState.

const SHOW_SECONDS: float = 2.6
const FADE_SECONDS: float = 0.3

var _label: Label
var _left: float = 0.0


func _ready() -> void:
	layer = 8
	process_mode = Node.PROCESS_MODE_ALWAYS
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_label.custom_minimum_size = Vector2(700.0, 40.0)
	_label.position = Vector2(-350.0, 150.0)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	UiStyle.style_label(_label, UiStyle.text_size(), UiStyle.SPEAKER)
	_label.add_theme_color_override(&"font_outline_color", UiStyle.OUTLINE)
	_label.add_theme_constant_override(&"outline_size", 6)
	_label.modulate.a = 0.0
	add_child(_label)
	GameState.events.item_received.connect(show_item)


func show_item(item_id: StringName) -> void:
	var item: ItemDefinition = ItemCatalog.main().find(item_id)
	if item == null:
		return
	_label.text = tr(&"TOAST_FOUND").format({"name": tr(item.name_key)})
	_left = SHOW_SECONDS


func current_text() -> String:
	return _label.text if _left > 0.0 else ""


func _process(delta: float) -> void:
	if _left <= 0.0:
		return
	_left = maxf(0.0, _left - delta)
	var shown: float = SHOW_SECONDS - _left
	_label.modulate.a = clampf(minf(shown, _left) / FADE_SECONDS, 0.0, 1.0)
