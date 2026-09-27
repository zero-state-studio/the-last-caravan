@tool
class_name VegetationScatter
extends Node3D
## Spreads elements of the vegetation kit (101) over an elliptical patch,
## one MultiMesh per element. Plants keep their lean toward the Day (west,
## 100): random turns stay within +-max_yaw_degrees around the vertical axis.
## Instances sit on the node's own XZ plane: put one scatter per ground level.

const CARD_SHADER: Shader = preload("res://scenes/proto/materials/foreground_fade.gdshader")
## Fraction of the radius where instances start to thin out toward the rim.
const EDGE_FADE_START: float = 0.55
## Placement tries per wanted instance before giving up (dense patches).
const TRIES_PER_INSTANCE: int = 20

@export var entries: Array[VegetationEntry] = []:
	set(value):
		entries = value
		_rebuild()
## Radii of the ellipse, in meters (x, z).
@export var extents: Vector2 = Vector2(2.0, 2.0):
	set(value):
		extents = value
		_rebuild()
## Wanted instances per square meter, before the rim thinning and spacing.
@export var density: float = 4.0:
	set(value):
		density = value
		_rebuild()
@export var max_yaw_degrees: float = 20.0:
	set(value):
		max_yaw_degrees = value
		_rebuild()
@export var random_seed: int = 1:
	set(value):
		random_seed = value
		_rebuild()

## Placed instances as [entry index, Transform3D], for tests and tools.
var placements: Array[Array] = []


func _ready() -> void:
	_rebuild()


## Chooses the instance transforms. Deterministic for a given seed.
func compute_placements() -> Array[Array]:
	var result: Array[Array] = []
	var usable: Array[int] = []
	var total_weight: float = 0.0
	var largest_radius: float = 0.01
	for index: int in entries.size():
		var entry: VegetationEntry = entries[index]
		if entry != null and entry.weight > 0.0 and (entry.model != null or entry.card_texture != null):
			usable.append(index)
			total_weight += entry.weight
			largest_radius = maxf(largest_radius, entry.footprint_radius)
	if usable.is_empty():
		return result
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = random_seed
	var wanted: int = roundi(density * PI * extents.x * extents.y)
	# Spatial hash of accepted spots: cells as large as two of the biggest
	# footprints, so a spacing check only looks at the 3x3 cells around.
	var cell_size: float = largest_radius * 2.0
	var grid: Dictionary = {}
	var tries: int = 0
	while result.size() < wanted and tries < wanted * TRIES_PER_INSTANCE:
		tries += 1
		var spot: Vector2 = _random_spot(random) * extents
		var index: int = _pick(usable, total_weight, random)
		var radius: float = entries[index].footprint_radius
		var cell: Vector2i = Vector2i(floori(spot.x / cell_size), floori(spot.y / cell_size))
		if not _is_free(grid, cell, spot, radius):
			continue
		if not grid.has(cell):
			grid[cell] = []
		(grid[cell] as Array).append(Vector3(spot.x, spot.y, radius))
		var yaw: float = deg_to_rad(random.randf_range(-max_yaw_degrees, max_yaw_degrees))
		var range_: Vector2 = entries[index].scale_range
		var basis: Basis = Basis(Vector3.UP, yaw).scaled(Vector3.ONE * random.randf_range(range_.x, range_.y))
		result.append([index, Transform3D(basis, Vector3(spot.x, 0.0, spot.y))])
	return result


func _rebuild() -> void:
	if not is_inside_tree():
		return
	for child: Node in get_children(true):
		if child is MultiMeshInstance3D and child.get_meta(&"vegetation_scatter", false):
			remove_child(child)
			child.queue_free()
	placements = compute_placements()
	for index: int in entries.size():
		var transforms: Array[Transform3D] = []
		for placement: Array in placements:
			if placement[0] == index:
				transforms.append(placement[1])
		if not transforms.is_empty():
			_add_multimesh(entries[index], transforms)


func _add_multimesh(entry: VegetationEntry, transforms: Array[Transform3D]) -> void:
	var mesh: Mesh
	var mesh_transform: Transform3D = Transform3D.IDENTITY
	var material: Material
	if entry.model != null:
		var model_mesh: Array = load_model_mesh(entry.model)
		if model_mesh.is_empty():
			push_warning("VegetationScatter: no mesh in %s" % entry.model.resource_path)
			return
		mesh = model_mesh[0]
		mesh_transform = model_mesh[1]
		material = ZonePalette.palette_material(mesh.surface_get_material(0))
	else:
		var size: Vector2 = Vector2(entry.card_texture.get_width(), entry.card_texture.get_height()) * WorldScale.METERS_PER_PIXEL
		mesh = GrassCardMesh.build(size)
		var card_material: ShaderMaterial = ShaderMaterial.new()
		card_material.shader = CARD_SHADER
		card_material.set_shader_parameter(&"albedo_texture", entry.card_texture)
		material = card_material
	var multimesh: MultiMesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for index: int in transforms.size():
		multimesh.set_instance_transform(index, transforms[index] * mesh_transform)
	var instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if entry.cast_shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.set_meta(&"vegetation_scatter", true)
	# Internal child: rebuilt on load, never saved into the scene file.
	add_child(instance, false, Node.INTERNAL_MODE_BACK)


## The first mesh of an imported model and its transform inside the model
## scene, as [Mesh, Transform3D]; empty when the model has no mesh.
static func load_model_mesh(model: PackedScene) -> Array:
	var root: Node3D = model.instantiate() as Node3D
	var found: Array[Node] = root.find_children("*", "MeshInstance3D", true, false)
	var result: Array = []
	if not found.is_empty():
		var mesh_instance: MeshInstance3D = found[0]
		result = [mesh_instance.mesh, transform_in(root, mesh_instance)]
	root.free()
	return result


## Transform of `node` relative to `root`, including the root's own one
## (the scaling parent written by tools/meshy_pixelize.py sits in between).
static func transform_in(root: Node3D, node: Node3D) -> Transform3D:
	var result: Transform3D = node.transform
	var parent: Node = node.get_parent()
	while parent != null and parent != root:
		result = (parent as Node3D).transform * result
		parent = parent.get_parent()
	return root.transform * result


func _pick(usable: Array[int], total_weight: float, random: RandomNumberGenerator) -> int:
	var roll: float = random.randf() * total_weight
	for index: int in usable:
		roll -= entries[index].weight
		if roll <= 0.0:
			return index
	return usable[usable.size() - 1]


static func _is_free(grid: Dictionary, cell: Vector2i, spot: Vector2, radius: float) -> bool:
	for dx: int in range(-1, 2):
		for dy: int in range(-1, 2):
			for other: Vector3 in grid.get(cell + Vector2i(dx, dy), []):
				if spot.distance_to(Vector2(other.x, other.y)) < radius + other.z:
					return false
	return true


## A point in the unit disk, thinning out toward the rim so the patch has a
## soft, irregular edge instead of a hard outline.
static func _random_spot(random: RandomNumberGenerator) -> Vector2:
	while true:
		var spot: Vector2 = Vector2(random.randf_range(-1.0, 1.0), random.randf_range(-1.0, 1.0))
		var radius: float = spot.length()
		if radius <= 1.0 and random.randf() > smoothstep(EDGE_FADE_START, 1.0, radius):
			return spot
	return Vector2.ZERO
