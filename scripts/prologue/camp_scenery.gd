class_name CampScenery
extends RefCounted
## Scenery of the prologue camp (106): a ground that is not one repeated
## pattern (dirt roads, gravel, a second meadow, frost toward the Night),
## the vegetation kit (101) spread thin, ruins of old stone buildings and
## 3D mountains on the horizon to the north.

const GROUND_SHADER: Shader = preload("res://scenes/proto/materials/ground_blend.gdshader")
const TEX_MEADOW: Texture2D = preload("res://assets/textures/terrain/ground_dry_meadow.png")
const TEX_MEADOW_B: Texture2D = preload("res://assets/textures/terrain/ground_dry_meadow_b.png")
const TEX_ROAD: Texture2D = preload("res://assets/textures/terrain/road_dirt_01.png")
const TEX_GRAVEL: Texture2D = preload("res://assets/textures/terrain/gravel_01.png")
const TEX_FROST: Texture2D = preload("res://assets/textures/terrain/frost_ground.png")
const TEX_ROCK: Texture2D = preload("res://assets/textures/terrain/rock_cliff_01.png")
const TEX_EARTH: Texture2D = preload("res://assets/textures/terrain/earth_bank_01.png")
## The mask covers this rectangle (x, z, width, depth), 1 px per metre.
const MASK_RECT: Rect2 = Rect2(-160.0, -110.0, 320.0, 200.0)
const GROUND_SIZE: Vector2 = Vector2(1000.0, 1000.0)
const GRASS_ENTRIES: Array[String] = [
	"res://assets/vegetation_kit/ciuffo_erba_01.tres",
	"res://assets/vegetation_kit/ciuffo_erba_02.tres",
	"res://assets/vegetation_kit/erba_alta_01.tres",
	"res://assets/vegetation_kit/sassi_01.tres",
]
## Kit elements spread by hand, with how many of each (sparse: this is the
## dry Twilight plain, not a forest).
const PROPS: Dictionary = {
	"res://assets/vegetation_kit/roccia_grande_01.tres": 16,
	"res://assets/vegetation_kit/sassi_01.tres": 30,
	"res://assets/vegetation_kit/cespuglio_secco_01.tres": 34,
	"res://assets/vegetation_kit/alberello_01.tres": 7,
	"res://assets/vegetation_kit/albero_storto_01.tres": 5,
	"res://assets/vegetation_kit/tronco_caduto_01.tres": 6,
	"res://assets/vegetation_kit/ceppo_01.tres": 6,
}
const RUINS: Array[Dictionary] = [
	{"path": "res://assets/models/ruins/casa_diroccata.glb", "at": Vector3(-96.0, 0.0, -78.0), "yaw": 0.4},
	{"path": "res://assets/models/ruins/torre_spezzata.glb", "at": Vector3(-38.0, 0.0, -96.0), "yaw": 0.0},
	{"path": "res://assets/models/ruins/muro_arco.glb", "at": Vector3(22.0, 0.0, -84.0), "yaw": -0.2},
	{"path": "res://assets/models/ruins/casa_diroccata.glb", "at": Vector3(64.0, 0.0, -104.0), "yaw": 2.6},
	{"path": "res://assets/models/ruins/muro_arco.glb", "at": Vector3(-132.0, 0.0, -40.0), "yaw": 1.3},
]

## Roads as polylines (points in metres) with a half width.
const ROADS: Array[Dictionary] = [
	# The alley between the rows of the camp.
	{"points": [Vector2(-140.0, 9.0), Vector2(-60.0, 7.0), Vector2(0.0, 8.5), Vector2(60.0, 7.5)], "half_width": 2.4},
	{"points": [Vector2(-120.0, -25.0), Vector2(-30.0, -26.0), Vector2(40.0, -24.0)], "half_width": 1.8},
	{"points": [Vector2(-40.0, -44.0), Vector2(-36.0, -10.0), Vector2(-40.0, 30.0)], "half_width": 1.6},
	# The wheel tracks of the column, coming from the east, out of the frost.
	{"points": [Vector2(14.0, -2.0), Vector2(60.0, -4.0), Vector2(110.0, -9.0), Vector2(160.0, -12.0)], "half_width": 3.2},
]


## The ground plane with its blended material and a collision slab.
static func build_ground(parent: Node3D, random: RandomNumberGenerator) -> void:
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = GROUND_SHADER
	material.set_shader_parameter(&"base_texture", TEX_MEADOW)
	material.set_shader_parameter(&"base_alt_texture", TEX_MEADOW_B)
	material.set_shader_parameter(&"road_texture", TEX_ROAD)
	material.set_shader_parameter(&"gravel_texture", TEX_GRAVEL)
	material.set_shader_parameter(&"frost_texture", TEX_FROST)
	material.set_shader_parameter(&"layer_mask", ImageTexture.create_from_image(paint_mask(random)))
	material.set_shader_parameter(&"alt_amount", 0.3)
	material.set_shader_parameter(&"alt_patch_meters", 9.0)
	material.set_shader_parameter(&"mask_rect", Vector4(MASK_RECT.position.x, MASK_RECT.position.y, MASK_RECT.size.x, MASK_RECT.size.y))
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = GROUND_SIZE
	var ground: MeshInstance3D = MeshInstance3D.new()
	ground.name = "Ground"
	ground.mesh = plane
	ground.material_override = material
	parent.add_child(ground)
	var slab: Node3D = LevelBlocks.box(parent, Vector3(0.0, -0.5, 0.0), Vector3(GROUND_SIZE.x, 1.0, GROUND_SIZE.y), material)
	slab.visible = false


## R road, G gravel, B frost: 1 px per metre over MASK_RECT.
static func paint_mask(random: RandomNumberGenerator) -> Image:
	var width: int = int(MASK_RECT.size.x)
	var depth: int = int(MASK_RECT.size.y)
	var image: Image = Image.create(width, depth, false, Image.FORMAT_RGBA8)
	var gravel_spots: Array[Vector3] = []
	for index: int in 18:
		gravel_spots.append(Vector3(random.randf_range(-120.0, 40.0), random.randf_range(-60.0, 45.0), random.randf_range(2.5, 7.5)))
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = random.randi()
	noise.frequency = 0.04
	for z: int in depth:
		for x: int in width:
			var point: Vector2 = MASK_RECT.position + Vector2(x + 0.5, z + 0.5)
			var road: float = 0.0
			for entry: Dictionary in ROADS:
				var distance: float = _polyline_distance(point, entry["points"])
				road = maxf(road, clampf(1.0 - (distance - float(entry["half_width"])) / 1.5, 0.0, 1.0))
			var gravel: float = 0.0
			for spot: Vector3 in gravel_spots:
				var d: float = point.distance_to(Vector2(spot.x, spot.y)) / spot.z
				gravel = maxf(gravel, clampf(1.4 - d, 0.0, 1.0))
			# Frost thickens toward the Night (east), with ragged tongues.
			var frost: float = clampf((point.x - 22.0) / 45.0 + noise.get_noise_2dv(point) * 0.6, 0.0, 1.0)
			image.set_pixel(x, z, Color(road, gravel, frost, 1.0))
	return image


static func _polyline_distance(point: Vector2, points: Array) -> float:
	var best: float = INF
	for index: int in points.size() - 1:
		var a: Vector2 = points[index]
		var b: Vector2 = points[index + 1]
		best = minf(best, point.distance_to(Geometry2D.get_closest_point_to_segment(point, a, b)))
	return best


static func on_road(point: Vector3, margin: float = 1.0) -> bool:
	for entry: Dictionary in ROADS:
		if _polyline_distance(Vector2(point.x, point.z), entry["points"]) < float(entry["half_width"]) + margin:
			return true
	return false


## Grass tufts over the camp, and kit props placed where `is_free` allows.
static func place_nature(parent: Node3D, random: RandomNumberGenerator, is_free: Callable) -> void:
	var scatter: VegetationScatter = VegetationScatter.new()
	var entries: Array[VegetationEntry] = []
	for path: String in GRASS_ENTRIES:
		entries.append(load(path) as VegetationEntry)
	scatter.entries = entries
	scatter.extents = Vector2(120.0, 70.0)
	scatter.density = 0.28
	scatter.random_seed = 106
	scatter.position = Vector3(-15.0, 0.0, -5.0)
	parent.add_child(scatter)
	for path: String in PROPS:
		var entry: VegetationEntry = load(path)
		var count: int = PROPS[path]
		var placed: int = 0
		var tries: int = 0
		while placed < count and tries < count * 40:
			tries += 1
			var point: Vector3 = Vector3(random.randf_range(-150.0, 90.0), 0.0, random.randf_range(-70.0, 45.0))
			if on_road(point) or not is_free.call(point):
				continue
			var prop: Node3D = entry.model.instantiate()
			prop.position = point
			prop.rotation.y = random.randf_range(-0.35, 0.35)
			prop.scale = Vector3.ONE * random.randf_range(entry.scale_range.x, entry.scale_range.y)
			parent.add_child(prop)
			placed += 1


## Ruins of old stone buildings between the camp and the mountains.
static func place_ruins(parent: Node3D) -> void:
	for ruin: Dictionary in RUINS:
		if not ResourceLoader.exists(ruin["path"]):
			continue
		var model: Node3D = (load(ruin["path"]) as PackedScene).instantiate()
		model.position = ruin["at"]
		model.rotation.y = ruin["yaw"]
		parent.add_child(model)


## Two ridges of mountains to the north, the farther one higher and hazier:
## a heightfield with the rock texture, frost on the eastern peaks.
static func build_mountains(parent: Node3D, random: RandomNumberGenerator) -> void:
	var near_rock: ShaderMaterial = LevelBlocks.material(TEX_ROCK, TEX_ROCK, Color(0.72, 0.66, 0.62))
	var far_rock: ShaderMaterial = LevelBlocks.material(TEX_ROCK, TEX_ROCK, Color(0.5, 0.5, 0.62))
	var hills: ShaderMaterial = LevelBlocks.material(TEX_EARTH, TEX_EARTH, Color(0.8, 0.72, 0.62))
	_ridge(parent, random, hills, -120.0, -205.0, 5.0, 16.0)
	_ridge(parent, random, near_rock, -200.0, -290.0, 28.0, 70.0)
	_ridge(parent, random, far_rock, -330.0, -470.0, 70.0, 150.0)


static func _ridge(parent: Node3D, random: RandomNumberGenerator, material: Material, z_near: float, z_far: float, low: float, high: float) -> void:
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = random.randi()
	noise.frequency = 0.012
	noise.fractal_octaves = 4
	var columns: int = 96
	var rows: int = 14
	var x0: float = -420.0
	var x1: float = 380.0
	var tool: SurfaceTool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var heights: Array[PackedFloat32Array] = []
	for row: int in rows + 1:
		var line: PackedFloat32Array = []
		var t: float = float(row) / rows
		for column: int in columns + 1:
			var x: float = lerpf(x0, x1, float(column) / columns)
			var z: float = lerpf(z_near, z_far, t)
			# Rises from the plain at the front edge to the crest, then falls.
			var profile: float = sin(t * PI)
			var n: float = noise.get_noise_2d(x, z) * 0.5 + 0.5
			line.append(maxf(0.0, profile * lerpf(low, high, n) - (1.0 - profile) * 4.0))
		heights.append(line)
	for row: int in rows:
		for column: int in columns:
			var corners: Array[Vector3] = []
			for offset: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
				var c: int = column + offset.x
				var r: int = row + offset.y
				corners.append(Vector3(lerpf(x0, x1, float(c) / columns), heights[r][c], lerpf(z_near, z_far, float(r) / rows)))
			for index: int in [0, 2, 1, 0, 3, 2]:
				tool.add_vertex(corners[index])
	tool.generate_normals()
	var mountains: MeshInstance3D = MeshInstance3D.new()
	mountains.name = "Mountains"
	mountains.mesh = tool.commit()
	mountains.material_override = material
	mountains.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mountains)
