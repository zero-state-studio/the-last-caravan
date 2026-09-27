class_name CombatEffects
extends RefCounted
## Provisional combat effects (phase 3, until the real animations): a pixel
## arc for swings, a small spark on impact. Drawn at the world density (49)
## with the nearest filter; the arc lies flat at chest height.

const SWING_SECONDS: float = 0.14
const SPARK_SECONDS: float = 0.1
const ARC_THICKNESS_PIXELS: int = 7

static var _arc_textures: Dictionary = {}
static var _spark_texture: ImageTexture


## A flat arc of `arc_degrees` around `direction`, `reach` meters long.
static func swing(parent: Node, origin: Vector3, direction: Vector3, reach: float, arc_degrees: float, color: Color) -> void:
	var flat: Vector3 = Vector3(direction.x, 0.0, direction.z)
	if flat.length_squared() < 0.0001:
		return
	flat = flat.normalized()
	var radius_pixels: int = maxi(8, roundi(reach * WorldScale.PIXELS_PER_METER))
	var mesh: PlaneMesh = PlaneMesh.new()
	mesh.size = Vector2(reach * 2.0, reach)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_texture = _arc_texture(radius_pixels, arc_degrees)
	material.albedo_color = color
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)
	# PlaneMesh: v = 0 at local -Z. The arc is drawn around the top-center
	# of the image with its center at the bottom edge, so local -Z = forward.
	var center: Vector3 = origin + flat * reach * 0.5
	instance.global_transform = Transform3D(Basis.looking_at(flat, Vector3.UP), center)
	_fade_and_free(instance, material, SWING_SECONDS)


## A flat ring on the ground marking where an attack will land (telegraph),
## drawn above the grass so it stays readable in dense vegetation.
static func ground_ring(parent: Node, center: Vector3, radius: float, color: Color, seconds: float) -> void:
	var radius_pixels: int = maxi(6, roundi(radius * WorldScale.PIXELS_PER_METER))
	var mesh: PlaneMesh = PlaneMesh.new()
	mesh.size = Vector2(radius * 2.0, radius * 2.0)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.no_depth_test = true
	material.albedo_texture = _ring_texture(radius_pixels)
	material.albedo_color = color
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)
	instance.global_position = center + Vector3.UP * 0.05
	var tween: Tween = instance.create_tween()
	tween.tween_property(material, "albedo_color:a", color.a * 0.35, seconds * 0.5).from(color.a * 0.35)
	tween.tween_property(material, "albedo_color:a", color.a, seconds * 0.5)
	tween.tween_callback(instance.queue_free)


static func _ring_texture(radius: int) -> ImageTexture:
	var key: String = "ring_%d" % radius
	if _arc_textures.has(key):
		return _arc_textures[key]
	var image: Image = Image.create(radius * 2, radius * 2, false, Image.FORMAT_RGBA8)
	for y: int in radius * 2:
		for x: int in radius * 2:
			var distance: float = Vector2(x + 0.5 - radius, y + 0.5 - radius).length()
			if distance <= radius and distance >= radius - 2.0:
				image.set_pixel(x, y, Color.WHITE)
			elif distance < radius - 2.0 and (x + y) % 4 == 0:
				image.set_pixel(x, y, Color(1.0, 1.0, 1.0, 0.35))
	var texture: ImageTexture = ImageTexture.create_from_image(image)
	_arc_textures[key] = texture
	return texture


## A tiny star that faces the camera at `point`.
static func spark(parent: Node, point: Vector3, color: Color, size_pixels: float = 9.0) -> void:
	var sprite: Sprite3D = Sprite3D.new()
	sprite.texture = _spark()
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded = false
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.pixel_size = WorldScale.METERS_PER_PIXEL * size_pixels / 9.0
	sprite.modulate = color
	sprite.no_depth_test = true
	parent.add_child(sprite)
	sprite.global_position = point
	var tween: Tween = sprite.create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, SPARK_SECONDS)
	tween.tween_callback(sprite.queue_free)


## Drops the cached textures (call when the level closes, so no resource is
## left alive at exit).
static func clear_cache() -> void:
	_arc_textures.clear()
	_spark_texture = null


static func _fade_and_free(instance: MeshInstance3D, material: StandardMaterial3D, seconds: float) -> void:
	var tween: Tween = instance.create_tween()
	tween.tween_property(material, "albedo_color:a", 0.0, seconds)
	tween.tween_callback(instance.queue_free)


static func _arc_texture(radius: int, arc_degrees: float) -> ImageTexture:
	var key: String = "%d_%d" % [radius, roundi(arc_degrees)]
	if _arc_textures.has(key):
		return _arc_textures[key]
	var image: Image = Image.create(radius * 2, radius, false, Image.FORMAT_RGBA8)
	var half_arc: float = deg_to_rad(arc_degrees) * 0.5
	for y: int in radius:
		for x: int in radius * 2:
			var offset: Vector2 = Vector2(x + 0.5 - radius, radius - (y + 0.5))
			var distance: float = offset.length()
			var angle: float = absf(atan2(offset.x, offset.y))
			if angle <= half_arc and distance <= radius and distance >= radius - ARC_THICKNESS_PIXELS:
				# Brighter at the leading edge of the swing.
				var alpha: float = 1.0 if distance >= radius - 2.5 else 0.75
				image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	var texture: ImageTexture = ImageTexture.create_from_image(image)
	_arc_textures[key] = texture
	return texture


static func _spark() -> ImageTexture:
	if _spark_texture != null:
		return _spark_texture
	var image: Image = Image.create(9, 9, false, Image.FORMAT_RGBA8)
	for index: int in 9:
		image.set_pixel(4, index, Color.WHITE)
		image.set_pixel(index, 4, Color.WHITE)
	for index: int in [2, 3, 5, 6]:
		image.set_pixel(index, index, Color(1.0, 1.0, 1.0, 0.7))
		image.set_pixel(8 - index, index, Color(1.0, 1.0, 1.0, 0.7))
	_spark_texture = ImageTexture.create_from_image(image)
	return _spark_texture
