extends SceneTree
## Headless test runner.
## Usage: godot --headless --path . --script res://tests/run_tests.gd
## Exits with code 0 when every check passes, 1 otherwise.

const GAME_ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"move_up", &"move_down", &"toggle_tuning_panel", &"interact", &"attack", &"hook", &"jump", &"run", &"parry", &"lantern", &"call", &"warm_stone", &"open_options"]
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
	_test_zone_light()
	_test_controls()
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


## Controls (67, 96): every action within reach of the left hand on WASD,
## strike and parry on the mouse buttons, jump on the space bar, run on
## Shift; bindings
## can be changed and reset.
func _test_controls() -> void:
	var left_hand: Array[Key] = [KEY_Q, KEY_E, KEY_R, KEY_F, KEY_C, KEY_SPACE, KEY_SHIFT, KEY_ESCAPE, KEY_W, KEY_A, KEY_S, KEY_D]
	for action: StringName in [&"hook", &"jump", &"run", &"lantern", &"call", &"interact", &"warm_stone", &"open_options"]:
		var event: InputEvent = InputRemap.main_event(action, InputRemap.Device.KEYBOARD)
		_check(event is InputEventKey and (event as InputEventKey).physical_keycode in left_hand, "controls: %s under the left hand" % action)
	var attack: InputEvent = InputRemap.main_event(&"attack", InputRemap.Device.KEYBOARD)
	var parry: InputEvent = InputRemap.main_event(&"parry", InputRemap.Device.KEYBOARD)
	var jump: InputEvent = InputRemap.main_event(&"jump", InputRemap.Device.KEYBOARD)
	var run: InputEvent = InputRemap.main_event(&"run", InputRemap.Device.KEYBOARD)
	var run_pad: InputEvent = InputRemap.main_event(&"run", InputRemap.Device.GAMEPAD)
	var jump_pad: InputEvent = InputRemap.main_event(&"jump", InputRemap.Device.GAMEPAD)
	_check(attack is InputEventMouseButton and (attack as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT, "controls: strike on the left mouse button")
	_check(parry is InputEventMouseButton and (parry as InputEventMouseButton).button_index == MOUSE_BUTTON_RIGHT, "controls: parry on the right mouse button")
	_check(jump is InputEventKey and (jump as InputEventKey).physical_keycode == KEY_SPACE, "controls: jump on the space bar")
	_check(run is InputEventKey and (run as InputEventKey).physical_keycode == KEY_SHIFT, "controls: run on Shift")
	_check(jump_pad is InputEventJoypadButton and (jump_pad as InputEventJoypadButton).button_index == JOY_BUTTON_B, "controls: jump on pad B")
	_check(run_pad is InputEventJoypadButton and (run_pad as InputEventJoypadButton).button_index == JOY_BUTTON_LEFT_STICK, "controls: run on L3")
	var key: InputEventKey = InputEventKey.new()
	key.physical_keycode = KEY_G
	InputRemap.rebind(&"attack", key)
	var rebound: InputEvent = InputRemap.main_event(&"attack", InputRemap.Device.KEYBOARD)
	_check(rebound is InputEventKey and (rebound as InputEventKey).physical_keycode == KEY_G, "controls: strike can be rebound")
	_check(InputRemap.main_event(&"attack", InputRemap.Device.GAMEPAD) != null, "controls: rebinding the keyboard keeps the gamepad binding")
	InputRemap.reset_controls()
	var reset: InputEvent = InputRemap.main_event(&"attack", InputRemap.Device.KEYBOARD)
	_check(reset is InputEventMouseButton, "controls: reset restores the defaults")


## Zone light (51): unchanged in the Twilight, colder, weaker and lower toward
## the Night, whiter and higher toward the Day.
func _test_zone_light() -> void:
	var base: Color = Color(0.5, 0.45, 0.85)
	_check(ZonePalette.sun_tint(0.0).is_equal_approx(Color.WHITE), "zone light: Twilight keeps the sun color")
	_check(is_equal_approx(ZonePalette.sun_energy_scale(0.0), 1.0) and is_equal_approx(ZonePalette.sun_elevation_scale(0.0), 1.0), "zone light: Twilight keeps sun energy and height")
	_check(ZonePalette.ambient_color(base, 0.0).is_equal_approx(base), "zone light: Twilight keeps the sky light")
	var night: Color = ZonePalette.sun_tint(1.0)
	_check(night.b > night.r and ZonePalette.sun_energy_scale(1.0) < 1.0 and ZonePalette.sun_elevation_scale(1.0) < 1.0, "zone light: Night sun colder, weaker, lower")
	_check(ZonePalette.ambient_color(base, 1.0).b / ZonePalette.ambient_color(base, 1.0).r > base.b / base.r, "zone light: Night sky light bluer")
	var day: Color = ZonePalette.sun_tint(-1.0)
	_check(day.b > 1.0 and ZonePalette.sun_elevation_scale(-1.0) > 1.0, "zone light: Day sun whiter and higher")
	_check(is_equal_approx(ZonePalette.sun_energy_scale(3.0), ZonePalette.sun_energy_scale(1.0)), "zone light: values past the edges clamp")


## Lantern of Ottavia (19): one lantern point per frame, near the top of the
## staff, and a light offset at about the height of the drawn lantern.
func _test_lantern() -> void:
	var data: JSON = load("res://assets/sprites/ottavia/ottavia_v2_sheet.json")
	var points: PackedVector2Array = OttaviaProto.lantern_points_from(data.data)
	var rows: int = int(data.data["meta"]["rows"])
	_check(points.size() == rows * OttaviaProto.COLUMNS, "lantern: one point per cell (got %d)" % points.size())
	var idle: Dictionary = data.data["animations"]["idle_s"]
	var inside: bool = true
	for row: int in 16:
		for column: int in 8:
			var point: Vector2 = points[row * OttaviaProto.COLUMNS + column]
			inside = inside and point.x > 4.0 and point.x < 60.0 and point.y > 4.0 and point.y < 20.0
	_check(inside, "lantern: idle and walk points sit near the top of the staff")
	var offset: Vector3 = OttaviaProto.lantern_offset(points[int(idle["row"]) * OttaviaProto.COLUMNS], WorldScale.METERS_PER_PIXEL, 29.0, Vector3.RIGHT)
	_check(offset.y > 1.4 and offset.y < 1.8 and offset.x < 0.0, "lantern: idle_s light at the drawn lantern (got %s)" % offset)
	var names: Array = data.data["animations"].keys()
	var complete: bool = true
	for anim: String in ["idle", "walk", "run", "jump", "climb", "combo", "parry", "hurt", "breathless"]:
		for suffix: String in ["s", "se", "e", "ne", "n", "nw", "w", "sw"]:
			complete = complete and names.has("%s_%s" % [anim, suffix])
	_check(complete and names.has("tie_rope_s") and names.has("give_hand_w"), "sheet: every animation of phase 4a in its directions (19)")
	var mask: Texture2D = load("res://assets/sprites/ottavia/ottavia_v2_emission.png")
	var sheet: Texture2D = load("res://assets/sprites/ottavia/ottavia_v2_sheet.png")
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
