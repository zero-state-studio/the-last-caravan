class_name NpcSprite
extends Sprite3D
## A person drawn as a pixel-art sprite (49): feet on the node, world pixel
## density, nearest filter, lit by the scene (so in the dark only the
## lantern shows them), upright billboard toward the camera.

@export var sprite_texture: Texture2D


func _ready() -> void:
	if sprite_texture != null:
		texture = sprite_texture
	pixel_size = WorldScale.METERS_PER_PIXEL
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	shaded = true
	# 64x64 cells keep the feet at row 60, like Ottavia.
	if texture != null:
		offset = Vector2(0.0, texture.get_height() * 0.5 - 3.0)
