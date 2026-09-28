class_name SpeechBubble
extends CanvasLayer
## A line said by someone in the world, shown above their head (the verdict
## chain, 106): a small dark box that follows the speaker on screen. A
## speaker out of view keeps the box on the screen edge on their side, so
## the line is always read (96). Text is a translation key.

## Above the feet, in metres: over the head of a grown-up.
const HEAD_METERS: float = 2.2
const EDGE_MARGIN: float = 16.0
const MAX_WIDTH: float = 380.0

var _panel: PanelContainer
var _line: Label
var _target: Node3D


func _ready() -> void:
	layer = 8
	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_theme_stylebox_override(&"panel", UiStyle.panel_style(8.0))
	add_child(_panel)
	_line = Label.new()
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(_line)
	_panel.visible = false


func show_over(target: Node3D, line_key: StringName) -> void:
	_target = target
	_line.text = line_key
	UiStyle.style_label(_line, UiStyle.text_size())
	# Short lines stay on one row; long ones wrap at MAX_WIDTH.
	var font: Font = _line.get_theme_font(&"font")
	var width: float = font.get_string_size(tr(line_key), HORIZONTAL_ALIGNMENT_LEFT, -1.0, _line.get_theme_font_size(&"font_size")).x
	var wraps: bool = width > MAX_WIDTH
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wraps else TextServer.AUTOWRAP_OFF
	_line.custom_minimum_size = Vector2(MAX_WIDTH if wraps else 0.0, 0.0)
	_line.size = Vector2.ZERO
	_panel.size = Vector2.ZERO
	_panel.visible = true
	_panel.reset_size.call_deferred()
	_follow()


func hide_bubble() -> void:
	_panel.visible = false
	_target = null


func is_showing() -> bool:
	return _panel.visible


func current_line() -> String:
	return _line.text


func current_target() -> Node3D:
	return _target


func _process(_delta: float) -> void:
	if _panel.visible:
		_follow()


func _follow() -> void:
	if _target == null or not is_instance_valid(_target):
		return
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return
	var head: Vector3 = _target.global_position + Vector3.UP * HEAD_METERS
	var screen: Vector2 = camera.unproject_position(head)
	if camera.is_position_behind(head):
		screen.x = -screen.x
	var size: Vector2 = _panel.size
	var view: Vector2 = get_viewport().get_visible_rect().size
	var at: Vector2 = screen - Vector2(size.x * 0.5, size.y + 6.0)
	at.x = clampf(at.x, EDGE_MARGIN, view.x - size.x - EDGE_MARGIN)
	at.y = clampf(at.y, EDGE_MARGIN, view.y - size.y - EDGE_MARGIN)
	_panel.position = at
