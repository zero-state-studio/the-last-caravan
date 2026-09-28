class_name LevelBlocks
extends RefCounted
## Small helpers to build level geometry from boxes and cylinders with the
## triplanar pixel-art material (texel density from world_texels_per_meter,
## 54) and optional collision.

const TRIPLANAR: Shader = preload("res://scenes/proto/materials/terrain_triplanar.gdshader")

static var _materials: Dictionary = {}


## Triplanar material with one texture on top and one on the sides; cached.
static func material(top: Texture2D, side: Texture2D = null, tint: Color = Color.WHITE) -> ShaderMaterial:
	var key: String = "%s|%s|%s" % [top.resource_path, side.resource_path if side != null else "", tint.to_html()]
	if _materials.has(key):
		return _materials[key]
	var result: ShaderMaterial = ShaderMaterial.new()
	result.shader = TRIPLANAR
	result.set_shader_parameter(&"top_texture", top)
	result.set_shader_parameter(&"side_texture", side if side != null else top)
	result.set_shader_parameter(&"top_tint", tint)
	result.set_shader_parameter(&"side_tint", tint)
	result.set_shader_parameter(&"top_threshold", 0.7)
	_materials[key] = result
	return result


## Makes a model (rock, trunk, ruin) block movement: a box the size of its
## meshes, a little narrower (`shrink`) so the edges do not catch from afar.
static func make_solid(model: Node3D, shrink: float = 0.8) -> void:
	var box: AABB = AABB()
	var first: bool = true
	var to_local: Transform3D = model.transform.affine_inverse()
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance: MeshInstance3D = node
		var local: AABB = (to_local * VegetationScatter.transform_in(model, mesh_instance)) * mesh_instance.get_aabb()
		box = local if first else box.merge(local)
		first = false
	if first or box.size.y < 0.2:
		return
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(box.size.x * shrink, box.size.y, box.size.z * shrink)
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.shape = shape
	collision.position = box.get_center()
	var body: StaticBody3D = StaticBody3D.new()
	body.name = "Solid"
	body.add_child(collision)
	model.add_child(body)


## A box centred on `center`; with `solid` it also blocks movement.
static func box(parent: Node3D, center: Vector3, size: Vector3, mat: Material, solid: bool = true) -> Node3D:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	return _add(parent, center, mesh, mat, BoxShape3D.new() if solid else null, size)


## An upright cylinder (or lying along x with `lying`).
static func cylinder(parent: Node3D, center: Vector3, radius: float, height: float, mat: Material, lying: bool = false, solid: bool = false) -> Node3D:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	var node: Node3D = _add(parent, center, mesh, mat, null, Vector3.ZERO)
	if lying:
		node.rotation.z = PI * 0.5
	if solid:
		var body: StaticBody3D = StaticBody3D.new()
		var shape: CollisionShape3D = CollisionShape3D.new()
		var cylinder_shape: CylinderShape3D = CylinderShape3D.new()
		cylinder_shape.radius = radius
		cylinder_shape.height = height
		shape.shape = cylinder_shape
		body.add_child(shape)
		node.add_child(body)
	return node


static func _add(parent: Node3D, center: Vector3, mesh: Mesh, mat: Material, shape: BoxShape3D, size: Vector3) -> Node3D:
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = mat
	instance.position = center
	parent.add_child(instance)
	if shape != null:
		shape.size = size
		var body: StaticBody3D = StaticBody3D.new()
		var collision: CollisionShape3D = CollisionShape3D.new()
		collision.shape = shape
		body.add_child(collision)
		instance.add_child(body)
	return instance
