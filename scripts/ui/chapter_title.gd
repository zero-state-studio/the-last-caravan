class_name ChapterTitle
extends CanvasLayer
## Black screen with a big title that fades in and out (125), for example
## «Ne restano dieci». Also shows, once, the empty silhouette of the
## farewell lantern in the menu (88).

const LANTERN_COLOR: Color = Color(0.93, 0.8, 0.52)

var _black: ColorRect
var _title: Label
var _lantern: Control


func _ready() -> void:
	layer = 60
	_black = ColorRect.new()
	_black.color = Color(0.0, 0.0, 0.0, 0.0)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_black.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_black)
	_title = Label.new()
	_title.set_anchors_preset(Control.PRESET_FULL_RECT)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override(&"font_size", 52)
	_title.modulate.a = 0.0
	add_child(_title)
	_lantern = Control.new()
	_lantern.set_anchors_preset(Control.PRESET_CENTER)
	_lantern.custom_minimum_size = Vector2(120.0, 200.0)
	_lantern.position = Vector2(-60.0, -100.0)
	_lantern.draw.connect(_draw_lantern)
	_lantern.modulate.a = 0.0
	add_child(_lantern)


func fade_to_black(seconds: float) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_black, "color:a", 1.0, seconds)
	await tween.finished


## The title on black: in, hold, out.
func show_title(key: StringName, hold_seconds: float) -> void:
	_title.text = key
	var tween: Tween = create_tween()
	tween.tween_property(_title, "modulate:a", 1.0, 1.2)
	tween.tween_interval(hold_seconds)
	tween.tween_property(_title, "modulate:a", 0.0, 1.2)
	await tween.finished


func is_title_visible() -> bool:
	return _title.modulate.a > 0.01


## The farewell lantern (88), still empty: only its outline.
func show_lantern_silhouette(seconds: float) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_black, "color:a", 0.75, 0.6)
	tween.parallel().tween_property(_lantern, "modulate:a", 1.0, 0.8)
	tween.tween_interval(seconds)
	tween.tween_property(_lantern, "modulate:a", 0.0, 0.6)
	await tween.finished


## Outline of an old lantern: ring, cap, cage, base; thick pixel lines.
func _draw_lantern() -> void:
	var w: float = 4.0
	var c: Color = LANTERN_COLOR
	_lantern.draw_arc(Vector2(60.0, 18.0), 12.0, PI, TAU, 10, c, w)
	_lantern.draw_polyline(PackedVector2Array([Vector2(36.0, 52.0), Vector2(48.0, 30.0), Vector2(72.0, 30.0), Vector2(84.0, 52.0), Vector2(36.0, 52.0)]), c, w)
	_lantern.draw_rect(Rect2(34.0, 52.0, 52.0, 100.0), c, false, w)
	for x: float in [51.0, 69.0]:
		_lantern.draw_line(Vector2(x, 52.0), Vector2(x, 152.0), c, w * 0.75)
	_lantern.draw_polyline(PackedVector2Array([Vector2(30.0, 152.0), Vector2(90.0, 152.0), Vector2(84.0, 170.0), Vector2(36.0, 170.0), Vector2(30.0, 152.0)]), c, w)
