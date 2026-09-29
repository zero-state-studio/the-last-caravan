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
## Gentle hollows in the ground outside the band where one plays (the camp,
## the roads, the way of the column): flat inside FLAT_BAND, rising to
## HOLLOW_METERS within HOLLOW_FADE metres of its edge.
const FLAT_BAND: Rect2 = Rect2(-480.0, -34.0, 660.0, 58.0)
const HOLLOW_FADE: float = 14.0
const HOLLOW_METERS: float = 1.1
const HOLLOW_SEED: int = 7331
## Wrecks per 1000 square metres of plain.
const PLAIN_WRECKS: Dictionary = {
	"res://assets/models/props/carro_abbandonato.glb": 0.5,
	"res://assets/models/props/ruota_interrata.glb": 0.8,
	"res://assets/models/props/staccionata.glb": 0.8,
	"res://assets/models/props/segnavia.glb": 0.5,
	"res://assets/models/props/generatore_rotto.glb": 0.3,
}
const PLAIN_RUINS: Array[String] = ["res://assets/models/ruins/casa_diroccata.glb", "res://assets/models/ruins/palazzo_sventrato.glb", "res://assets/models/ruins/facciata.glb"]
## Props one cannot walk through, with the share of their width that
## blocks (trees only by the trunk; bushes and stones stay passable).
const SOLID_PROPS: Dictionary = {"roccia_grande": 0.8, "tronco_caduto": 0.8, "ceppo": 0.6, "albero": 0.15, "alberello": 0.15}
const FROST_FIELD_SEED: int = 1250
const GROUND_CELL: float = 4.0
const COLLISION_CELL: float = 2.0
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

## The dead city (_place_dead_city): models and how often each appears.
## Ruins stand a little into the ground, on its lowest point around them.
const CITY_RUINS: Array[Dictionary] = [
	{"path": "res://assets/models/ruins/facciata.glb", "weight": 3.0},
	{"path": "res://assets/models/ruins/palazzo_sventrato.glb", "weight": 3.0},
	{"path": "res://assets/models/ruins/casa_diroccata.glb", "weight": 2.5},
	{"path": "res://assets/models/ruins/muro_arco.glb", "weight": 2.0},
	{"path": "res://assets/models/ruins/ciminiera.glb", "weight": 1.0},
	{"path": "res://assets/models/ruins/torre_spezzata.glb", "weight": 1.0},
	{"path": "res://assets/models/ruins/ponte_crollato.glb", "weight": 0.6},
]
const CITY_SEED: int = 4242
const CITY_SIZE: int = 32
const CITY_SPACING: float = 13.0
const CITY_NEAR_Z: float = -46.0
const CITY_FAR_Z: float = -118.0
## Centres of the old city blocks (x, z).
const CITY_BLOCKS: Array[Vector2] = [Vector2(-170.0, -80.0), Vector2(-105.0, -90.0), Vector2(-40.0, -72.0), Vector2(20.0, -95.0), Vector2(85.0, -78.0), Vector2(140.0, -100.0)]

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
static func build_ground(parent: Node3D, random: RandomNumberGenerator, roads: Array = ROADS) -> void:
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = GROUND_SHADER
	material.set_shader_parameter(&"base_texture", TEX_MEADOW)
	material.set_shader_parameter(&"base_alt_texture", TEX_MEADOW_B)
	material.set_shader_parameter(&"road_texture", TEX_ROAD)
	material.set_shader_parameter(&"gravel_texture", TEX_GRAVEL)
	material.set_shader_parameter(&"frost_texture", TEX_FROST)
	material.set_shader_parameter(&"layer_mask", ImageTexture.create_from_image(paint_mask(random, roads)))
	material.set_shader_parameter(&"alt_amount", 0.3)
	material.set_shader_parameter(&"alt_patch_meters", 9.0)
	material.set_shader_parameter(&"mask_rect", Vector4(MASK_RECT.position.x, MASK_RECT.position.y, MASK_RECT.size.x, MASK_RECT.size.y))
	var ground: MeshInstance3D = MeshInstance3D.new()
	ground.name = "Ground"
	ground.mesh = _ground_mesh()
	ground.material_override = material
	parent.add_child(ground)
	parent.add_child(_ground_body())


static var _hollows: FastNoiseLite
## Where the ground stays flat (where one plays); each scene sets its own
## before building the ground.
static var flat_rects: Array[Rect2] = [FLAT_BAND]
static var hollow_meters: float = HOLLOW_METERS


## Height of the ground at (x, z): 0 in the band where one plays, gentle
## hollows and swells outside it.
static func ground_height(x: float, z: float) -> float:
	var outside: float = INF
	for rect: Rect2 in flat_rects:
		outside = minf(outside, maxf(maxf(rect.position.x - x, x - rect.end.x), maxf(rect.position.y - z, z - rect.end.y)))
	if outside <= 0.0:
		return 0.0
	if _hollows == null:
		_hollows = FastNoiseLite.new()
		_hollows.seed = HOLLOW_SEED
		_hollows.frequency = 0.03
		_hollows.fractal_octaves = 2
	var weight: float = smoothstep(0.0, HOLLOW_FADE, outside)
	return _hollows.get_noise_2d(x, z) * hollow_meters * weight


static func _ground_mesh() -> ArrayMesh:
	var tool: SurfaceTool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cells: Vector2i = Vector2i(int(GROUND_SIZE.x / GROUND_CELL), int(GROUND_SIZE.y / GROUND_CELL))
	var origin: Vector2 = -GROUND_SIZE * 0.5
	for row: int in cells.y + 1:
		for column: int in cells.x + 1:
			var x: float = origin.x + column * GROUND_CELL
			var z: float = origin.y + row * GROUND_CELL
			tool.set_uv(Vector2(float(column) / cells.x, float(row) / cells.y))
			tool.add_vertex(Vector3(x, ground_height(x, z), z))
	for row: int in cells.y:
		for column: int in cells.x:
			var a: int = row * (cells.x + 1) + column
			var b: int = a + 1
			var c: int = a + cells.x + 1
			var d: int = c + 1
			tool.add_index(a)
			tool.add_index(b)
			tool.add_index(c)
			tool.add_index(b)
			tool.add_index(d)
			tool.add_index(c)
	tool.generate_normals()
	return tool.commit()


## The ground as a height map, so hollows can be walked into.
static func _ground_body() -> StaticBody3D:
	var samples: Vector2i = Vector2i(int(GROUND_SIZE.x / COLLISION_CELL) + 1, int(GROUND_SIZE.y / COLLISION_CELL) + 1)
	var heights: PackedFloat32Array = []
	heights.resize(samples.x * samples.y)
	var origin: Vector2 = -GROUND_SIZE * 0.5
	for row: int in samples.y:
		for column: int in samples.x:
			heights[row * samples.x + column] = ground_height(origin.x + column * COLLISION_CELL, origin.y + row * COLLISION_CELL)
	var shape: HeightMapShape3D = HeightMapShape3D.new()
	shape.map_width = samples.x
	shape.map_depth = samples.y
	shape.map_data = heights
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.shape = shape
	collision.scale = Vector3(COLLISION_CELL, 1.0, COLLISION_CELL)
	var body: StaticBody3D = StaticBody3D.new()
	body.name = "GroundBody"
	body.add_child(collision)
	return body


## R road, G gravel, B frost: 1 px per metre over MASK_RECT.
static func paint_mask(random: RandomNumberGenerator, roads: Array = ROADS) -> Image:
	var width: int = int(MASK_RECT.size.x)
	var depth: int = int(MASK_RECT.size.y)
	var image: Image = Image.create(width, depth, false, Image.FORMAT_RGBA8)
	var gravel_spots: Array[Vector3] = []
	for index: int in 18:
		gravel_spots.append(Vector3(random.randf_range(-120.0, 40.0), random.randf_range(-60.0, 45.0), random.randf_range(2.5, 7.5)))
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = random.randi()
	noise.frequency = 0.04
	var patches: FastNoiseLite = FastNoiseLite.new()
	patches.seed = random.randi()
	patches.frequency = 0.07
	patches.fractal_octaves = 2
	for z: int in depth:
		for x: int in width:
			var point: Vector2 = MASK_RECT.position + Vector2(x + 0.5, z + 0.5)
			var road: float = 0.0
			for entry: Dictionary in roads:
				var distance: float = _polyline_distance(point, entry["points"])
				road = maxf(road, clampf(1.0 - (distance - float(entry["half_width"])) / 1.5, 0.0, 1.0))
			var gravel: float = 0.0
			for spot: Vector3 in gravel_spots:
				var d: float = point.distance_to(Vector2(spot.x, spot.y)) / spot.z
				gravel = maxf(gravel, clampf(1.4 - d, 0.0, 1.0))
			# Frost thickens toward the Night (east), with ragged tongues; deep
			# in it, bare patches of earth and gravel break the white.
			var frost: float = clampf((point.x - 22.0) / 45.0 + noise.get_noise_2dv(point) * 0.6, 0.0, 1.0)
			if frost > 0.4:
				# Soft values across 0.5, so the ground shader's jitter frays
				# the edges instead of drawing squares.
				var bare: float = patches.get_noise_2dv(point)
				frost = minf(frost, clampf(0.5 - (bare - 0.16) * 1.1, 0.0, 1.0))
				gravel = maxf(gravel, clampf(0.5 + (bare - 0.36) * 1.1, 0.0, 1.0))
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
	scatter.height_at = ground_height
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
			prop.position = Vector3(point.x, ground_height(point.x, point.z), point.z)
			prop.rotation.y = random.randf_range(-0.35, 0.35)
			prop.scale = Vector3.ONE * random.randf_range(entry.scale_range.x, entry.scale_range.y)
			parent.add_child(prop)
			_solid_if_needed(prop, path)
			placed += 1


## The frost field toward the Night (the column's east end, where Mirco
## stays behind): frozen bushes, rocks, fallen trunks and dead trees, low
## drifts of frost and shards of ice standing up, so the white ground is
## never an empty pattern. `is_free` keeps the way clear where needed.
static func dress_frost_field(parent: Node3D, area: Rect2, is_free: Callable) -> void:
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = FROST_FIELD_SEED
	var scatter: VegetationScatter = VegetationScatter.new()
	var entries: Array[VegetationEntry] = []
	for path: String in ["res://assets/vegetation_kit/ciuffo_erba_02.tres", "res://assets/vegetation_kit/sassi_01.tres", "res://assets/vegetation_kit/cespuglio_secco_01.tres"]:
		entries.append(load(path) as VegetationEntry)
	scatter.entries = entries
	scatter.extents = area.size * 0.5
	scatter.density = 0.12
	scatter.random_seed = FROST_FIELD_SEED
	scatter.position = Vector3(area.get_center().x, 0.0, area.get_center().y)
	parent.add_child(scatter)
	var props: Dictionary = {
		"res://assets/vegetation_kit/roccia_grande_01.tres": 22,
		"res://assets/vegetation_kit/cespuglio_secco_01.tres": 26,
		"res://assets/vegetation_kit/tronco_caduto_01.tres": 7,
		"res://assets/vegetation_kit/albero_storto_01.tres": 6,
		"res://assets/vegetation_kit/ceppo_01.tres": 6,
	}
	for path: String in props:
		var entry: VegetationEntry = load(path)
		var placed: int = 0
		var tries: int = 0
		while placed < int(props[path]) and tries < 400:
			tries += 1
			var point: Vector3 = Vector3(random.randf_range(area.position.x, area.end.x), 0.0, random.randf_range(area.position.y, area.end.y))
			if not is_free.call(point):
				continue
			var prop: Node3D = entry.model.instantiate()
			prop.position = point
			prop.rotation.y = random.randf_range(-PI, PI)
			prop.scale = Vector3.ONE * random.randf_range(entry.scale_range.x, entry.scale_range.y)
			parent.add_child(prop)
			_solid_if_needed(prop, path)
			placed += 1
	var frost_material: StandardMaterial3D = StandardMaterial3D.new()
	frost_material.albedo_texture = TEX_FROST
	frost_material.albedo_color = Color(0.92, 0.96, 1.0)
	frost_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	frost_material.uv1_triplanar = true
	frost_material.uv1_scale = Vector3.ONE * 0.4
	var ice: StandardMaterial3D = frost_material.duplicate()
	ice.albedo_color = Color(0.8, 0.9, 1.0)
	ice.roughness = 0.3
	ice.emission_enabled = true
	ice.emission = Color(0.55, 0.72, 0.95)
	ice.emission_energy_multiplier = 0.3
	# Low drifts of frost: relief on the flat white, not in the way.
	for index: int in 26:
		var at: Vector3 = Vector3(random.randf_range(area.position.x, area.end.x), 0.0, random.randf_range(area.position.y, area.end.y))
		if not is_free.call(at):
			continue
		var drift: MeshInstance3D = MeshInstance3D.new()
		var sphere: SphereMesh = SphereMesh.new()
		sphere.radial_segments = 10
		sphere.rings = 5
		drift.mesh = sphere
		drift.material_override = frost_material
		drift.scale = Vector3(random.randf_range(2.0, 5.0), random.randf_range(0.25, 0.55), random.randf_range(1.5, 3.5))
		drift.position = at
		drift.rotation.y = random.randf_range(-PI, PI)
		parent.add_child(drift)
	# Shards of ice pushed up by the cold, in small clusters.
	for cluster: int in 14:
		var centre: Vector3 = Vector3(random.randf_range(area.position.x, area.end.x), 0.0, random.randf_range(area.position.y, area.end.y))
		if not is_free.call(centre):
			continue
		for shard: int in random.randi_range(2, 5):
			var height: float = random.randf_range(0.4, 1.3)
			var piece: Node3D = LevelBlocks.box(parent, centre + Vector3(random.randf_range(-0.8, 0.8), height * 0.4, random.randf_range(-0.8, 0.8)), Vector3(random.randf_range(0.2, 0.45), height, random.randf_range(0.2, 0.4)), ice, false)
			piece.rotation = Vector3(random.randf_range(-0.4, 0.4), random.randf_range(-PI, PI), random.randf_range(-0.4, 0.4))


## The dry plain beside the column's road: rocks, dead trees, bushes, fallen
## trunks, stumps and a few ruined walls, standing on the ground's height,
## the big ones solid. `is_free` keeps the road and the ways clear.
static func dress_plain(parent: Node3D, area: Rect2, is_free: Callable, seed_value: int) -> void:
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = seed_value
	var scatter: VegetationScatter = VegetationScatter.new()
	var entries: Array[VegetationEntry] = []
	for path: String in GRASS_ENTRIES:
		entries.append(load(path) as VegetationEntry)
	scatter.entries = entries
	scatter.extents = area.size * 0.5
	scatter.density = 0.45
	scatter.random_seed = seed_value
	scatter.position = Vector3(area.get_center().x, 0.0, area.get_center().y)
	scatter.height_at = ground_height
	parent.add_child(scatter)
	var per_1000: Dictionary = {
		"res://assets/vegetation_kit/roccia_grande_01.tres": 6.0,
		"res://assets/vegetation_kit/sassi_01.tres": 8.0,
		"res://assets/vegetation_kit/cespuglio_secco_01.tres": 18.0,
		"res://assets/vegetation_kit/albero_storto_01.tres": 2.4,
		"res://assets/vegetation_kit/alberello_01.tres": 2.4,
		"res://assets/vegetation_kit/tronco_caduto_01.tres": 2.0,
		"res://assets/vegetation_kit/ceppo_01.tres": 2.0,
	}
	var surface: float = area.size.x * area.size.y / 1000.0
	for path: String in per_1000:
		var entry: VegetationEntry = load(path)
		var wanted: int = roundi(float(per_1000[path]) * surface)
		var placed: int = 0
		var tries: int = 0
		while placed < wanted and tries < wanted * 20:
			tries += 1
			var point: Vector3 = Vector3(random.randf_range(area.position.x, area.end.x), 0.0, random.randf_range(area.position.y, area.end.y))
			if not is_free.call(point):
				continue
			var prop: Node3D = entry.model.instantiate()
			prop.position = Vector3(point.x, ground_height(point.x, point.z), point.z)
			prop.rotation.y = random.randf_range(-PI, PI)
			prop.scale = Vector3.ONE * random.randf_range(entry.scale_range.x, entry.scale_range.y)
			parent.add_child(prop)
			_solid_if_needed(prop, path)
			placed += 1
	# What the caravans before left on the plain (106): wrecks, a sunk wheel,
	# broken fences, waymarks, an old Generator; all solid.
	for path: String in PLAIN_WRECKS:
		if not ResourceLoader.exists(path):
			continue
		var scene: PackedScene = load(path)
		var wanted_wrecks: int = roundi(float(PLAIN_WRECKS[path]) * surface)
		var put: int = 0
		var attempts: int = 0
		while put < wanted_wrecks and attempts < wanted_wrecks * 20:
			attempts += 1
			var at_wreck: Vector3 = Vector3(random.randf_range(area.position.x, area.end.x), 0.0, random.randf_range(area.position.y, area.end.y))
			if not is_free.call(at_wreck):
				continue
			var wreck: Node3D = scene.instantiate()
			wreck.position = Vector3(at_wreck.x, ground_height(at_wreck.x, at_wreck.z) - 0.1, at_wreck.z)
			wreck.rotation.y = random.randf_range(-PI, PI)
			parent.add_child(wreck)
			LevelBlocks.make_solid(wreck, 0.8)
			put += 1
	# A few ruined houses and walls of an older road.
	for index: int in roundi(surface * 0.12):
		var at: Vector3 = Vector3(random.randf_range(area.position.x, area.end.x), 0.0, random.randf_range(area.position.y, area.end.y))
		if not is_free.call(at):
			continue
		var model: Node3D = (load(PLAIN_RUINS[random.randi() % PLAIN_RUINS.size()]) as PackedScene).instantiate()
		model.position = Vector3(at.x, _ruin_base(at), at.z)
		model.rotation.y = random.randf_range(-PI, PI)
		parent.add_child(model)
		LevelBlocks.make_solid(model, 0.9)


## Ruins of old stone buildings between the camp and the mountains.
static func place_ruins(parent: Node3D) -> void:
	for ruin: Dictionary in RUINS:
		if not ResourceLoader.exists(ruin["path"]):
			continue
		var model: Node3D = (load(ruin["path"]) as PackedScene).instantiate()
		var at: Vector3 = ruin["at"]
		model.position = Vector3(at.x, _ruin_base(at), at.z)
		model.rotation.y = ruin["yaw"]
		parent.add_child(model)
		LevelBlocks.make_solid(model, 0.9)
	_place_dead_city(parent)


## The dead city behind the camp: a band of ruined blocks to the north,
## between the plain and the hills, so the skyline is a city, not a few
## lone buildings. Fixed seed: the same city every time.
static func _solid_if_needed(prop: Node3D, path: String) -> void:
	for name: String in SOLID_PROPS:
		if path.get_file().begins_with(name):
			LevelBlocks.make_solid(prop, SOLID_PROPS[name])
			return


static func _ruin_base(at: Vector3) -> float:
	var lowest: float = INF
	for offset: Vector2 in [Vector2.ZERO, Vector2(4.0, 0.0), Vector2(-4.0, 0.0), Vector2(0.0, 4.0), Vector2(0.0, -4.0)]:
		lowest = minf(lowest, ground_height(at.x + offset.x, at.z + offset.y))
	return lowest - 0.3


static func _place_dead_city(parent: Node3D) -> void:
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = CITY_SEED
	var scenes: Array[PackedScene] = []
	var weights: PackedFloat32Array = []
	for entry: Dictionary in CITY_RUINS:
		if ResourceLoader.exists(entry["path"]):
			scenes.append(load(entry["path"]))
			weights.append(entry["weight"])
	if scenes.is_empty():
		return
	var placed: Array[Vector3] = []
	for ruin: Dictionary in RUINS:
		placed.append(ruin["at"])
	var tries: int = 0
	while placed.size() < RUINS.size() + CITY_SIZE and tries < 800:
		tries += 1
		# Blocks: a few centres, buildings scattered around each.
		var block: int = random.randi() % CITY_BLOCKS.size()
		var centre: Vector2 = CITY_BLOCKS[block]
		var at: Vector3 = Vector3(centre.x + random.randfn(0.0, 22.0), 0.0, centre.y + random.randfn(0.0, 12.0))
		if at.z > CITY_NEAR_Z or at.z < CITY_FAR_Z:
			continue
		if placed.any(func(other: Vector3) -> bool: return Vector2(other.x - at.x, other.z - at.z).length() < CITY_SPACING):
			continue
		var model: Node3D = scenes[random.rand_weighted(weights)].instantiate()
		model.position = Vector3(at.x, _ruin_base(at), at.z)
		model.rotation.y = random.randf_range(-PI, PI)
		parent.add_child(model)
		LevelBlocks.make_solid(model, 0.9)
		placed.append(at)


## Two ridges of mountains to the north, the farther one higher and hazier:
## a heightfield with the rock texture, frost on the eastern peaks.
static func build_mountains(parent: Node3D, random: RandomNumberGenerator) -> void:
	var near_rock: ShaderMaterial = LevelBlocks.material(TEX_ROCK, TEX_ROCK, Color(0.72, 0.66, 0.62))
	var far_rock: ShaderMaterial = LevelBlocks.material(TEX_ROCK, TEX_ROCK, Color(0.5, 0.5, 0.62))
	var hills: ShaderMaterial = LevelBlocks.material(TEX_EARTH, TEX_EARTH, Color(0.8, 0.72, 0.62))
	_ridge(parent, random, hills, -120.0, -190.0, 6.0, 20.0)
	_ridge(parent, random, near_rock, -170.0, -250.0, 40.0, 90.0)
	_ridge(parent, random, far_rock, -260.0, -400.0, 90.0, 170.0)


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
