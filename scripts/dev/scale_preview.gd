extends SceneTree
## Renders test vehicles (GLB) and character sprites (PNG, south views) on flat
## ground at world scale (30 px per metre, 49/54), to judge their size next
## to Ottavia. Phase 4a step 1 (122-124, 117-121).
## Usage: godot --path . --resolution 1280x800 --script res://scripts/dev/scale_preview.gd -- \
##     <out.png> <camera_distance> <focus_x> models=<a.glb,b.glb> sprites=<a.png,b.png>

const PITCH_DEGREES: float = 35.0
const FOV_DEGREES: float = 35.0
const MODEL_GAP: float = 3.0
const SPRITE_SPACING: float = 1.3
const SPRITE_Z: float = 3.5

var _out_path: String = ""
var _frames: int = 0


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_out_path = args[0]
	var camera_distance: float = args[1].to_float()
	var focus_x: float = args[2].to_float()
	var models: PackedStringArray = []
	var sprites: PackedStringArray = []
	for argument: String in args:
		if argument.begins_with("models="):
			models = argument.trim_prefix("models=").split(",", false)
		elif argument.begins_with("sprites="):
			sprites = argument.trim_prefix("sprites=").split(",", false)

	var root: Node3D = Node3D.new()
	get_root().add_child(root)
	_add_world(root)

	var x: float = 0.0
	for path: String in models:
		var model: Node3D = _load_glb(path)
		root.add_child(model)
		var box: AABB = _bounds(model)
		model.position = Vector3(x - box.position.x, -box.position.y, -box.end.z)
		x += box.size.x + MODEL_GAP

	var sprite_x: float = focus_x - (sprites.size() - 1) * SPRITE_SPACING * 0.5
	for path: String in sprites:
		var sprite: Sprite3D = Sprite3D.new()
		var image: Image = Image.load_from_file(path)
		sprite.texture = ImageTexture.create_from_image(image)
		sprite.pixel_size = WorldScale.METERS_PER_PIXEL
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		sprite.shaded = false
		sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		# Feet at the bottom of the 64 px canvas stand on the ground.
		sprite.offset = Vector2(0.0, image.get_height() * 0.5)
		sprite.position = Vector3(sprite_x, 0.0, SPRITE_Z)
		root.add_child(sprite)
		sprite_x += SPRITE_SPACING

	var camera: Camera3D = Camera3D.new()
	camera.fov = FOV_DEGREES
	var pitch: float = deg_to_rad(PITCH_DEGREES)
	var target: Vector3 = Vector3(focus_x, 2.0, 0.0)
	camera.look_at_from_position(target + Vector3(0.0, sin(pitch), cos(pitch)) * camera_distance, target)
	root.add_child(camera)
	camera.current = true


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 12:
		var image: Image = get_root().get_texture().get_image()
		image.save_png(_out_path)
		print("scale_preview: saved " + _out_path)
		return true
	return false


func _add_world(root: Node3D) -> void:
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.55, 0.5, 0.52)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.75, 0.72, 0.8)
	environment.ambient_light_energy = 0.8
	var world: WorldEnvironment = WorldEnvironment.new()
	world.environment = environment
	root.add_child(world)
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.8, 0.6)
	sun.light_energy = 1.4
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-40.0, -70.0, 0.0)
	root.add_child(sun)
	var ground: MeshInstance3D = MeshInstance3D.new()
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(200.0, 200.0)
	ground.mesh = plane
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.45, 0.4, 0.33)
	ground.material_override = material
	root.add_child(ground)


func _load_glb(path: String) -> Node3D:
	var document: GLTFDocument = GLTFDocument.new()
	var state: GLTFState = GLTFState.new()
	if document.append_from_file(path, state) != OK:
		printerr("scale_preview: cannot read " + path)
		return Node3D.new()
	return document.generate_scene(state)


## Bounds in the model's own space (the scaling parent written by
## meshy_pixelize.py counts).
func _bounds(model: Node3D) -> AABB:
	var box: AABB = AABB()
	var first: bool = true
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance: MeshInstance3D = node
		var local: AABB = VegetationScatter.transform_in(model, mesh_instance) * mesh_instance.get_aabb()
		box = local if first else box.merge(local)
		first = false
	return box
