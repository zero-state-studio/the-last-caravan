class_name C01Kit
extends RefCounted
## Plain shapes for chapter 1 in its placeholder form (phase 4b step 2):
## boxes, slopes, rails, crops, grass, wheels, rooms, entries and gated
## passages. Everything replaced by the final models in step 4.

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

static var _materials: Dictionary = {}


static func material(color: Color) -> StandardMaterial3D:
	var key: String = color.to_html()
	if not _materials.has(key):
		var made: StandardMaterial3D = StandardMaterial3D.new()
		made.albedo_color = color
		made.roughness = 1.0
		_materials[key] = made
	return _materials[key]


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


## Rows of "spighe piegate" (chapter 1, section 2): ochre stems bent about
## 30 degrees to the west, seen only.
static func ears(parent: Node3D, area: Rect2, y: float, spacing: float = 0.9) -> void:
	var z: float = area.position.y + spacing * 0.5
	while z < area.end.y:
		var x: float = area.position.x + 0.3
		while x < area.end.x:
			visual(parent, Vector3(x, y + 0.45, z), Vector3(0.12, 0.9, 0.12), EAR, Vector3(0.0, 0.0, deg_to_rad(30.0)))
			x += 0.45
		z += spacing


## A fan cabbage (section 2): up to 1.5 m, it casts shade. Solid on `body`
## so the sun test of the Specchietti sees it.
static func cabbage_on(body: CollisionObject3D, at: Vector3, height: float = 1.5) -> void:
	var shape: CollisionShape3D = CollisionShape3D.new()
	var cylinder: CylinderShape3D = CylinderShape3D.new()
	cylinder.radius = 0.45
	cylinder.height = height
	shape.shape = cylinder
	shape.position = at + Vector3.UP * height * 0.5
	body.add_child(shape)
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = 0.7
	mesh.bottom_radius = 0.2
	mesh.height = height
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material(CABBAGE)
	mesh_instance.position = at + Vector3.UP * height * 0.5
	body.add_child(mesh_instance)


## Frost tubers (section 2): low, pale blue-white leaves.
static func tubers(parent: Node3D, area: Rect2, y: float) -> void:
	var x: float = area.position.x + 0.5
	while x < area.end.x:
		var z: float = area.position.y + 0.5
		while z < area.end.y:
			visual(parent, Vector3(x, y + 0.12, z), Vector3(0.5, 0.25, 0.5), TUBER)
			z += 1.3
		x += 1.3


## Tall straw grass up to Ottavia's waist, seen only (section 3, room 3).
static func tall_grass(parent: Node3D, area: Rect2, clearings: Array[Rect2], y: float = 0.0) -> void:
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = 1073
	var x: float = area.position.x + 0.25
	while x < area.end.x:
		var z: float = area.position.y + 0.25
		while z < area.end.y:
			var point: Vector2 = Vector2(x, z)
			var clear: bool = false
			for clearing: Rect2 in clearings:
				clear = clear or clearing.has_point(point)
			if not clear:
				var height: float = random.randf_range(0.8, 1.1)
				visual(parent, Vector3(x + random.randf_range(-0.2, 0.2), y + height * 0.5, z + random.randf_range(-0.2, 0.2)), Vector3(0.08, height, 0.35), DRY_GRASS, Vector3(0.0, random.randf() * PI, deg_to_rad(12.0)))
			z += 0.5
		x += 0.5


static func wheel(parent: Node3D, at: Vector3, radius: float) -> void:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.4
	mesh.radial_segments = 16
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material(WOOD_DARK)
	mesh_instance.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	mesh_instance.position = at
	parent.add_child(mesh_instance)


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
