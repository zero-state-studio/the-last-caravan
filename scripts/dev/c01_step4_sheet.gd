extends SceneTree
## Close-ups of the final chapter 1 pieces (phase 4b step 4), in the
## chapter's light, next to Ottavia for the scale: the field-cart with its
## hubs and Tails, the Rooted Leafback whole, the creatures' strips.
## Usage: godot --path . --resolution 1280x800 --script res://scripts/dev/c01_step4_sheet.gd -- <out_dir> [shot ...]

const OTTAVIA: String = "res://source-assets/pixellab/2026-09-26-ottavia-v1-south/ottavia_south_v1_definitiva.png"

const CREATURES: Array[String] = ["res://scenes/creatures/voltafaccia.tscn"]

var _out: String = ""
var _camera: Camera3D
var _shots: Array[Dictionary] = []
var _frames: int = 0
var _basking: RootedFoglione


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_out = args[0]
	var wanted: PackedStringArray = args.slice(1)
	var root: Node3D = Node3D.new()
	get_root().add_child(root)
	_world(root)
	var cart: Node3D = FieldCartModel.build()
	root.add_child(cart)
	_sprite(root, OTTAVIA, Vector3(15.0, 0.0, 4.0))
	# The creatures with their strips, 40 m south of the cart.
	var x: float = -3.0
	for path: String in CREATURES:
		var creature: Node3D = (load(path) as PackedScene).instantiate() if path.ends_with(".tscn") else (load(path) as GDScript).new()
		creature.position = Vector3(x, 0.0, 40.0)
		root.add_child(creature)
		x += 2.0
	_sprite(root, OTTAVIA, Vector3(x, 0.0, 40.0))
	# The Rooted Leafback whole, on planks of the top: closed (left, face to
	# the sun, west) and basking with its leaves open (right, face south).
	LevelBlocks.box(root, Vector3(0.0, -0.1, 80.0), Vector3(30.0, 0.2, 14.0), LevelBlocks.material(FieldCartModel.WOOD), false)
	var closed: RootedFoglione = RootedFoglione.new()
	closed.position = Vector3(-5.5, 0.0, 80.0)
	root.add_child(closed)
	closed.facing = Vector3(-0.7, 0.0, 0.7).normalized()
	var basking: RootedFoglione = RootedFoglione.new()
	basking.position = Vector3(5.5, 0.0, 80.0)
	root.add_child(basking)
	basking.facing = Vector3.BACK
	basking.act = RootedFoglione.Act.BASK
	_basking = basking
	_sprite(root, OTTAVIA, Vector3(0.0, 0.0, 82.0))
	_camera = Camera3D.new()
	_camera.fov = 35.0
	root.add_child(_camera)
	_camera.current = true
	var all: Array[Dictionary] = [
		{"name": "cart-tails.png", "target": Vector3(14.0, 0.5, 0.0), "distance": 22.0, "pitch": 50.0},
		{"name": "cart-wheels.png", "target": Vector3(0.0, 1.2, 5.0), "distance": 14.0, "pitch": 20.0},
		{"name": "boss-front.png", "target": Vector3(0.0, 1.8, 80.0), "distance": 21.0, "pitch": 14.0},
		{"name": "boss-game.png", "target": Vector3(0.0, 1.6, 80.0), "distance": 24.0, "pitch": 50.0},
		{"name": "creatures.png", "target": Vector3(0.0, 0.8, 41.5), "distance": 9.0, "pitch": 40.0},
	]
	for shot: Dictionary in all:
		if wanted.is_empty() or wanted.has(String(shot["name"]).get_basename()):
			_shots.append(shot)
	_aim(_shots[0])


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 3:
		# The boss builds its look in _ready: open its leaves once it has.
		for hinge: Node3D in _basking._leaves:
			(hinge.get_child(0) as Node3D).rotation.x = RootedFoglione.LEAF_OPEN
	if _frames % 14 != 0:
		return false
	var shot: Dictionary = _shots.pop_front()
	get_root().get_texture().get_image().save_png(_out.path_join(shot["name"]))
	if _shots.is_empty():
		return true
	_aim(_shots[0])
	return false


func _aim(shot: Dictionary) -> void:
	var pitch: float = deg_to_rad(float(shot["pitch"]))
	var target: Vector3 = shot["target"]
	_camera.look_at_from_position(target + Vector3(0.0, sin(pitch), cos(pitch)) * float(shot["distance"]), target)


func _world(root: Node3D) -> void:
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.36, 0.3, 0.42)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.5, 0.45, 0.85)
	environment.ambient_light_energy = 0.8
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world: WorldEnvironment = WorldEnvironment.new()
	world.environment = environment
	root.add_child(world)
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-24.0, 290.0, 0.0)
	sun.light_color = Color(1.0, 0.76, 0.5)
	sun.light_energy = 1.7
	sun.shadow_enabled = true
	root.add_child(sun)
	LevelBlocks.box(root, Vector3(0.0, -0.5, 0.0), Vector3(160.0, 1.0, 160.0), LevelBlocks.material(preload("res://assets/textures/terrain/ground_dry_meadow.png")), false)


func _sprite(root: Node3D, path: String, at: Vector3) -> void:
	var sprite: Sprite3D = Sprite3D.new()
	var image: Image = Image.load_from_file(ProjectSettings.globalize_path(path))
	sprite.texture = ImageTexture.create_from_image(image)
	sprite.pixel_size = WorldScale.METERS_PER_PIXEL
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.shaded = false
	sprite.offset = Vector2(0.0, image.get_height() * 0.5)
	sprite.position = at
	root.add_child(sprite)

