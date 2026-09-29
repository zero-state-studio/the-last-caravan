class_name PlaceholderSprite
extends RefCounted
## Provisional look of the chapter 1 creatures and people until the
## PixelLab sprites (phase 4b step 4): a flat silhouette drawn in code at
## the world density (30 px per metre, 49), with a dark outline, a lighter
## top and one eye, on a 64-pixel-wide canvas with the feet on row 60 like
## every character.

const CANVAS: int = 64
const FEET_ROW: int = 60
const OUTLINE: Color = Color(0.08, 0.06, 0.1)

static var _cache: Dictionary = {}


## A body `width` x `height` pixels, of `color`; `shape` is "round" (an
## ellipse), "tall" (a standing figure) or "cloud" (loose dots).
## `cracks` draws that many dark cracks across the body (a shell).
static func texture(width: int, height: int, color: Color, shape: String = "round", cracks: int = 0) -> ImageTexture:
	var key: String = "%d_%d_%s_%s_%d" % [width, height, color.to_html(), shape, cracks]
	if _cache.has(key):
		return _cache[key]
	var canvas_height: int = maxi(CANVAS, height + CANVAS - FEET_ROW + 2)
	var feet: int = canvas_height - (CANVAS - FEET_ROW)
	var image: Image = Image.create(CANVAS, canvas_height, false, Image.FORMAT_RGBA8)
	var left: int = (CANVAS - width) / 2
	var top: int = feet - height
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash(key)
	for y: int in range(top, feet):
		for x: int in range(left, left + width):
			if _inside(x - left, y - top, width, height, shape, rng):
				var shade: float = 1.15 if y < top + height * 0.35 else (0.8 if y > top + height * 0.8 else 1.0)
				image.set_pixel(x, y, Color(color.r * shade, color.g * shade, color.b * shade))
	# Outline: every empty pixel next to a filled one.
	var filled: Image = image.duplicate()
	for y: int in canvas_height:
		for x: int in CANVAS:
			if filled.get_pixel(x, y).a > 0.0:
				continue
			for offset: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var other: Vector2i = Vector2i(x, y) + offset
				if other.x >= 0 and other.y >= 0 and other.x < CANVAS and other.y < canvas_height and filled.get_pixel(other.x, other.y).a > 0.0:
					image.set_pixel(x, y, OUTLINE)
					break
	for crack: int in cracks:
		var x: int = left + width * (crack + 1) / (cracks + 1)
		for y: int in range(top + 2, feet - 1):
			x += rng.randi_range(-1, 1)
			if image.get_pixel(clampi(x, 0, CANVAS - 1), y).a > 0.0:
				image.set_pixel(clampi(x, 0, CANVAS - 1), y, OUTLINE)
	if shape != "cloud":
		var eye: Vector2i = Vector2i(left + maxi(1, width / 4), top + maxi(1, height / 4))
		image.set_pixel(eye.x, eye.y, OUTLINE)
	var result: ImageTexture = ImageTexture.create_from_image(image)
	_cache[key] = result
	return result


## Pixel offset of the sprite so the feet sit on the node (as Ottavia).
static func offset_y(height: int) -> float:
	return feet_offset(height)


static func feet_offset(height: int) -> float:
	var canvas_height: int = maxi(CANVAS, height + CANVAS - FEET_ROW + 2)
	return (canvas_height - (CANVAS - FEET_ROW)) - canvas_height * 0.5


static func _inside(x: int, y: int, width: int, height: int, shape: String, rng: RandomNumberGenerator) -> bool:
	var nx: float = (x + 0.5) / width * 2.0 - 1.0
	var ny: float = (y + 0.5) / height * 2.0 - 1.0
	match shape:
		"tall":
			# Head on a body that widens toward the feet.
			if ny < -0.6:
				return nx * nx + pow((ny + 0.8) / 0.2, 2.0) * 0.25 <= 0.3
			return absf(nx) <= 0.45 + 0.35 * (ny + 0.6) / 1.6
		"cloud":
			return nx * nx + ny * ny <= 1.0 and rng.randf() < 0.45
		_:
			return nx * nx + ny * ny <= 1.0


## Gives a creature built in code (not from a scene) what CombatEnemy
## needs before _ready: a "Sprite3D" child and a collision cylinder.
static func build_body(enemy: CombatEnemy, body_radius: float, body_height: float, look: Texture2D, look_height: int) -> void:
	var shape: CollisionShape3D = CollisionShape3D.new()
	var cylinder: CylinderShape3D = CylinderShape3D.new()
	cylinder.radius = body_radius
	cylinder.height = body_height
	shape.shape = cylinder
	shape.position = Vector3.UP * body_height * 0.5
	enemy.add_child(shape)
	var sprite: Sprite3D = Sprite3D.new()
	sprite.name = "Sprite3D"
	sprite.texture = look
	sprite.pixel_size = WorldScale.METERS_PER_PIXEL
	sprite.offset = Vector2(0.0, feet_offset(look_height))
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	enemy.add_child(sprite)
	enemy.radius = body_radius + 0.05
