@tool
class_name ForegroundPlant
extends MeshInstance3D
## Flat pixel-art plant that faces the fixed camera and thins out around
## Ottavia when it covers her (53). The quad size follows the texture at the
## shared world pixel size, so plants and terrain have the same grain.

const FADE_SHADER: Shader = preload("res://scenes/proto/materials/foreground_fade.gdshader")

@export var texture: Texture2D:
	set(value):
		texture = value
		_rebuild()
@export var pixel_size: float = 1.0 / 30.0:
	set(value):
		pixel_size = value
		_rebuild()
@export var tint: Color = Color.WHITE:
	set(value):
		tint = value
		_rebuild()


func _ready() -> void:
	add_to_group(&"foreground_plants")
	_rebuild()


func _rebuild() -> void:
	if texture == null:
		return
	var size: Vector2 = Vector2(texture.get_width(), texture.get_height()) * pixel_size
	var quad: QuadMesh = QuadMesh.new()
	quad.size = size
	quad.center_offset = Vector3(0.0, size.y * 0.5, 0.0)
	mesh = quad
	var shader_material: ShaderMaterial = ShaderMaterial.new()
	shader_material.shader = FADE_SHADER
	shader_material.set_shader_parameter(&"albedo_texture", texture)
	shader_material.set_shader_parameter(&"tint", tint)
	material_override = shader_material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
