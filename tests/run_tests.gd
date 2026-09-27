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
	_test_load_all_resources()
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
	var south: Facing.Cardinal = Facing.Cardinal.SOUTH
	var north: Facing.Cardinal = Facing.Cardinal.NORTH
	var east: Facing.Cardinal = Facing.Cardinal.EAST
	var west: Facing.Cardinal = Facing.Cardinal.WEST
	_check(Facing.nearest_cardinal(Vector2.ZERO, north) == north, "facing: no input keeps the view")
	_check(Facing.nearest_cardinal(Vector2(0, 1), north) == south, "facing: down is south")
	_check(Facing.nearest_cardinal(Vector2(0, -1), south) == north, "facing: up is north")
	_check(Facing.nearest_cardinal(Vector2(1, 0), south) == east, "facing: right is east")
	_check(Facing.nearest_cardinal(Vector2(-1, 0), south) == west, "facing: left is west")
	_check(Facing.nearest_cardinal(Vector2(0.9, 0.3), north) == east, "facing: mostly right is east")
	_check(Facing.nearest_cardinal(Vector2(0.3, -0.9), east) == north, "facing: mostly up is north")
	var diagonal: Vector2 = Vector2(1, 1).normalized()
	_check(Facing.nearest_cardinal(diagonal, south) == south, "facing: diagonal keeps a matching view")
	_check(Facing.nearest_cardinal(diagonal, east) == east, "facing: diagonal keeps the other matching view")
	_check(Facing.nearest_cardinal(diagonal, north) == east, "facing: diagonal from a non-matching view picks east/west")


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
