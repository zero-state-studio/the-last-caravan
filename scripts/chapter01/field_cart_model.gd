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
const WHEEL_X: Array[float] = [-8.5, 0.0, 8.5]
const SLAB: float = 0.4


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
			var wheel: Node3D = WHEEL.instantiate()
			root.add_child(wheel)
			# The wheel taken out of the test model has one side only.
			_double_sided(wheel)
			if side < 0.0:
				wheel.rotation.y = PI
			var box: AABB = VehicleKit.bounds(wheel)
			wheel.position = Vector3(x, 0.0, side * (WIDTH * 0.5 + 0.1)) - Vector3(box.get_center().x, box.position.y, box.get_center().z)
	var lever: Node3D = LEVER.instantiate()
	root.add_child(lever)
	VehicleKit.place_on(lever, Vector3(-LENGTH * 0.5 + 1.2, DECK_TOP, WIDTH * 0.5 - 1.2))
	# The small Wings in front, the Tails behind, the ice tanks at the ends.
	var wings: Node3D = VehicleKit.module("ali")
	wings.rotation.y = VehicleKit.WINGS_ROTATION
	root.add_child(wings)
	var wings_box: AABB = VehicleKit.bounds(wings)
	VehicleKit.place_on(wings, Vector3(-LENGTH * 0.5 - wings_box.size.x * 0.5, 0.0, 0.0))
	var tails: Node3D = VehicleKit.module("code")
	tails.name = VehicleWheels.TAILS_NAME
	tails.rotation.y = VehicleKit.TAILS_ROTATION
	root.add_child(tails)
	var tails_box: AABB = VehicleKit.bounds(tails)
	VehicleKit.place_on(tails, Vector3(LENGTH * 0.5 + tails_box.size.x * 0.5, 0.0, 0.0))
	for z: float in [-WIDTH * 0.5 + 1.4, WIDTH * 0.5 - 1.4]:
		var tank: Node3D = VehicleKit.module("serbatoio")
		root.add_child(tank)
		VehicleKit.place_on(tank, Vector3(LENGTH * 0.5 - 1.0, DECK_TOP, z))
	return root


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
