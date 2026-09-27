class_name EnemyHealthBar
extends Sprite3D
## Small pixel health bar above a creature, shown once it has been hit, so
## the player knows how much is left. Drawn at the world density (49), with
## the nearest filter; like all interface it never drifts with the palette
## (51). Hidden while the creature cannot be hit (underground, split apart,
## clinging).

const WIDTH_PIXELS: int = 24
const HEIGHT_PIXELS: int = 4
const GAP_METERS: float = 0.15
const FRAME_COLOR: Color = Color(0.118, 0.102, 0.2)
const EMPTY_COLOR: Color = Color(0.2, 0.16, 0.24)
const FILL_COLOR: Color = Color(0.85, 0.36, 0.25)
const HIGHLIGHT_COLOR: Color = Color(0.97, 0.6, 0.4)

var enemy: CombatEnemy
var _shown_pixels: int = -1
var _image: Image
var _texture: ImageTexture


func _init(target: CombatEnemy) -> void:
	enemy = target
	name = "HealthBar"


func _ready() -> void:
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	shaded = false
	no_depth_test = true
	render_priority = 10
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	pixel_size = WorldScale.METERS_PER_PIXEL
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_image = Image.create(WIDTH_PIXELS, HEIGHT_PIXELS, false, Image.FORMAT_RGBA8)
	_texture = ImageTexture.create_from_image(_image)
	texture = _texture
	var sprite: Sprite3D = enemy.sprite
	var top: float = (sprite.texture.get_height() * 0.5 + sprite.offset.y) * sprite.pixel_size if sprite.texture != null else 1.0
	position = Vector3(0.0, top + GAP_METERS, 0.0)
	visible = false


func _process(_delta: float) -> void:
	var hurt: bool = enemy.is_alive() and enemy.health < enemy.max_health
	visible = hurt and enemy.can_be_targeted() and enemy.sprite.visible
	if not visible:
		return
	var inner: int = WIDTH_PIXELS - 2
	var pixels: int = clampi(ceili(inner * enemy.health / maxf(enemy.max_health, 0.01)), 0, inner)
	if pixels != _shown_pixels:
		_shown_pixels = pixels
		_draw(pixels)


func fill_ratio() -> float:
	return float(maxi(_shown_pixels, 0)) / float(WIDTH_PIXELS - 2)


func _draw(pixels: int) -> void:
	_image.fill(FRAME_COLOR)
	for y: int in range(1, HEIGHT_PIXELS - 1):
		for x: int in range(1, WIDTH_PIXELS - 1):
			var filled: bool = x - 1 < pixels
			var color: Color = EMPTY_COLOR
			if filled:
				color = HIGHLIGHT_COLOR if y == 1 else FILL_COLOR
			_image.set_pixel(x, y, color)
	_texture.update(_image)
