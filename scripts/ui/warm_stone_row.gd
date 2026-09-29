class_name WarmStoneRow
extends Control
## The warm stones carried (129), beside the sundial: one small glowing
## pebble each, dark sockets for the missing ones; the pebble being squeezed
## fills with light. Drawn with whole pixels in code, never tinted by the
## world palette (51).

const STONE_SIZE: Vector2 = Vector2(14.0, 10.0)
const SPACING: float = 20.0
const GLOW: Color = Color(1.0, 0.62, 0.3)
const CORE: Color = Color(1.0, 0.86, 0.6)

var stones: int = 0
var max_stones: int = 3
var squeeze: float = 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(SPACING * 3.0 + 4.0, STONE_SIZE.y + 8.0)


func set_values(count: int, maximum: int, progress: float) -> void:
	if count != stones or maximum != max_stones or not is_equal_approx(progress, squeeze):
		stones = count
		max_stones = maximum
		squeeze = progress
		custom_minimum_size.x = SPACING * max_stones + 4.0
		queue_redraw()


func _draw() -> void:
	for index: int in max_stones:
		var rect: Rect2 = Rect2(Vector2(2.0 + index * SPACING, 4.0), STONE_SIZE)
		draw_rect(rect.grow(2.0), UiStyle.OUTLINE)
		if index >= stones:
			draw_rect(rect, UiStyle.WARM_DARK * Color(0.6, 0.6, 0.6))
			continue
		draw_rect(rect, UiStyle.WARM_DARK)
		draw_rect(Rect2(rect.position + Vector2(2.0, 2.0), rect.size - Vector2(4.0, 4.0)), GLOW)
		draw_rect(Rect2(rect.position + Vector2(4.0, 3.0), Vector2(4.0, 2.0)), CORE)
		# The last stone is the one squeezed: its light rises from the bottom.
		if index == stones - 1 and squeeze > 0.0:
			var height: float = roundf(rect.size.y * squeeze)
			draw_rect(Rect2(rect.position.x, rect.end.y - height, rect.size.x, height), CORE)
