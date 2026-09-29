class_name C01Kit
extends RefCounted
## Shapes for chapter 1: boxes, slopes, rails, crops, grass, wheels,
## rooms, entries and gated passages. Built in phase 4b step 2 with plain
## colours; since step 4 every base colour below (and its lighter or darker
## variants) draws with its final tiled texture at the world density, 30 px
## per metre (49, 54): cart wood, terrace soil, generator iron, the patched
## cloth of the prologue tents, stone, dry meadow.

const WOOD: Color = Color(0.55, 0.4, 0.26)
const WOOD_DARK: Color = Color(0.38, 0.27, 0.18)
const SOIL: Color = Color(0.45, 0.33, 0.24)
const DRY_GRASS: Color = Color(0.78, 0.66, 0.38)
const EAR: Color = Color(0.86, 0.68, 0.3)
const CABBAGE: Color = Color(0.4, 0.46, 0.4)
const TUBER: Color = Color(0.78, 0.86, 0.95)
const STONE: Color = Color(0.66, 0.6, 0.52)
const IRON: Color = Color(0.3, 0.3, 0.33)
const CLOTH: Color = Color(0.6, 0.5, 0.36)

const TEX_WOOD: Texture2D = preload("res://assets/textures/capitolo01/legno_carro.png")
const TEX_SOIL: Texture2D = preload("res://assets/textures/capitolo01/terra_terrazze.png")
const TEX_IRON: Texture2D = preload("res://assets/textures/capitolo01/metallo_generatore.png")
const TEX_CLOTH: Texture2D = preload("res://assets/models/vehicles/moduli/tenda_0.png")
const TEX_STONE: Texture2D = preload("res://assets/textures/terrain/rock_cliff_01.png")
const TEX_MEADOW: Texture2D = preload("res://assets/textures/terrain/ground_dry_meadow.png")
const TEX_EARTH: Texture2D = preload("res://assets/textures/terrain/earth_bank_01.png")
## Base colour -> [top texture, side texture, tint of the base]. The tint
## keeps the dark wood darker than the light one; the variants of a base
## (lightened, darkened) scale it.
const SURFACES: Array[Array] = [
	[WOOD, TEX_WOOD, TEX_WOOD, Color(1.0, 1.0, 1.0)],
	[WOOD_DARK, TEX_WOOD, TEX_WOOD, Color(0.72, 0.68, 0.66)],
	[SOIL, TEX_SOIL, TEX_WOOD, Color(1.0, 1.0, 1.0)],
	[DRY_GRASS, TEX_MEADOW, TEX_EARTH, Color(1.0, 1.0, 1.0)],
	[STONE, TEX_STONE, TEX_STONE, Color(1.0, 1.0, 1.0)],
	[IRON, TEX_IRON, TEX_IRON, Color(1.0, 1.0, 1.0)],
	[CLOTH, TEX_CLOTH, TEX_CLOTH, Color(1.0, 1.0, 1.0)],
]
const MATCH_TOLERANCE: float = 0.012
const EARS_CARD: Texture2D = preload("res://assets/sprites/capitolo01/spighe_piegate.png")
const TUBERS_CARD: Texture2D = preload("res://assets/sprites/capitolo01/tuberi_di_brina.png")
const TALL_GRASS_CARD: Texture2D = preload("res://assets/textures/vegetation/grass_tall_01.png")
const STEM_CARD: Texture2D = preload("res://assets/sprites/capitolo01/stelo_a_nodi.png")
const CAGE_MODEL: PackedScene = preload("res://assets/models/capitolo01/gabbia_di_piante_v3.glb")
const CABBAGE_MODEL: PackedScene = preload("res://assets/models/capitolo01/cavolo_a_ventaglio_v3.glb")
## Yaw of the flat fan cabbage: its face toward west-south-west.
const CABBAGE_YAW: float = -PI / 3.0
const CARD_SHADER: Shader = preload("res://scenes/proto/materials/foreground_fade.gdshader")
const GROUND_SHADER: Shader = preload("res://scenes/proto/materials/ground_blend.gdshader")
## Kit tufts on the open ground round the carts, per square metre.
const GROUND_TUFTS: float = 0.22

static var _materials: Dictionary = {}


## The material of a shape: the textured surface when `color` is one of the
## bases (or a lighter or darker variant), a plain colour otherwise.
static func material(color: Color) -> Material:
	var key: String = color.to_html()
	if _materials.has(key):
		return _materials[key]
	var made: Material = null
	for surface: Array in SURFACES:
		var scale: Variant = _variant_scale(color, surface[0])
		if scale != null:
			var tint: Color = surface[3]
			var by: Color = scale
			made = LevelBlocks.material(surface[1], surface[2], Color(tint.r * by.r, tint.g * by.g, tint.b * by.b))
			break
	if made == null:
		var plain: StandardMaterial3D = StandardMaterial3D.new()
		plain.albedo_color = color
		plain.roughness = 1.0
		made = plain
	_materials[key] = made
	return made


## How `color` scales `base` channel by channel when it is the base itself,
## base.darkened(x) or base.lightened(x); null when it is another colour.
static func _variant_scale(color: Color, base: Color) -> Variant:
	var ratio: Vector3 = Vector3(color.r / base.r, color.g / base.g, color.b / base.b)
	if absf(ratio.x - ratio.y) < MATCH_TOLERANCE * 4.0 and absf(ratio.x - ratio.z) < MATCH_TOLERANCE * 4.0:
		return Color(ratio.x, ratio.y, ratio.z)
	var amount: Vector3 = Vector3((color.r - base.r) / (1.0 - base.r), (color.g - base.g) / (1.0 - base.g), (color.b - base.b) / (1.0 - base.b))
	if amount.x > 0.0 and absf(amount.x - amount.y) < MATCH_TOLERANCE and absf(amount.x - amount.z) < MATCH_TOLERANCE:
		return Color(ratio.x, ratio.y, ratio.z)
	return null


## The open ground of a diorama: a solid slab `size` big whose top is at
## `at.y + size.y / 2`, drawn like the prologue plain (two dry meadows in
## large patches, no repeated grid) with the kit's tufts spread thin on it
## (101). The light of each room gives its temperature.
static func ground(parent: Node3D, at: Vector3, size: Vector3, seed_value: int = 1) -> StaticBody3D:
	var body: StaticBody3D = box(parent, at, size, DRY_GRASS)
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = GROUND_SHADER
	material.set_shader_parameter(&"base_texture", TEX_MEADOW)
	material.set_shader_parameter(&"base_alt_texture", CampScenery.TEX_MEADOW_B)
	material.set_shader_parameter(&"road_texture", CampScenery.TEX_ROAD)
	material.set_shader_parameter(&"gravel_texture", CampScenery.TEX_GRAVEL)
	material.set_shader_parameter(&"frost_texture", CampScenery.TEX_FROST)
	material.set_shader_parameter(&"alt_amount", 0.5)
	material.set_shader_parameter(&"alt_patch_meters", 6.0)
	for child: Node in body.get_children():
		if child is MeshInstance3D:
			(child as MeshInstance3D).material_override = material
	var tufts: VegetationScatter = VegetationScatter.new()
	var entries: Array[VegetationEntry] = []
	for path: String in CampScenery.GRASS_ENTRIES:
		entries.append(load(path) as VegetationEntry)
	tufts.entries = entries
	tufts.extents = Vector2(size.x, size.z) * 0.5
	tufts.density = GROUND_TUFTS
	tufts.random_seed = seed_value
	tufts.position = at + Vector3.UP * size.y * 0.5
	parent.add_child(tufts)
	return body


## A solid box under `parent`, at `at` in the parent's space.
static func box(parent: Node3D, at: Vector3, size: Vector3, color: Color, turn: Vector3 = Vector3.ZERO) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	parent.add_child(body)
	body.position = at
	shape_on(body, Vector3.ZERO, size, color, turn)
	return body


## A box of collision and its mesh added straight to `body` (a turning
## platform, for example), at `at` in its space.
static func shape_on(body: CollisionObject3D, at: Vector3, size: Vector3, color: Color, turn: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	shape.position = at
	shape.rotation = turn
	body.add_child(shape)
	var mesh: MeshInstance3D = visual(body, at, size, color, turn)
	return mesh


## A box that is only seen (scenery, crops).
static func visual(parent: Node3D, at: Vector3, size: Vector3, color: Color, turn: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material(color)
	mesh_instance.position = at
	mesh_instance.rotation = turn
	parent.add_child(mesh_instance)
	return mesh_instance


## A walkable slope from `top` down to `bottom` (points on its surface, in
## the parent's space), `width` wide, added to `body`.
static func slope_on(body: CollisionObject3D, top: Vector3, bottom: Vector3, width: float, color: Color) -> void:
	var run: Vector3 = bottom - top
	var length: float = run.length()
	var flat: Vector3 = Vector3(run.x, 0.0, run.z)
	var yaw: float = atan2(-flat.x, -flat.z)
	var pitch: float = atan2(-run.y, flat.length())
	var center: Vector3 = (top + bottom) * 0.5 + Vector3.DOWN * 0.1
	# A box whose long side is its local Z, tilted down along the run.
	shape_on(body, center, Vector3(width, 0.2, length), color, Vector3(-pitch, yaw, 0.0))


static func slope(parent: Node3D, top: Vector3, bottom: Vector3, width: float, color: Color) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	parent.add_child(body)
	slope_on(body, top, bottom, width, color)
	return body


## A low rail between two points (at their height), on `body`.
static func rail_on(body: CollisionObject3D, a: Vector3, b: Vector3, height: float = 0.9) -> void:
	var run: Vector3 = b - a
	var center: Vector3 = (a + b) * 0.5 + Vector3.UP * height * 0.5
	var yaw: float = atan2(run.x, run.z)
	shape_on(body, center, Vector3(0.12, height, run.length()), WOOD_DARK, Vector3(0.0, yaw, 0.0))


## Rails all round a rectangle of `size` (x, z) at height `y`, leaving the
## openings listed as [side, from, to] (side "n", "s", "e", "w"; from and
## to along the side, in metres from its centre).
static func rails_around(body: CollisionObject3D, center: Vector3, size: Vector2, openings: Array = []) -> void:
	var half: Vector2 = size * 0.5
	var sides: Dictionary = {
		"n": [Vector3(-half.x, 0.0, -half.y), Vector3(half.x, 0.0, -half.y)],
		"s": [Vector3(-half.x, 0.0, half.y), Vector3(half.x, 0.0, half.y)],
		"w": [Vector3(-half.x, 0.0, -half.y), Vector3(-half.x, 0.0, half.y)],
		"e": [Vector3(half.x, 0.0, -half.y), Vector3(half.x, 0.0, half.y)],
	}
	for side: String in sides:
		var a: Vector3 = sides[side][0]
		var b: Vector3 = sides[side][1]
		var length: float = a.distance_to(b)
		var cuts: Array = []
		for opening: Array in openings:
			if opening[0] == side:
				cuts.append([float(opening[1]) + length * 0.5, float(opening[2]) + length * 0.5])
		cuts.sort_custom(func(x: Array, y: Array) -> bool: return x[0] < y[0])
		var start: float = 0.0
		for cut: Array in cuts:
			if cut[0] > start + 0.1:
				rail_on(body, center + a.lerp(b, start / length), center + a.lerp(b, cut[0] / length))
			start = maxf(start, cut[1])
		if length - start > 0.1:
			rail_on(body, center + a.lerp(b, start / length), center + b)


## Rows of "spighe piegate" (chapter 1, section 2): clumps of ochre ears
## all bent about 30 degrees to the west, readable from afar; cards of the
## vegetation kit's kind (101), seen only.
static func ears(parent: Node3D, area: Rect2, y: float, spacing: float = 0.9) -> MultiMeshInstance3D:
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = 1070 + int(area.position.x * 10.0)
	var spots: Array[Transform3D] = []
	var z: float = area.position.y + spacing * 0.5
	while z < area.end.y:
		var x: float = area.position.x + 0.5
		while x < area.end.x:
			var scale: float = random.randf_range(0.7, 0.85)
			spots.append(Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * scale), Vector3(x + random.randf_range(-0.2, 0.2), y, z + random.randf_range(-0.15, 0.15))))
			x += 1.1
		z += spacing
	return cards(parent, EARS_CARD, spots)


## One crossed card of `texture` (a knotted stem to break, 101), not yet
## in the tree, its base on its origin, `scale` times the world size.
static func card_look(texture: Texture2D, scale: float = 1.0) -> MeshInstance3D:
	var size: Vector2 = Vector2(texture.get_width(), texture.get_height()) * WorldScale.METERS_PER_PIXEL * scale
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = CARD_SHADER
	material.set_shader_parameter(&"albedo_texture", texture)
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = GrassCardMesh.build(size)
	instance.material_override = material
	return instance


## The cage of live crops round Pia (section 4, room 6): closed, gold and
## green; centred on `at` in the parent's space.
static func cage(parent: Node3D, at: Vector3) -> Node3D:
	var model: Node3D = CAGE_MODEL.instantiate()
	parent.add_child(model)
	var box: AABB = VehicleKit.bounds(model)
	model.position = at - Vector3(box.get_center().x, box.position.y, box.get_center().z)
	return model


## Kit-style crossed cards of `texture` at `spots` (in the parent's space),
## one MultiMesh, the base of each card on its spot (101).
static func cards(parent: Node3D, texture: Texture2D, spots: Array[Transform3D], cast_shadow: bool = true) -> MultiMeshInstance3D:
	var size: Vector2 = Vector2(texture.get_width(), texture.get_height()) * WorldScale.METERS_PER_PIXEL
	var multimesh: MultiMesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = GrassCardMesh.build(size)
	multimesh.instance_count = spots.size()
	for index: int in spots.size():
		multimesh.set_instance_transform(index, spots[index])
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = CARD_SHADER
	material.set_shader_parameter(&"albedo_texture", texture)
	var instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast_shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)
	return instance


## A fan cabbage (section 2): about 1.5 m, opened like a fan with its
## leaves turned to the sun, so it casts a wide shade eastward. Solid on
## `body` so the sun test of the Specchietti sees it.
static func cabbage_on(body: CollisionObject3D, at: Vector3, height: float = 1.5) -> void:
	var shape: CollisionShape3D = CollisionShape3D.new()
	var cylinder: CylinderShape3D = CylinderShape3D.new()
	cylinder.radius = 0.55
	cylinder.height = height
	shape.shape = cylinder
	shape.position = at + Vector3.UP * height * 0.5
	body.add_child(shape)
	# The fan is flat: turned CABBAGE_YAW from the west, so it takes the
	# low sun and the fixed camera sees it three-quarters, not edge-on.
	var holder: Node3D = Node3D.new()
	body.add_child(holder)
	holder.position = at
	holder.rotation.y = CABBAGE_YAW
	var model: Node3D = CABBAGE_MODEL.instantiate()
	holder.add_child(model)
	var box: AABB = VehicleKit.bounds(model)
	model.scale = Vector3.ONE * (height / maxf(box.size.y, 0.01))
	model.position = -Vector3(box.get_center().x, box.position.y, box.get_center().z) * model.scale


## Frost tubers (section 2): low pale blue-white leaves, only where the
## sun does not reach; `sunny_side` (z, in the parent's space) and beyond
## stays bare.
static func tubers(parent: Node3D, area: Rect2, y: float, sunny_side: float = INF) -> MultiMeshInstance3D:
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = 1078
	var spots: Array[Transform3D] = []
	var x: float = area.position.x + 0.5
	while x < area.end.x:
		var z: float = area.position.y + 0.5
		while z < area.end.y and z < sunny_side:
			var scale: float = random.randf_range(0.8, 1.0)
			spots.append(Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * scale), Vector3(x + random.randf_range(-0.2, 0.2), y, z + random.randf_range(-0.2, 0.2))))
			z += 1.3
		x += 1.3
	return cards(parent, TUBERS_CARD, spots, false)


## Tall straw grass up to Ottavia's waist, seen only (section 3, room 3):
## the tall grass cards of the vegetation kit, thick, with clearings.
static func tall_grass(parent: Node3D, area: Rect2, clearings: Array[Rect2], y: float = 0.0) -> MultiMeshInstance3D:
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = 1073
	var spots: Array[Transform3D] = []
	var x: float = area.position.x + 0.25
	while x < area.end.x:
		var z: float = area.position.y + 0.25
		while z < area.end.y:
			var point: Vector2 = Vector2(x, z) + Vector2(random.randf_range(-0.2, 0.2), random.randf_range(-0.2, 0.2))
			var clear: bool = false
			for clearing: Rect2 in clearings:
				clear = clear or clearing.has_point(point)
			if not clear:
				var scale: float = random.randf_range(0.7, 0.9)
				spots.append(Transform3D(Basis(Vector3.UP, random.randf_range(-0.3, 0.3)).scaled(Vector3.ONE * scale), Vector3(point.x, y, point.y)))
			z += 0.55
		x += 0.55
	return cards(parent, TALL_GRASS_CARD, spots, false)


## A big cart wheel (the Meshy wheel of the field-cart, with its solid
## hub), `radius` metres, its axle along z.
static func wheel(parent: Node3D, at: Vector3, radius: float) -> void:
	var wheel_model: Node3D = FieldCartModel.wheel(parent, radius)
	wheel_model.position += at


static func room(parent: Node3D, id: StringName, center: Vector3, size: Vector3, default_entry: StringName) -> Room:
	var made: Room = Room.new()
	made.room_id = id
	made.size = size
	made.default_entry = default_entry
	made.dungeon = true
	made.name = String(id)
	parent.add_child(made)
	made.global_position = center
	return made


static func entry(parent: Node3D, id: StringName, at: Vector3) -> RoomEntry:
	var made: RoomEntry = RoomEntry.new()
	made.entry_id = id
	made.name = "Entry_" + String(id)
	parent.add_child(made)
	made.global_position = at
	return made


## A passage that works only while `gate` returns true (a ramp that points
## the right way, a bridge that is down). `at` is its centre in the world.
static func exit(parent: Node3D, at: Vector3, size: Vector3, target_room: StringName, target_entry: StringName, gate: Callable = Callable()) -> GatedExit:
	var made: GatedExit = GatedExit.new()
	made.target_room = target_room
	made.target_entry = target_entry
	made.gate = gate
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	made.add_child(shape)
	parent.add_child(made)
	made.global_position = at
	return made


## A person standing, drawn as a sprite (placeholder or approved).
static func person(parent: Node3D, at: Vector3, texture: Texture2D) -> NpcSprite:
	var sprite: NpcSprite = NpcSprite.new()
	sprite.sprite_texture = texture
	parent.add_child(sprite)
	sprite.global_position = at
	return sprite
