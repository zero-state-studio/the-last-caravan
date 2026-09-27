extends SceneTree
## Opens a scene, waits a number of frames, saves a PNG screenshot and quits.
## Usage: godot --path . --script res://scripts/dev/screenshot_runner.gd -- <scene> <output.png> [frames]
## Prefer the wrapper tools/screenshot.sh.

const DEFAULT_FRAMES: int = 30

var _output_path: String = ""
var _frames_left: int = DEFAULT_FRAMES


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 2:
		printerr("screenshot_runner: expected <scene> <output.png> [frames]")
		quit(2)
		return
	var scene_path: String = args[0]
	_output_path = args[1]
	if args.size() >= 3:
		_frames_left = maxi(1, args[2].to_int())
	var error: Error = change_scene_to_file(scene_path)
	if error != OK:
		printerr("screenshot_runner: cannot open scene %s (error %d)" % [scene_path, error])
		quit(3)


func _process(_delta: float) -> bool:
	if _output_path.is_empty():
		return false
	_frames_left -= 1
	if _frames_left > 0:
		return false
	var image: Image = root.get_texture().get_image()
	var error: Error = image.save_png(_output_path)
	if error != OK:
		printerr("screenshot_runner: cannot save %s (error %d)" % [_output_path, error])
		quit(4)
	else:
		print("screenshot_runner: saved %s (%dx%d)" % [_output_path, image.get_width(), image.get_height()])
		quit(0)
	return true
