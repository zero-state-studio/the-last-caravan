extends SceneTree
## The second look sheet of chapter 1 (phase 4b step 3): only the redone
## elements, next to Ottavia for the scale, in the chapter's light. Three
## pictures: the field-cart built in Godot with its terraces and crops and
## the 16 m top; the Rooted Leafback, the cage, the cabbage and the
## Frinitore swarm; the redone sprites and cards up close.
## Usage: godot --path . --resolution 1280x800 --script res://scripts/dev/c01_look_sheet.gd -- <out_dir>

const PIXELLAB: String = "res://source-assets/pixellab/2026-09-29-capitolo01/"
const OTTAVIA: String = "res://source-assets/pixellab/2026-09-26-ottavia-v1-south/ottavia_south_v1_definitiva.png"
const MODELS: String = "res://assets/models/capitolo01/"

var _out: String = ""
var _camera: Camera3D
var _shots: Array[Dictionary] = []
var _frames: int = 0


func _initialize() -> void:
	_out = OS.get_cmdline_user_args()[0]
	var root: Node3D = Node3D.new()
	get_root().add_child(root)
	_world(root)
	# 1. The field-cart at 24 x 10 m with its two terraces, and the top.
	var cart: Node3D = FieldCartModel.build()
	root.add_child(cart)
	FieldCartModel.terrace(cart, Vector3.ZERO, Vector2(20.0, 9.0), 2.0)
	LevelBlocks.box(cart, Vector3(0.0, 3.25, 0.0), Vector3(1.6, 2.5, 1.6), LevelBlocks.material(FieldCartModel.WOOD), false)
	FieldCartModel.terrace(cart, Vector3(0.0, 0.0, 0.0), Vector2(18.0, 9.0), 4.5)
	for x: float in [2.0, 4.5, 7.0]:
		_model(root, MODELS + "cavolo_a_ventaglio_v2.glb", Vector3(x, 4.5, -2.5))
	for x: float in range(-8, 0, 1):
		for z: float in [-3.0, -1.5, 0.0, 1.5, 3.0]:
			_sprite(root, PIXELLAB + "spighe_v2.png", Vector3(x, 4.5, z))
	for x: float in range(-9, -2, 2):
		_sprite(root, PIXELLAB + "tuberi_v2.png", Vector3(float(x), 2.0, 4.0))
	_sprite(root, OTTAVIA, Vector3(-5.0, 4.5, 3.5))
	_sprite(root, OTTAVIA, Vector3(-14.0, 0.0, 7.0))
	_model(root, MODELS + "cima_rotonda_16m.glb", Vector3(26.0, 0.0, 0.0))
	_sprite(root, OTTAVIA, Vector3(26.0, 0.0, 10.0))
	# 2. The Rooted Leafback, the cage, the cabbage, the swarm.
	_model(root, MODELS + "foglione_radicato_v2.glb", Vector3(-4.0, 0.0, 40.0))
	_model(root, MODELS + "gabbia_di_piante_v2.glb", Vector3(2.5, 0.0, 40.0))
	_sprite(root, PIXELLAB + "pia/south.png", Vector3(2.5, 0.0, 42.2))
	_model(root, MODELS + "cavolo_a_ventaglio_v2.glb", Vector3(6.0, 0.0, 40.0))
	var swarm: FrinitoreSwarm = FrinitoreSwarm.new()
	swarm.position = Vector3(9.0, 0.9, 40.0)
	root.add_child(swarm)
	_sprite(root, OTTAVIA, Vector3(0.0, 0.0, 43.0))
	# 3. The redone sprites and cards up close.
	var x: float = -4.2
	for path: String in [OTTAVIA, PIXELLAB + "voltafaccia_v2/south.png", PIXELLAB + "coccio_v2/south.png", PIXELLAB + "specchietto_v2/south.png", PIXELLAB + "specchietto_v2/east.png", PIXELLAB + "pellegrino_v2/south.png", PIXELLAB + "stelo_v2.png", PIXELLAB + "spighe_v2.png", PIXELLAB + "tuberi_v2.png"]:
		_sprite(root, path, Vector3(x, 0.0, 80.0))
		x += 1.05 if not path.contains("pellegrino") else 1.6
	_camera = Camera3D.new()
	_camera.fov = 35.0
	root.add_child(_camera)
	_camera.current = true
	_shots = [
		{"name": "01-carro-campo-montato-e-cima.png", "target": Vector3(8.0, 2.5, 0.0), "distance": 48.0, "pitch": 40.0},
		{"name": "02-carro-campo-da-vicino.png", "target": Vector3(-6.0, 3.0, 2.0), "distance": 16.0, "pitch": 45.0},
		{"name": "03-foglione-radicato-gabbia-cavolo-frinitori.png", "target": Vector3(2.5, 1.6, 41.0), "distance": 15.0, "pitch": 30.0},
		{"name": "04-sprite-rifatti.png", "target": Vector3(0.6, 0.8, 80.0), "distance": 10.5, "pitch": 25.0},
	]
	_aim(_shots[0])


func _process(_delta: float) -> bool:
	_frames += 1
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
	LevelBlocks.box(root, Vector3(0.0, -0.5, 40.0), Vector3(120.0, 1.0, 140.0), LevelBlocks.material(preload("res://assets/textures/terrain/ground_dry_meadow.png")), false)


func _model(root: Node3D, path: String, at: Vector3) -> void:
	var model: Node3D = (load(path) as PackedScene).instantiate()
	root.add_child(model)
	var box: AABB = VehicleKit.bounds(model)
	model.position = at - Vector3(box.get_center().x, box.position.y, box.get_center().z)


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
