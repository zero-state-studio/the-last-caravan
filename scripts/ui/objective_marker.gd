class_name ObjectiveMarker
extends Node3D
## Where to go next (106): a warm glow on the ground at the goal and, when
## the goal is off screen, a small arrow on the screen edge pointing to it.
## The goal in words shows above the hint (HintBanner.show_goal).

const GLOW_COLOR: Color = Color(1.0, 0.74, 0.38)
const GLOW_METERS: float = 1.8
const PULSE_HZ: float = 0.8
const EDGE_MARGIN: float = 44.0
const ARROW_SIZE: float = 16.0

var _target_node: Node3D
var _target_offset: Vector3 = Vector3.ZERO
var _target_point: Vector3
var _active: bool = false
var _time: float = 0.0
var _light: OmniLight3D
var _glow: Sprite3D
var _layer: CanvasLayer
var _arrow: Control
var _arrow_angle: float = 0.0


func _ready() -> void:
	_light = OmniLight3D.new()
	_light.light_color = GLOW_COLOR
	_light.omni_range = 4.0
	_light.shadow_enabled = false
	add_child(_light)
	_glow = Sprite3D.new()
	_glow.texture = _glow_texture()
	_glow.pixel_size = GLOW_METERS / 64.0
	_glow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_glow.shaded = false
	_glow.transparent = true
	_glow.no_depth_test = false
	_glow.modulate = GLOW_COLOR
	_glow.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_glow.position = Vector3.UP * 0.35
	add_child(_glow)
	_layer = CanvasLayer.new()
	_layer.layer = 7
	add_child(_layer)
	_arrow = Control.new()
	_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arrow.size = Vector2(ARROW_SIZE * 3.0, ARROW_SIZE * 3.0)
	_arrow.draw.connect(_draw_arrow)
	_layer.add_child(_arrow)
	clear()


## Guides to a node (it may move, like Mirco or the column).
func point_to_node(target: Node3D, offset: Vector3 = Vector3.ZERO) -> void:
	_target_node = target
	_target_offset = offset
	_active = true
	visible = true


func point_to(point: Vector3) -> void:
	_target_node = null
	_target_point = point
	_active = true
	visible = true


func clear() -> void:
	_active = false
	_target_node = null
	visible = false
	if _arrow != null:
		_arrow.visible = false


func is_active() -> bool:
	return _active


func target_position() -> Vector3:
	if _target_node != null and is_instance_valid(_target_node):
		return _target_node.global_position + _target_offset
	return _target_point


func arrow_showing() -> bool:
	return _arrow.visible


func _process(delta: float) -> void:
	if not _active:
		return
	_time += delta
	global_position = target_position()
	var pulse: float = 0.5 + 0.5 * sin(_time * TAU * PULSE_HZ)
	_light.light_energy = 0.8 + 0.8 * pulse
	_glow.modulate.a = 0.35 + 0.35 * pulse
	_update_arrow(pulse)


func _update_arrow(pulse: float) -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		_arrow.visible = false
		return
	var view: Vector2 = get_viewport().get_visible_rect().size
	var point: Vector3 = global_position + Vector3.UP * 0.5
	var behind: bool = camera.is_position_behind(point)
	var screen: Vector2 = camera.unproject_position(point)
	if behind:
		screen = view - screen
	var inside: Rect2 = Rect2(Vector2.ONE * EDGE_MARGIN, view - Vector2.ONE * EDGE_MARGIN * 2.0)
	if not behind and inside.has_point(screen):
		_arrow.visible = false
		return
	var centre: Vector2 = view * 0.5
	var direction: Vector2 = (screen - centre).normalized()
	# Onto the edge of the inner rectangle, along the direction to the goal.
	var half: Vector2 = view * 0.5 - Vector2.ONE * EDGE_MARGIN
	var scale_to_edge: float = minf(absf(half.x / direction.x) if absf(direction.x) > 0.001 else INF, absf(half.y / direction.y) if absf(direction.y) > 0.001 else INF)
	var at: Vector2 = centre + direction * scale_to_edge
	_arrow_angle = direction.angle()
	_arrow.position = (at - _arrow.size * 0.5).round()
	_arrow.modulate.a = 0.7 + 0.3 * pulse
	_arrow.visible = true
	_arrow.queue_redraw()


func _draw_arrow() -> void:
	var centre: Vector2 = _arrow.size * 0.5
	var tip: Vector2 = Vector2.RIGHT.rotated(_arrow_angle) * ARROW_SIZE
	var side: Vector2 = Vector2.RIGHT.rotated(_arrow_angle + PI * 0.5) * ARROW_SIZE * 0.7
	var back: Vector2 = -tip * 0.6
	var points: PackedVector2Array = PackedVector2Array([centre + tip, centre + back + side, centre + back - side])
	var outline: PackedVector2Array = PackedVector2Array()
	for point: Vector2 in points:
		outline.append(centre + (point - centre) * 1.3)
	_arrow.draw_colored_polygon(outline, UiStyle.OUTLINE)
	_arrow.draw_colored_polygon(points, GLOW_COLOR)


static func _glow_texture() -> Texture2D:
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	texture.width = 64
	texture.height = 64
	return texture
