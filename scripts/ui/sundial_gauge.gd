class_name SundialGauge
extends Control
## Health and breath (125): bottom left, a small half disc like the
## sundial of the caravan. The outer arc, warm, is health; the inner one,
## light, is breath. Both fill from left to right like the shadow on a
## sundial; hour ticks and a gnomon in the middle. Drawn with whole pixels.

const RADIUS: float = 58.0
const HEALTH_WIDTH: float = 9.0
const BREATH_WIDTH: float = 6.0
const GAP: float = 4.0
const TICKS: int = 7
## Below this share the health arc pulses.
const LOW_HEALTH: float = 0.25

var health_ratio: float = 1.0
var breath_ratio: float = 1.0
var breathless: bool = false
var _time: float = 0.0


func _init() -> void:
	custom_minimum_size = Vector2(RADIUS * 2.0 + 8.0, RADIUS + 10.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_values(health: float, breath: float, out_of_breath: bool) -> void:
	if not is_equal_approx(health, health_ratio) or not is_equal_approx(breath, breath_ratio) or out_of_breath != breathless:
		health_ratio = clampf(health, 0.0, 1.0)
		breath_ratio = clampf(breath, 0.0, 1.0)
		breathless = out_of_breath
		queue_redraw()


func _process(delta: float) -> void:
	if health_ratio < LOW_HEALTH or breathless:
		_time += delta
		queue_redraw()


func _draw() -> void:
	var centre: Vector2 = Vector2(RADIUS + 4.0, RADIUS + 4.0).round()
	# The dial: a dark half disc with a rim.
	draw_colored_polygon(_half_disc(centre, RADIUS + 3.0), UiStyle.OUTLINE)
	draw_colored_polygon(_half_disc(centre, RADIUS + 1.0), UiStyle.PANEL)
	var health_radius: float = RADIUS - 2.0 - HEALTH_WIDTH * 0.5
	var breath_radius: float = health_radius - HEALTH_WIDTH * 0.5 - GAP - BREATH_WIDTH * 0.5
	_arc(centre, health_radius, HEALTH_WIDTH, 1.0, UiStyle.WARM_DARK)
	var pulse: float = 0.75 + 0.25 * sin(_time * 8.0) if health_ratio < LOW_HEALTH else 1.0
	_arc(centre, health_radius, HEALTH_WIDTH, health_ratio, UiStyle.WARM * Color(pulse, pulse, pulse))
	_arc(centre, breath_radius, BREATH_WIDTH, 1.0, UiStyle.LIGHT_DARK)
	var breath_color: Color = UiStyle.LIGHT
	if breathless:
		breath_color = UiStyle.LIGHT.lerp(UiStyle.LIGHT_DARK, 0.5 + 0.5 * sin(_time * 10.0))
	_arc(centre, breath_radius, BREATH_WIDTH, breath_ratio, breath_color)
	# Hour ticks inside the arcs, and the gnomon.
	var inner: float = breath_radius - BREATH_WIDTH * 0.5 - 3.0
	for index: int in TICKS:
		var angle: float = PI + PI * index / (TICKS - 1)
		var direction: Vector2 = Vector2(cos(angle), sin(angle))
		draw_line((centre + direction * (inner - 5.0)).round(), (centre + direction * inner).round(), UiStyle.WARM_DARK, 2.0, false)
	draw_colored_polygon(PackedVector2Array([centre + Vector2(-5.0, 0.0), centre + Vector2(5.0, 0.0), centre + Vector2(0.0, -16.0)]), UiStyle.WARM_DARK)
	draw_line(centre + Vector2(-RADIUS - 3.0, 1.0), centre + Vector2(RADIUS + 3.0, 1.0), UiStyle.OUTLINE, 3.0, false)


func _half_disc(centre: Vector2, radius: float) -> PackedVector2Array:
	var points: PackedVector2Array = []
	for index: int in 33:
		var angle: float = PI + PI * index / 32.0
		points.append((centre + Vector2(cos(angle), sin(angle)) * radius).round())
	return points


## Upper half arc from the left (share 0) to the right (share 1).
func _arc(centre: Vector2, radius: float, width: float, share: float, color: Color) -> void:
	if share <= 0.0:
		return
	var points: int = maxi(2, int(40.0 * share))
	draw_arc(centre, radius, PI, PI + PI * share, points, color, width, false)
