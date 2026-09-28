class_name RopeCounter
extends CanvasLayer
## The rope of the saved (106, 125): top right, a length of rope with one
## knot per person Ottavia brought back, and their number. A new knot
## tightens with a short animation. Provisional drawing until the final
## interface (step 6).

const ROPE_COLOR: Color = Color(0.79, 0.66, 0.43)
const KNOT_COLOR: Color = Color(0.93, 0.82, 0.58)
const OUTLINE: Color = Color(0.12, 0.1, 0.2)
const KNOT_SPACING: float = 22.0

var knots: int = 0
var _drawing: Control
var _label: Label
var _new_knot_scale: float = 1.0


func _ready() -> void:
	layer = 9
	_drawing = Control.new()
	_drawing.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_drawing.position = Vector2(-260.0, 24.0)
	_drawing.custom_minimum_size = Vector2(230.0, 40.0)
	_drawing.draw.connect(_draw_rope)
	add_child(_drawing)
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_label.position = Vector2(-44.0, 30.0)
	_label.add_theme_font_size_override(&"font_size", 20)
	_label.add_theme_color_override(&"font_outline_color", OUTLINE)
	_label.add_theme_constant_override(&"outline_size", 5)
	add_child(_label)
	set_knots(PrologueState.knots)


func set_knots(count: int) -> void:
	knots = count
	_label.text = str(knots)
	_drawing.queue_redraw()


## A new person saved: the knot tightens.
func add_knot() -> void:
	set_knots(knots + 1)
	var tween: Tween = create_tween()
	_new_knot_scale = 2.2
	tween.tween_method(func(value: float) -> void:
		_new_knot_scale = value
		_drawing.queue_redraw(), 2.2, 1.0, 0.45).set_trans(Tween.TRANS_BACK)


func _draw_rope() -> void:
	var y: float = 20.0
	_drawing.draw_line(Vector2(0.0, y), Vector2(200.0, y), OUTLINE, 7.0)
	_drawing.draw_line(Vector2(0.0, y), Vector2(200.0, y), ROPE_COLOR, 4.0)
	for index: int in knots:
		var x: float = 190.0 - index * KNOT_SPACING
		if x < 10.0:
			break
		var size: float = 6.0 * (_new_knot_scale if index == knots - 1 else 1.0)
		_drawing.draw_rect(Rect2(x - size * 0.5 - 1.5, y - size * 0.5 - 1.5, size + 3.0, size + 3.0), OUTLINE)
		_drawing.draw_rect(Rect2(x - size * 0.5, y - size * 0.5, size, size), KNOT_COLOR)
