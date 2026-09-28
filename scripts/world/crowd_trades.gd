class_name CrowdTrades
extends RefCounted
## Trade colours of the generic crowd (121): the dark and light ends of the
## ramp the clothes are dyed along; the front is sun-faded on top (98).

const TRADES: Dictionary = {
	&"brinaioli": {"dark": Color(0.30, 0.08, 0.05), "light": Color(0.80, 0.36, 0.20)},
	&"tessibuio": {"dark": Color(0.10, 0.06, 0.10), "light": Color(0.37, 0.25, 0.32)},
	&"voltacampi": {"dark": Color(0.24, 0.27, 0.11), "light": Color(0.82, 0.74, 0.42)},
	&"traslocanti": {"dark": Color(0.14, 0.17, 0.22), "light": Color(0.48, 0.53, 0.58)},
	&"specchianti": {"dark": Color(0.56, 0.58, 0.64), "light": Color(0.97, 0.97, 0.98)},
	&"nodai": {"dark": Color(0.42, 0.33, 0.22), "light": Color(0.86, 0.78, 0.60)},
}
## How much the dye covers the drawn cloth, and how faded the front is.
const STRENGTH: float = 0.9
const FRONT_FADE: float = 0.25


static func names() -> Array[StringName]:
	var list: Array[StringName] = []
	for trade: StringName in TRADES:
		list.append(trade)
	return list


## The garment mask drawn for a crowd sprite, next to it (tools/crowd_garment_masks.py).
static func mask_for(texture: Texture2D) -> Texture2D:
	if texture == null or texture.resource_path.is_empty():
		return null
	var path: String = texture.resource_path.get_basename() + "_mask.png"
	return load(path) if ResourceLoader.exists(path) else null
