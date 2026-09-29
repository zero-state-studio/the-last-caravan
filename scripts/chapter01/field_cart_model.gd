class_name FieldCartModel
extends RefCounted
## The field-cart of chapter 1 (123, 107), built in Godot at the sizes of
## the document: a deck 24 m long and 10 m wide of old sun-baked planks,
## three pairs of big wheels and the lever with its gears taken from the
## Meshy test model, the small Wings at the front (west), the Tails at the
## back (east) and the ice tanks, like every vehicle (122); on top the
## rectangular terraces of soil. All the flat surfaces use tiled textures at
## the world density, 30 px per metre (49, 54).

const LENGTH: float = 24.0
const WIDTH: float = 10.0
const DECK_TOP: float = 1.6
const DECK_THICKNESS: float = 0.5
const WHEEL: PackedScene = preload("res://assets/models/capitolo01/ruota_carro_campo.glb")
const LEVER: PackedScene = preload("res://assets/models/capitolo01/leva_carro_campo.glb")
const WOOD: Texture2D = preload("res://assets/textures/capitolo01/legno_carro.png")
const SOIL: Texture2D = preload("res://assets/textures/capitolo01/terra_terrazze.png")
const METAL: Texture2D = preload("res://assets/textures/capitolo01/metallo_generatore.png")
const HUB_TINT: Color = Color(0.62, 0.5, 0.4)
const IRON_TINT: Color = Color(0.45, 0.42, 0.44)
const FROST: Texture2D = preload("res://assets/textures/terrain/frost_ground.png")
const WHEEL_X: Array[float] = [-8.5, 0.0, 8.5]
const WHEEL_RADIUS: float = 1.4
const SLAB: float = 0.4
## The solid wooden hub in the middle of each wheel, as a share of its radius.
const HUB_SHARE: float = 0.3
## The Tails crawl this far behind the cart, in the frost (16, 77).
const TAIL_STRETCH: float = 3.2
const TAIL_Z: Array[float] = [-3.0, 0.2, 3.2]
const FROST_LUMPS: int = 9
const ICE_COLOR: Color = Color(0.86, 0.94, 1.0)
const ICE_GLOW: Color = Color(0.55, 0.72, 0.95)


## The cart, centred on the origin with its wheels on y = 0, front to -x.
static func build() -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "CarroCampo"
	var wood: ShaderMaterial = LevelBlocks.material(WOOD)
	LevelBlocks.box(root, Vector3(0.0, DECK_TOP - DECK_THICKNESS * 0.5, 0.0), Vector3(LENGTH, DECK_THICKNESS, WIDTH), wood, false)
	# Two long beams under the deck, where the axles hang.
	for z: float in [-WIDTH * 0.35, WIDTH * 0.35]:
		LevelBlocks.box(root, Vector3(0.0, DECK_TOP - DECK_THICKNESS - 0.2, z), Vector3(LENGTH - 1.0, 0.4, 0.6), wood, false)
	for x: float in WHEEL_X:
		for side: float in [-1.0, 1.0]:
			var wheel_node: Node3D = wheel(root, WHEEL_RADIUS, side < 0.0)
			wheel_node.position = Vector3(x, WHEEL_RADIUS, side * (WIDTH * 0.5 + 0.1))
	var lever: Node3D = LEVER.instantiate()
	root.add_child(lever)
	VehicleKit.place_on(lever, Vector3(-LENGTH * 0.5 + 1.2, DECK_TOP, WIDTH * 0.5 - 1.2))
	# The small Wings in front, the Tails behind, the ice tanks at the ends.
	var wings: Node3D = VehicleKit.module("ali")
	wings.rotation.y = VehicleKit.WINGS_ROTATION
	root.add_child(wings)
	var wings_box: AABB = VehicleKit.bounds(wings)
	VehicleKit.place_on(wings, Vector3(-LENGTH * 0.5 - wings_box.size.x * 0.5, 0.0, 0.0))
	_tails(root)
	for z: float in [-WIDTH * 0.5 + 1.4, WIDTH * 0.5 - 1.4]:
		var tank: Node3D = VehicleKit.module("serbatoio")
		root.add_child(tank)
		VehicleKit.place_on(tank, Vector3(LENGTH * 0.5 - 1.0, DECK_TOP, z))
	return root


## One big wheel of `radius` metres centred on the returned node, its axle
## along z, the outer face toward +z (toward -z with `inner_face_south`): the
## Meshy wheel with a solid wooden hub where the spokes meet and an iron
## band round the hub.
static func wheel(parent: Node3D, radius: float, inner_face_south: bool = false) -> Node3D:
	var holder: Node3D = Node3D.new()
	holder.name = "Wheel"
	parent.add_child(holder)
	var model: Node3D = WHEEL.instantiate()
	holder.add_child(model)
	# The wheel taken out of the test model has one side only.
	_double_sided(model)
	var box: AABB = VehicleKit.bounds(model)
	var scale: float = radius / (box.size.y * 0.5)
	model.scale = Vector3.ONE * scale
	model.position = -box.get_center() * scale
	var thickness: float = box.size.z * scale
	if inner_face_south:
		holder.rotation.y = PI
	# The hubs darker than the deck, end grain worn by the axle.
	var hub_wood: ShaderMaterial = LevelBlocks.material(WOOD, WOOD, HUB_TINT)
	var iron: ShaderMaterial = LevelBlocks.material(METAL, METAL, IRON_TINT)
	var hub: Node3D = LevelBlocks.cylinder(holder, Vector3.ZERO, radius * HUB_SHARE, thickness + 0.5 * scale, hub_wood)
	hub.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	var band: Node3D = LevelBlocks.cylinder(holder, Vector3(0.0, 0.0, thickness * 0.5 + 0.08 * scale), radius * HUB_SHARE + 0.06 * scale, 0.14 * scale, iron)
	band.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	return holder


## Three long Tails crawling on the ground to the east, behind the cart,
## with frost caught on their tips as on the prologue vehicles (16).
static func _tails(root: Node3D) -> void:
	var frost: StandardMaterial3D = StandardMaterial3D.new()
	frost.albedo_texture = FROST
	frost.albedo_color = ICE_COLOR
	frost.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	frost.uv1_triplanar = true
	frost.uv1_scale = Vector3.ONE * 0.5
	frost.roughness = 0.35
	frost.emission_enabled = true
	frost.emission = ICE_GLOW
	frost.emission_energy_multiplier = 0.35
	var group: Node3D = Node3D.new()
	group.name = VehicleWheels.TAILS_NAME
	root.add_child(group)
	for index: int in TAIL_Z.size():
		var tail: Node3D = VehicleKit.module("code")
		tail.rotation.y = VehicleKit.TAILS_ROTATION + (float(index) - 1.0) * 0.12
		# Longer along the crawl, lower to the ground.
		tail.scale = Vector3(1.0, 0.7, TAIL_STRETCH)
		group.add_child(tail)
		var box: AABB = VehicleKit.bounds(tail)
		VehicleKit.place_on(tail, Vector3(LENGTH * 0.5 + box.size.x * 0.5 - 0.4, 0.0, TAIL_Z[index]))
		box = VehicleKit.bounds(tail)
		box.position += tail.position
		# Small lumps of frost on the ends, thicker at the very tip.
		var random: RandomNumberGenerator = RandomNumberGenerator.new()
		random.seed = 71 + index
		for lump: int in FROST_LUMPS:
			var along: float = box.end.x - 0.2 - random.randf() * 1.8 * (float(lump) / FROST_LUMPS)
			var spot: Vector3 = Vector3(along, 0.0, box.get_center().z + random.randf_range(-0.55, 0.55))
			var size: Vector3 = Vector3(random.randf_range(0.2, 0.5), random.randf_range(0.1, 0.3), random.randf_range(0.2, 0.4))
			LevelBlocks.box(root, spot + Vector3(0.0, size.y * 0.5, 0.0), size, frost, false).rotation.y = random.randf() * TAU


static func _double_sided(model: Node) -> void:
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance: MeshInstance3D = node
		for surface: int in mesh_instance.mesh.get_surface_count():
			var material: BaseMaterial3D = mesh_instance.mesh.surface_get_material(surface) as BaseMaterial3D
			if material != null:
				var copy: BaseMaterial3D = material.duplicate() as BaseMaterial3D
				copy.cull_mode = BaseMaterial3D.CULL_DISABLED
				mesh_instance.set_surface_override_material(surface, copy)


## A rectangular terrace of soil on the deck: `size` (x, z), its top at
## `top` metres; the sides in the cart's wood.
static func terrace(parent: Node3D, center: Vector3, size: Vector2, top: float) -> Node3D:
	var soil: ShaderMaterial = LevelBlocks.material(SOIL, WOOD)
	return LevelBlocks.box(parent, Vector3(center.x, top - SLAB * 0.5, center.z), Vector3(size.x, SLAB, size.y), soil, false)
