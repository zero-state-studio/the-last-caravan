class_name TruceSundial
extends CanvasLayer
## The sundial of the Truce (125, 39): top centre, a small bronze half
## disc. The sun of the Crepuscolo is low on the left, so the shadow of the
## gnomon falls to the right and grows longer as the Truce goes by; the rim
## fills with shade at the same pace. In the last minute the rim pulses;
## stopped (inside a dungeon) the dial dims. Drawn with whole pixels, never
## tinted by the world palette (51).

const RADIUS: float = 34.0
const TOP_MARGIN: float = 18.0
const BRONZE: Color = Color(0.72, 0.5, 0.27)
const BRONZE_LIGHT: Color = Color(0.9, 0.7, 0.42)
const BRONZE_DARK: Color = Color(0.36, 0.22, 0.12)
const SHADOW: Color = Color(0.16, 0.1, 0.16)
const WARNING: Color = Color(1.0, 0.45, 0.25)
const TICKS: int = 7

var clock: TruceClock
var _dial: Control
var _time: float = 0.0


func _ready() -> void:
	layer = 6
	_dial = Control.new()
	_dial.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dial.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_dial.custom_minimum_size = Vector2(RADIUS * 2.0 + 12.0, RADIUS + 12.0)
	_dial.position = Vector2(-_dial.custom_minimum_size.x * 0.5, TOP_MARGIN)
	_dial.draw.connect(_draw_dial)
	add_child(_dial)


func bind(target: TruceClock) -> void:
	clock = target


func _process(delta: float) -> void:
	visible = clock != null and clock.running
	if visible:
		_time += delta
		_dial.queue_redraw()


func _draw_dial() -> void:
	var share: float = clock.share() if clock != null else 0.0
	var centre: Vector2 = Vector2(RADIUS + 6.0, RADIUS + 6.0).round()
	var dim: Color = Color(0.6, 0.6, 0.65) if clock != null and clock.paused else Color.WHITE
	var rim: Color = BRONZE_DARK
	if clock != null and clock.in_warning() and not clock.paused:
		rim = BRONZE_DARK.lerp(WARNING, 0.5 + 0.5 * sin(_time * 6.0))
	_dial.draw_colored_polygon(_half_disc(centre, RADIUS + 3.0), UiStyle.OUTLINE)
	_dial.draw_colored_polygon(_half_disc(centre, RADIUS + 1.0), rim * dim)
	_dial.draw_colored_polygon(_half_disc(centre, RADIUS - 2.0), BRONZE * dim)
	# The rim shade: from the left, the share of the Truce gone.
	if share > 0.0:
		_dial.draw_arc(centre, RADIUS - 3.0, PI, PI + PI * share, maxi(2, int(32.0 * share)), SHADOW * dim, 3.0, false)
	for index: int in TICKS:
		var angle: float = PI + PI * index / (TICKS - 1)
		var direction: Vector2 = Vector2(cos(angle), sin(angle))
		_dial.draw_line((centre + direction * (RADIUS - 11.0)).round(), (centre + direction * (RADIUS - 6.0)).round(), BRONZE_DARK * dim, 2.0, false)
	# The shadow of the gnomon: toward the right, longer and lower with time.
	var shadow_angle: float = lerpf(PI * 1.72, PI * 1.97, share)
	var shadow_length: float = lerpf(RADIUS * 0.35, RADIUS - 8.0, share)
	var tip: Vector2 = (centre + Vector2(cos(shadow_angle), sin(shadow_angle)) * shadow_length).round()
	_dial.draw_colored_polygon(PackedVector2Array([centre + Vector2(-2.0, 0.0), centre + Vector2(2.0, 0.0), tip]), SHADOW * dim)
	# The gnomon: a small upright blade lit from the left.
	_dial.draw_rect(Rect2(centre + Vector2(-2.0, -12.0), Vector2(4.0, 12.0)), BRONZE_DARK * dim)
	_dial.draw_rect(Rect2(centre + Vector2(-2.0, -12.0), Vector2(2.0, 12.0)), BRONZE_LIGHT * dim)
	_dial.draw_line(centre + Vector2(-RADIUS - 3.0, 1.0), centre + Vector2(RADIUS + 3.0, 1.0), UiStyle.OUTLINE, 3.0, false)


func _half_disc(centre: Vector2, radius: float) -> PackedVector2Array:
	var points: PackedVector2Array = []
	for index: int in 33:
		var angle: float = PI + PI * index / 32.0
		points.append((centre + Vector2(cos(angle), sin(angle)) * radius).round())
	return points
