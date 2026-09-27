@tool
class_name GrassPatch
extends MultiMeshInstance3D
## A patch of crossed-plane grass tufts drawn with one MultiMesh (101).
## Tufts keep the drawn lean toward the Day (west, 100): random turns stay
## within +-max_yaw_degrees around the vertical axis.

const CARD_SHADER: Shader = preload("res://scenes/proto/materials/foreground_fade.gdshader")
## Fraction of the radius where tufts start to thin out toward the rim.
const EDGE_FADE_START: float = 0.55

@export var texture: Texture2D:
	set(value):
		texture = value
		_rebuild()
@export var count: int = 40:
	set(value):
		count = value
		_rebuild()
## Radii of the ellipse the tufts are spread in, in meters (x, z).
@export var extents: Vector2 = Vector2(2.0, 2.0):
	set(value):
		extents = value
		_rebuild()
@export var max_yaw_degrees: float = 20.0:
	set(value):
		max_yaw_degrees = value
		_rebuild()
@export var scale_range: Vector2 = Vector2(0.8, 1.2):
	set(value):
		scale_range = value
		_rebuild()
@export var random_seed: int = 1:
	set(value):
		random_seed = value
		_rebuild()


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if texture == null:
		return
	var size: Vector2 = Vector2(texture.get_width(), texture.get_height()) * WorldScale.METERS_PER_PIXEL
	var tufts: MultiMesh = MultiMesh.new()
	tufts.transform_format = MultiMesh.TRANSFORM_3D
	tufts.mesh = GrassCardMesh.build(size)
	tufts.instance_count = count
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = random_seed
	for index: int in count:
		var yaw: float = deg_to_rad(random.randf_range(-max_yaw_degrees, max_yaw_degrees))
		var tuft_scale: float = random.randf_range(scale_range.x, scale_range.y)
		var basis: Basis = Basis(Vector3.UP, yaw).scaled(Vector3.ONE * tuft_scale)
		var spot: Vector2 = _random_spot(random)
		var origin: Vector3 = Vector3(spot.x * extents.x, 0.0, spot.y * extents.y)
		tufts.set_instance_transform(index, Transform3D(basis, origin))
	multimesh = tufts
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = CARD_SHADER
	material.set_shader_parameter(&"albedo_texture", texture)
	material_override = material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## A point in the unit disk, thinning out toward the rim so the patch has a
## soft, irregular edge instead of a rectangle.
func _random_spot(random: RandomNumberGenerator) -> Vector2:
	while true:
		var spot: Vector2 = Vector2(random.randf_range(-1.0, 1.0), random.randf_range(-1.0, 1.0))
		var radius: float = spot.length()
		if radius <= 1.0 and random.randf() > smoothstep(EDGE_FADE_START, 1.0, radius):
			return spot
	return Vector2.ZERO
