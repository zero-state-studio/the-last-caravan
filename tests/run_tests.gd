extends SceneTree
## Headless test runner.
## Usage: godot --headless --path . --script res://tests/run_tests.gd
## Exits with code 0 when every check passes, 1 otherwise.

const GAME_ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"move_up", &"move_down", &"toggle_tuning_panel"]
const LOAD_ROOTS: Array[String] = ["res://scenes", "res://scripts", "res://tests"]
const TEST_KEY: StringName = &"UI_TEST_GREETING"
const EXPECTED_TRANSLATIONS: Dictionary = {
	"en": "The caravan is ready to leave.",
	"it": "La carovana è pronta a partire.",
}

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_test_project_settings()
	_test_input_map()
	_test_translations()
	_test_facing()
	_test_proto_settings()
	_test_zone_palette_models()
	_test_load_all_resources()
	_test_texture_imports()
	_test_lantern()
	print("TESTS: %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("FAIL: " + message)


func _test_project_settings() -> void:
	_check(ProjectSettings.get_setting("display/window/size/viewport_width") == 1280, "viewport width is 1280")
	_check(ProjectSettings.get_setting("display/window/size/viewport_height") == 800, "viewport height is 800")
	_check(ProjectSettings.get_setting("display/window/size/resizable") == true, "window is resizable")
	_check(ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter") == 0, "default canvas texture filter is nearest")
	_check(ProjectSettings.get_setting("rendering/renderer/rendering_method") == "forward_plus", "renderer is Forward+")
	var texel_global: Dictionary = ProjectSettings.get_setting("shader_globals/world_texels_per_meter")
	_check(is_equal_approx(float(texel_global["value"]), WorldScale.PIXELS_PER_METER), "shader global world_texels_per_meter matches WorldScale")
	_check(is_equal_approx(WorldScale.OTTAVIA_BODY_PIXELS / WorldScale.OTTAVIA_HEIGHT_METERS, WorldScale.PIXELS_PER_METER), "WorldScale density matches Ottavia v1")


func _test_input_map() -> void:
	for action: StringName in GAME_ACTIONS:
		_check(InputMap.has_action(action), "input action %s exists" % action)
		if not InputMap.has_action(action):
			continue
		var has_key: bool = false
		var has_pad: bool = false
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventKey:
				has_key = true
			elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
				has_pad = true
		_check(has_key, "%s is mapped to the keyboard" % action)
		_check(has_pad, "%s is mapped to the gamepad" % action)


func _test_translations() -> void:
	var previous_locale: String = TranslationServer.get_locale()
	for locale: String in EXPECTED_TRANSLATIONS:
		TranslationServer.set_locale(locale)
		var text: String = TranslationServer.translate(TEST_KEY)
		_check(text == EXPECTED_TRANSLATIONS[locale], "%s translation of %s (got '%s')" % [locale, TEST_KEY, text])
	TranslationServer.set_locale(previous_locale)


func _test_facing() -> void:
	var cases: Array[Array] = [
		[Vector2(0, 1), Facing.Direction.SOUTH],
		[Vector2(1, 1), Facing.Direction.SOUTH_EAST],
		[Vector2(1, 0), Facing.Direction.EAST],
		[Vector2(1, -1), Facing.Direction.NORTH_EAST],
		[Vector2(0, -1), Facing.Direction.NORTH],
		[Vector2(-1, -1), Facing.Direction.NORTH_WEST],
		[Vector2(-1, 0), Facing.Direction.WEST],
		[Vector2(-1, 1), Facing.Direction.SOUTH_WEST],
		[Vector2(0.9, 0.2), Facing.Direction.EAST],
		[Vector2(0.2, -0.9), Facing.Direction.NORTH],
	]
	for test_case: Array in cases:
		var input: Vector2 = test_case[0]
		var expected: Facing.Direction = test_case[1]
		var got: Facing.Direction = Facing.nearest_direction(input.normalized(), Facing.Direction.SOUTH)
		_check(got == expected, "facing: %s gives %d (got %d)" % [input, expected, got])
	_check(Facing.nearest_direction(Vector2.ZERO, Facing.Direction.WEST) == Facing.Direction.WEST, "facing: no input keeps the view")


func _test_proto_settings() -> void:
	var original: ProtoSettings = ProtoSettings.new()
	original.camera_pitch = 62.5
	original.camera_orthographic = true
	original.sun_color = Color(0.25, 0.5, 0.75)
	original.player_position = Vector3(1, 2, 3)
	var copy: ProtoSettings = ProtoSettings.new()
	copy.apply_dict(JSON.parse_string(JSON.stringify(original.to_dict())))
	_check(is_equal_approx(copy.camera_pitch, 62.5), "settings: float survives JSON")
	_check(copy.camera_orthographic, "settings: bool survives JSON")
	_check(copy.sun_color.is_equal_approx(Color(0.25, 0.5, 0.75)), "settings: color survives JSON")
	_check(copy.player_position.is_equal_approx(Vector3(1, 2, 3)), "settings: vector survives JSON")


func _test_zone_palette_models() -> void:
	var model: Node = (load("res://assets/models/proto/boulder.glb") as PackedScene).instantiate()
	ZonePalette.retint_models(model)
	var converted: int = 0
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var material: ShaderMaterial = (node as MeshInstance3D).get_surface_override_material(0) as ShaderMaterial
		if material != null and material.shader == ZonePalette.MODEL_SHADER and material.get_shader_parameter(&"albedo_texture") != null:
			converted += 1
	_check(converted > 0, "zone palette: imported models get the palette shader with their texture")
	model.free()


func _test_load_all_resources() -> void:
	for root: String in LOAD_ROOTS:
		for path: String in _list_files(root):
			if path.ends_with(".gd"):
				var script: Script = load(path) as Script
				_check(script != null and script.can_instantiate(), "script loads and compiles: " + path)
			elif path.ends_with(".tscn"):
				var packed: PackedScene = load(path) as PackedScene
				_check(packed != null, "scene loads: " + path)
				if packed != null:
					var instance: Node = packed.instantiate()
					_check(instance != null, "scene instantiates: " + path)
					if instance != null:
						instance.free()


## Lantern of Ottavia (19): one lantern point per frame, near the top of the
## staff, and a light offset at about the height of the drawn lantern.
func _test_lantern() -> void:
	var data: JSON = load("res://assets/sprites/ottavia/ottavia_v1_sheet.json")
	var points: PackedVector2Array = OttaviaProto.lantern_points_from(data.data)
	_check(points.size() == 128, "lantern: one point per frame (got %d)" % points.size())
	var inside: bool = true
	for point: Vector2 in points:
		inside = inside and point.x > 4.0 and point.x < 60.0 and point.y > 4.0 and point.y < 20.0
	_check(inside, "lantern: every point sits near the top of the staff")
	var offset: Vector3 = OttaviaProto.lantern_offset(points[0], WorldScale.METERS_PER_PIXEL, 29.0, Vector3.RIGHT)
	_check(offset.y > 1.4 and offset.y < 1.8 and offset.x < 0.0, "lantern: idle_s light at the drawn lantern (got %s)" % offset)
	var mask: Texture2D = load("res://assets/sprites/ottavia/ottavia_v1_emission.png")
	var sheet: Texture2D = load("res://assets/sprites/ottavia/ottavia_v1_sheet.png")
	_check(mask.get_size() == sheet.get_size(), "lantern: emission mask matches the sheet size")


## Pixel-art textures never get mipmaps, also the ones extracted from GLB models.
func _test_texture_imports() -> void:
	var mipmapped: PackedStringArray = []
	for path: String in _list_files("res://assets"):
		if path.ends_with(".png.import") and FileAccess.get_file_as_string(path).contains("mipmaps/generate=true"):
			mipmapped.append(path)
	_check(mipmapped.is_empty(), "no texture in assets/ generates mipmaps %s" % [mipmapped])


func _list_files(dir_path: String) -> PackedStringArray:
	var result: PackedStringArray = []
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return result
	for file_name: String in dir.get_files():
		result.append(dir_path.path_join(file_name))
	for sub_dir: String in dir.get_directories():
		result.append_array(_list_files(dir_path.path_join(sub_dir)))
	return result
