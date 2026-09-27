class_name ProtoSettings
extends RefCounted
## Tunable values of the visual prototype (phase 1), saved as JSON.
## Camera (50), sprite size (49), light (48), depth of field (47).

# Camera (50)
var camera_pitch: float = 50.0
var camera_distance: float = 16.0
var camera_fov: float = 35.0
var camera_orthographic: bool = false
# Depth of field (47): offsets are measured from the focus point.
var dof_near_offset: float = 6.0
var dof_far_offset: float = 8.0
var dof_amount: float = 0.1
# Sprites (49)
var sprite_pixel_size: float = 0.038
var sprite_billboard_fixed_y: bool = true
var sprite_shaded: bool = false
var world_texels_per_meter: float = 26.0
# Light (48)
var sun_elevation: float = 14.0
var sun_azimuth: float = 225.0
var sun_color: Color = Color(1.0, 0.72, 0.45)
var sun_energy: float = 2.0
var fog_density: float = 0.008
# Where Ottavia starts; used to repeat screenshots from the same spot.
var player_position: Vector3 = Vector3(0.0, 0.0, 6.0)

const _COLOR_KEYS: Array[String] = ["sun_color"]
const _VECTOR_KEYS: Array[String] = ["player_position"]


func to_dict() -> Dictionary:
	var result: Dictionary = {}
	for key: String in _keys():
		var value: Variant = get(key)
		if value is Color:
			var color: Color = value
			result[key] = color.to_html(false)
		elif value is Vector3:
			var vector: Vector3 = value
			result[key] = [vector.x, vector.y, vector.z]
		else:
			result[key] = value
	return result


func apply_dict(data: Dictionary) -> void:
	for key: String in _keys():
		if not data.has(key):
			continue
		var value: Variant = data[key]
		if key in _COLOR_KEYS:
			set(key, Color.html(str(value)))
		elif key in _VECTOR_KEYS:
			var parts: Array = value
			set(key, Vector3(float(parts[0]), float(parts[1]), float(parts[2])))
		elif get(key) is bool:
			set(key, bool(value))
		else:
			set(key, float(value))


func save_json(path: String) -> Error:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(to_dict(), "\t"))
	return OK


func load_json(path: String) -> Error:
	if not FileAccess.file_exists(path):
		return ERR_FILE_NOT_FOUND
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return ERR_PARSE_ERROR
	apply_dict(parsed)
	return OK


func _keys() -> PackedStringArray:
	var keys: PackedStringArray = []
	for property: Dictionary in get_property_list():
		if property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			keys.append(property["name"])
	return keys
