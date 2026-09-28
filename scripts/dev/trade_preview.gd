extends SceneTree
## Renders the generic crowd (121) in every trade colour: one column per
## generic type, one row per trade (the first row undyed), lit like the
## prologue camp. For judging the dye and the garment masks.
## Usage: godot --path . --resolution 1280x800 --script res://scripts/dev/trade_preview.gd -- <out.png> [view]
##   view: south (default), west, south-west, north-west.

const TYPES: Array[String] = ["uomo_giovane", "uomo_adulto", "uomo_anziano", "donna_giovane", "donna_adulta", "donna_anziana", "bambino", "bambina"]
const SPACING: Vector2 = Vector2(1.3, 1.6)
const CAMERA_DISTANCE: float = 17.0
const PITCH_DEGREES: float = 30.0
const FOV_DEGREES: float = 35.0

var _out_path: String = ""
var _frames: int = 0


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_out_path = args[0]
	var view: String = args[1] if args.size() > 1 else "south"
	var root: Node3D = Node3D.new()
	get_root().add_child(root)
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.5, 0.42, 0.38)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.75, 0.68, 0.72)
	environment.ambient_light_energy = 0.7
	var world: WorldEnvironment = WorldEnvironment.new()
	world.environment = environment
	root.add_child(world)
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.82, 0.62)
	sun.light_energy = 1.3
	sun.rotation_degrees = Vector3(-30.0, 330.0, 0.0)
	root.add_child(sun)
	NpcSprite.sun_azimuth_degrees = NAN
	var rows: Array[StringName] = [&""]
	rows.append_array(CrowdTrades.names())
	for row: int in rows.size():
		for column: int in TYPES.size():
			var person: NpcSprite = NpcSprite.new()
			person.sprite_texture = load("res://assets/sprites/folla/%s_%s.png" % [TYPES[column], view])
			person.trade = rows[row]
			person.position = Vector3((column - (TYPES.size() - 1) * 0.5) * SPACING.x, 0.0, (row - (rows.size() - 1) * 0.5) * SPACING.y)
			root.add_child(person)
	var camera: Camera3D = Camera3D.new()
	camera.fov = FOV_DEGREES
	var pitch: float = deg_to_rad(PITCH_DEGREES)
	var target: Vector3 = Vector3(0.0, 1.0, 0.0)
	camera.look_at_from_position(target + Vector3(0.0, sin(pitch), cos(pitch)) * CAMERA_DISTANCE, target)
	root.add_child(camera)
	camera.current = true


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 12:
		get_root().get_texture().get_image().save_png(_out_path)
		print("trade_preview: saved " + _out_path)
		return true
	return false
