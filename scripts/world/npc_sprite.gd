class_name NpcSprite
extends Sprite3D
## A person drawn as a pixel-art sprite (49), drawn exactly like Ottavia so
## proportions match: the lit billboard shader of the diorama (full
## billboard toward the camera, depth of an upright quad), world pixel
## density, feet on the node. The scene lights it, so in the dark only the
## lantern shows it. An invisible upright copy turned toward the sun casts
## the shadow (as Ottavia's ShadowProxy).

const LIT_SHADER: Shader = preload("res://scenes/proto/materials/sprite_billboard_lit.gdshader")
const LIGHT_SAMPLE_HEIGHT: float = 0.9
const LIGHT_SAMPLE_TOWARD_SUN: float = 0.4

## Sun of the current scene, set by the level before adding people;
## NAN when there is no sun (interiors): no shadow copy then.
static var sun_azimuth_degrees: float = NAN

@export var sprite_texture: Texture2D
## Frames laid side by side in the texture (a looping idle, 64 px each).
@export var frame_count: int = 1
@export var frames_per_second: float = 6.0

var _time: float = 0.0


func _ready() -> void:
	if sprite_texture != null:
		texture = sprite_texture
	hframes = maxi(1, frame_count)
	pixel_size = WorldScale.METERS_PER_PIXEL
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	billboard = BaseMaterial3D.BILLBOARD_DISABLED
	alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	# 64x64 cells keep the feet at row 60, like Ottavia.
	if texture != null:
		offset = Vector2(0.0, texture.get_height() * 0.5 - 3.0)
	set_process(frame_count > 1)
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = LIT_SHADER
	material.set_shader_parameter(&"sprite_texture", texture)
	material.set_shader_parameter(&"full_billboard", true)
	material.set_shader_parameter(&"upright_depth", true)
	material_override = material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if is_nan(sun_azimuth_degrees):
		material.set_shader_parameter(&"light_sample_offset", Vector3.UP * LIGHT_SAMPLE_HEIGHT)
		return
	var azimuth: float = deg_to_rad(sun_azimuth_degrees)
	var toward_sun: Vector3 = Vector3(sin(azimuth), 0.0, cos(azimuth))
	material.set_shader_parameter(&"light_sample_offset", Vector3.UP * LIGHT_SAMPLE_HEIGHT + toward_sun * LIGHT_SAMPLE_TOWARD_SUN)
	var shadow: Sprite3D = Sprite3D.new()
	shadow.texture = texture
	shadow.hframes = hframes
	shadow.pixel_size = pixel_size
	shadow.offset = offset
	shadow.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	shadow.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	add_child(shadow)
	shadow.global_rotation = Vector3(0.0, azimuth, 0.0)


func _process(delta: float) -> void:
	_time += delta
	frame = int(_time * frames_per_second) % frame_count
	for child: Node in get_children():
		if child is Sprite3D:
			(child as Sprite3D).frame = frame
