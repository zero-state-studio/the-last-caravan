class_name RopeCounter
extends CanvasLayer
## The rope of the saved (106, 125): top right, a length of rope with one
## knot per person Ottavia brought back, and their number. A new knot
## tightens with a short animation. Twisted strands, frayed ends, pixel
## knots, drawn in code.

const ROPE_COLOR: Color = Color(0.79, 0.66, 0.43)
const ROPE_SHADE: Color = Color(0.56, 0.44, 0.27)
const KNOT_COLOR: Color = Color(0.93, 0.82, 0.58)
const OUTLINE: Color = UiStyle.OUTLINE
const KNOT_SPACING: float = 22.0
const ROPE_LENGTH: float = 200.0
## Twist of the strands: one shaded pixel pair every this many pixels.
const TWIST_PIXELS: int = 4

var knots: int = 0
var _drawing: Control
var _label: Label
var _new_knot_scale: float = 1.0


func _ready() -> void:
	layer = 9
	add_to_group(&"rope_counter")
	_drawing = Control.new()
	_drawing.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_drawing.position = Vector2(-260.0, 24.0)
	_drawing.custom_minimum_size = Vector2(230.0, 40.0)
	_drawing.draw.connect(_draw_rope)
	add_child(_drawing)
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_label.position = Vector2(-44.0, 30.0)
	UiStyle.style_label(_label, UiStyle.BODY_SIZE, KNOT_COLOR)
	_label.add_theme_color_override(&"font_outline_color", OUTLINE)
	_label.add_theme_constant_override(&"outline_size", 5)
	add_child(_label)
	set_knots(GameState.knots)


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
	# Outline, body, and the twist: diagonal shaded pixels along the rope.
	_drawing.draw_rect(Rect2(6.0, y - 4.0, ROPE_LENGTH - 6.0, 8.0), OUTLINE)
	_drawing.draw_rect(Rect2(6.0, y - 2.0, ROPE_LENGTH - 6.0, 4.0), ROPE_COLOR)
	for x: int in range(8, int(ROPE_LENGTH) - 2, TWIST_PIXELS):
		_drawing.draw_rect(Rect2(x, y - 2.0, 1.0, 2.0), ROPE_SHADE)
		_drawing.draw_rect(Rect2(x + 1, y, 1.0, 2.0), ROPE_SHADE)
	# Frayed end on the left: loose fibres.
	for fibre: Vector3 in [Vector3(0.0, -3.0, 6.0), Vector3(1.0, 0.0, 6.0), Vector3(0.0, 2.0, 6.0)]:
		_drawing.draw_rect(Rect2(fibre.x, y + fibre.y, fibre.z, 1.0), ROPE_SHADE)
	for index: int in knots:
		var x: float = ROPE_LENGTH - 10.0 - index * KNOT_SPACING
		if x < 12.0:
			break
		var size: float = roundf(8.0 * (_new_knot_scale if index == knots - 1 else 1.0))
		var knot: Rect2 = Rect2(roundf(x - size * 0.5), roundf(y - size * 0.5), size, size)
		_drawing.draw_rect(knot.grow(2.0), OUTLINE)
		_drawing.draw_rect(knot, KNOT_COLOR)
		# The loop of the knot: a shaded cross pixel line.
		_drawing.draw_rect(Rect2(knot.position.x + 1.0, knot.get_center().y, size - 2.0, 1.0), ROPE_SHADE)
		_drawing.draw_rect(Rect2(knot.get_center().x, knot.position.y + 1.0, 1.0, size - 2.0), ROPE_SHADE)
