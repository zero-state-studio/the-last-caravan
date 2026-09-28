class_name VehicleKit
extends RefCounted
## Builds the generic caravan vehicles (16) from a kit of modules. A recipe
## names a chassis, the stacks of modules standing on its deck from front
## (west) to back (east), and whether it carries the Generator underneath
## (77), the Wings at the front and the Tails at the back. Modules keep their
## size, so every vehicle has the world pixel density (54).

const MODULE_DIR: String = "res://assets/models/vehicles/moduli/"
const RECIPES_PATH: String = "res://assets/models/vehicles/mezzi_generici.json"
## Modules that face a side: Wings turn their panels west, Tails trail east
## (the Tails model hangs from its bracket at -z and trails toward +z).
const WINGS_ROTATION: float = -PI * 0.5
const TAILS_ROTATION: float = PI * 0.5
const ENGINE_CLEARANCE: float = 0.15
const STACK_GAP: float = 0.2


static func load_recipes() -> Array:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(RECIPES_PATH))
	return parsed if parsed is Array else []


## Front is -x (west), back is +x; the chassis stands on y = 0, centred on
## the origin.
static func build(recipe: Dictionary) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = String(recipe.get("name", "Mezzo"))
	var chassis: Node3D = _module(String(recipe.get("chassis", "pianale_lungo")))
	root.add_child(chassis)
	var box: AABB = bounds(chassis)
	chassis.position = -Vector3(box.get_center().x, box.position.y, box.get_center().z)
	box.position += chassis.position
	var deck_y: float = box.end.y

	# Stacks stand side by side along the deck, as wide as their widest module.
	var stacks: Array = recipe.get("stacks", [])
	var columns: Array[Array] = []
	var widths: PackedFloat32Array = []
	var total: float = 0.0
	for stack: Variant in stacks:
		var column: Array[Node3D] = []
		var width: float = 0.0
		for entry: Variant in stack:
			var module_name: String = String(entry)
			var module: Node3D = _module(module_name.trim_suffix("@180"))
			if module_name.ends_with("@180"):
				module.rotation.y = PI
			root.add_child(module)
			column.append(module)
			width = maxf(width, bounds(module).size.x)
		columns.append(column)
		widths.append(width)
		total += width
	total += STACK_GAP * maxf(0.0, columns.size() - 1)
	var x: float = box.get_center().x - total * 0.5
	for index: int in columns.size():
		var y: float = deck_y
		for module: Node3D in columns[index]:
			y = _place_on(module, Vector3(x + widths[index] * 0.5, y, 0.0)).end.y
		x += widths[index] + STACK_GAP

	if bool(recipe.get("engine", true)):
		var engine: Node3D = _module("generatore")
		engine.name = VehicleWheels.ENGINE_NAME
		root.add_child(engine)
		_place_on(engine, Vector3(0.0, ENGINE_CLEARANCE, 0.0))
	if bool(recipe.get("wings", true)):
		var wings: Node3D = _module("ali")
		wings.rotation.y = WINGS_ROTATION
		root.add_child(wings)
		var wings_box: AABB = bounds(wings)
		_place_on(wings, Vector3(box.position.x - wings_box.size.x * 0.5, 0.0, 0.0))
	if bool(recipe.get("tails", true)):
		var tails: Node3D = _module("code")
		tails.name = VehicleWheels.TAILS_NAME
		tails.rotation.y = TAILS_ROTATION
		root.add_child(tails)
		var tails_box: AABB = bounds(tails)
		_place_on(tails, Vector3(box.end.x + tails_box.size.x * 0.5, 0.0, 0.0))
	return root


## Bounds of a model in its parent's axes, relative to its position (its
## rotation and scale count).
static func bounds(model: Node3D) -> AABB:
	var box: AABB = AABB()
	var first: bool = true
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance: MeshInstance3D = node
		var local: AABB = VegetationScatter.transform_in(model, mesh_instance) * mesh_instance.get_aabb()
		box = local if first else box.merge(local)
		first = false
	box.position -= model.position
	return box


## Puts the model with its base centre on `base`; returns its new bounds.
static func _place_on(model: Node3D, base: Vector3) -> AABB:
	var box: AABB = bounds(model)
	model.position = base - Vector3(box.get_center().x, box.position.y, box.get_center().z)
	box.position += model.position
	return box


static func _module(module_name: String) -> Node3D:
	var scene: PackedScene = load(MODULE_DIR + module_name + ".glb")
	return scene.instantiate()
