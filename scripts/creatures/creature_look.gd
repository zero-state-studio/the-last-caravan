class_name CreatureLook
extends RefCounted
## The animated look of a creature (phase 4b step 4): horizontal strips of
## 64 x 64 cells with the feet on row 60 (tools/strip_from_zip.py), one per
## animation and direction, in `folder`/<animation>_<dir>.png with dir in
## s, se, e, ne, n. Symmetric creatures are drawn in these five directions;
## the other three are the mirror of se, e, ne (36).

const CELL: int = 64
const FEET_ROW: int = 60
const DRAWN: Array[String] = ["s", "se", "e", "ne", "n"]
## Eight views clockwise from south, as Facing numbers them; the mirrored
## ones read from their eastern twin.
const VIEWS: Array[String] = ["s", "se", "e", "ne", "n", "nw", "w", "sw"]
const MIRROR: Dictionary = {"w": "e", "sw": "se", "nw": "ne"}

var strips: Dictionary = {}
var fps: Dictionary = {}
var current: String = ""
var _time: float = 0.0

static var _cache: Dictionary = {}


## Loads every strip found in `folder`; `rates` gives frames per second by
## animation (default 8).
static func load_from(folder: String, rates: Dictionary = {}) -> CreatureLook:
	var look: CreatureLook = CreatureLook.new()
	look.fps = rates
	if _cache.has(folder):
		look.strips = _cache[folder]
		return look
	var directory: DirAccess = DirAccess.open(folder)
	if directory == null:
		return look
	# In an exported game the folder lists only "<strip>.png.import" (the
	# source PNG stays out of the pack): read the names from either.
	for listed: String in directory.get_files():
		var file: String = listed.trim_suffix(".remap").trim_suffix(".import")
		if not file.ends_with(".png"):
			continue
		var stem: String = file.get_basename()
		var cut: int = stem.rfind("_")
		if cut < 0:
			continue
		var animation: String = stem.substr(0, cut)
		var view: String = stem.substr(cut + 1)
		if not look.strips.has(animation):
			look.strips[animation] = {}
		if (look.strips[animation] as Dictionary).has(view):
			continue
		look.strips[animation][view] = load(folder.path_join(file))
	_cache[folder] = look.strips
	return look


func has_animation(animation: String) -> bool:
	return strips.has(animation)


## Pixel offset that puts the feet (row 60 of the cell) on the node.
static func feet_offset() -> float:
	return FEET_ROW - CELL * 0.5


## Shows `animation` facing `direction` on `sprite` (and its shader
## `material`), advancing by `delta`; `loop` false holds the last frame.
func show(sprite: Sprite3D, material: ShaderMaterial, animation: String, direction: Vector3, delta: float, loop: bool = true) -> void:
	if not strips.has(animation):
		return
	if animation != current:
		current = animation
		_time = 0.0
	_time += delta
	var view: String = VIEWS[Facing.nearest_direction(Vector2(direction.x, direction.z), Facing.Direction.SOUTH)]
	var mirrored: bool = MIRROR.has(view)
	var source: String = MIRROR.get(view, view)
	var by_view: Dictionary = strips[animation]
	var strip: Texture2D = by_view.get(source, by_view.get("s", null))
	if strip == null:
		return
	var frames: int = maxi(1, strip.get_width() / CELL)
	var frame: int = int(_time * float(fps.get(animation, 8.0)))
	frame = frame % frames if loop else mini(frame, frames - 1)
	if sprite.texture != strip:
		sprite.texture = strip
		sprite.hframes = frames
		if material != null:
			material.set_shader_parameter(&"sprite_texture", strip)
	sprite.frame = frame
	sprite.flip_h = mirrored


## True once a one-shot animation has shown its last frame.
func finished() -> bool:
	if not strips.has(current):
		return true
	var strip: Texture2D = (strips[current] as Dictionary).values()[0]
	var frames: int = maxi(1, strip.get_width() / CELL)
	return _time * float(fps.get(current, 8.0)) >= frames
