class_name VehicleWheels
extends Node3D
## Makes a caravan vehicle (16) look driven: its wheels roll with the ground
## it covers, the body rocks a little on them, and the Generator beats like
## a heart (77) while the vehicle moves.
## The Meshy models come as one mesh, but every wheel is a separate island
## of geometry: `attach` cuts the low, round, thin islands out into their
## own nodes, pivoted on their centre. The cut is cached per mesh.

## Node name of the Generator module (VehicleKit), which beats.
const ENGINE_NAME: StringName = &"Generatore"
const BEAT_HZ: float = 1.4
const BEAT_AMOUNT: float = 0.03
## The body rises and falls this much, in metres, once per wheel turn half.
const BOB_METERS: float = 0.05
## Below this many metres per second the vehicle counts as still.
const STILL_SPEED: float = 0.05

static var _cache: Dictionary = {}

## Each wheel: {"node", "axis" (local), "radius" (metres)}.
var wheels: Array[Dictionary] = []
var _bodies: Array[Node3D] = []
var _body_rest: Array[Vector3] = []
var _body_up: Array[Vector3] = []
var _engines: Array[Node3D] = []
var _engine_rest: Array[Vector3] = []
var _root: Node3D
var _last_position: Vector3
var _time: float = 0.0
var _travel: float = 0.0
var _motion: float = 0.0


## Cuts the wheels out of every mesh under `root` and adds the animator as a
## child of `root`. Call it before the root enters the tree or after, but
## before palettes retint the meshes (the wheels keep the source material).
static func attach(root: Node3D) -> VehicleWheels:
	var animator: VehicleWheels = VehicleWheels.new()
	animator.name = "VehicleWheels"
	var instances: Array[Node] = root.find_children("*", "MeshInstance3D", true, false)
	if root is MeshInstance3D:
		instances.append(root)
	for node: Node in instances:
		animator._cut_wheels(node as MeshInstance3D)
		animator._bodies.append(node as Node3D)
	for node: Node in root.find_children(ENGINE_NAME, "Node3D", true, false):
		animator._engines.append(node as Node3D)
	root.add_child(animator)
	return animator


func _ready() -> void:
	_root = get_parent() as Node3D
	_last_position = _root.global_position
	# Radii in metres are known once the vehicle is in the tree.
	for wheel: Dictionary in wheels:
		wheel["radius"] = float(wheel["local_radius"]) * (wheel["node"] as Node3D).global_basis.get_scale().y
	wheels = wheels.filter(func(wheel: Dictionary) -> bool: return float(wheel["radius"]) > 0.01)
	for body: Node3D in _bodies:
		_body_rest.append(body.position)
		# One world metre up, in the body's parent axes.
		var parent_basis: Basis = (body.get_parent() as Node3D).global_basis
		_body_up.append(parent_basis.inverse() * Vector3.UP)
	for engine: Node3D in _engines:
		_engine_rest.append(engine.scale)


func _physics_process(delta: float) -> void:
	var now: Vector3 = _root.global_position
	var moved: Vector3 = now - _last_position
	_last_position = now
	moved.y = 0.0
	for wheel: Dictionary in wheels:
		var node: Node3D = wheel["node"]
		var axis: Vector3 = (node.global_basis * (wheel["axis"] as Vector3)).normalized()
		# Rolling without slipping: the contact point stays on the ground.
		var forward: Vector3 = axis.cross(Vector3.UP)
		if forward.length_squared() > 0.01:
			node.rotate_object_local(wheel["axis"], moved.dot(forward) / forward.length_squared() / float(wheel["radius"]))
	# Eased amount of motion, so the rocking and the beat fade in and out.
	var speed: float = moved.length() / maxf(delta, 0.0001)
	_motion = move_toward(_motion, 1.0 if speed > STILL_SPEED else 0.0, delta * 1.5)
	if _motion <= 0.0 and _time == 0.0:
		return
	_time += delta
	_travel += moved.length()
	var bob: float = absf(sin(_travel * 1.3)) * BOB_METERS * _motion
	for index: int in _bodies.size():
		_bodies[index].position = _body_rest[index] + _body_up[index] * bob
	# The Generator beats even more when the vehicle pulls: a quick swell.
	var beat: float = pow(maxf(0.0, sin(_time * TAU * BEAT_HZ)), 6.0) * BEAT_AMOUNT * _motion
	for index: int in _engines.size():
		_engines[index].scale = _engine_rest[index] * (1.0 + beat)
	if _motion <= 0.0:
		_time = 0.0


func _cut_wheels(instance: MeshInstance3D) -> void:
	var mesh: Mesh = instance.mesh
	if mesh == null:
		return
	if not _cache.has(mesh):
		_cache[mesh] = split_wheels(mesh)
	var cut: Dictionary = _cache[mesh]
	if (cut["wheels"] as Array).is_empty():
		return
	instance.mesh = cut["body"]
	# The wheels hang from the instance's parent, not from the instance, so
	# they stay on the ground while the body rocks.
	var parent: Node3D = instance.get_parent() as Node3D
	for wheel: Dictionary in cut["wheels"]:
		var pivot: Node3D = Node3D.new()
		pivot.name = "WheelPivot"
		pivot.transform = instance.transform * Transform3D(Basis.IDENTITY, wheel["center"])
		var node: MeshInstance3D = MeshInstance3D.new()
		node.name = "Wheel"
		node.mesh = wheel["mesh"]
		pivot.add_child(node)
		if parent != null:
			parent.add_child(pivot)
		else:
			instance.add_child(pivot)
			pivot.transform = Transform3D(Basis.IDENTITY, wheel["center"])
		wheels.append({"node": node, "axis": wheel["axis"], "radius": 0.0, "local_radius": wheel["radius"]})


## Splits `mesh` (first surface) into a body and wheels: islands of
## triangles connected by shared positions, kept as wheels when they sit at
## the bottom, are round seen along one horizontal axis and thin along it.
static func split_wheels(mesh: Mesh) -> Dictionary:
	var result: Dictionary = {"body": mesh, "wheels": []}
	if mesh.get_surface_count() != 1:
		return result
	var arrays: Array = mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	if indices.is_empty():
		indices.resize(vertices.size())
		for index: int in vertices.size():
			indices[index] = index
	# Union-find over vertices; the UV seams split vertices that share a
	# position, so those are joined first.
	var parent: PackedInt32Array = []
	parent.resize(vertices.size())
	var by_position: Dictionary = {}
	for index: int in vertices.size():
		var key: Vector3i = Vector3i((vertices[index] * 10000.0).round())
		parent[index] = by_position.get(key, index)
		if not by_position.has(key):
			by_position[key] = index
	for face: int in range(0, indices.size(), 3):
		var a: int = _find(parent, indices[face])
		for corner: int in [1, 2]:
			var b: int = _find(parent, indices[face + corner])
			if a != b:
				parent[b] = a
	var groups: Dictionary = {}
	for face: int in range(0, indices.size(), 3):
		var group: int = _find(parent, indices[face])
		if not groups.has(group):
			groups[group] = []
		(groups[group] as Array).append(face)
	var bounds: AABB = AABB(vertices[0], Vector3.ZERO)
	for vertex: Vector3 in vertices:
		bounds = bounds.expand(vertex)
	var height: float = bounds.size.y
	var is_wheel: Dictionary = {}
	var found: Array[Dictionary] = []
	for faces: Array in groups.values():
		if faces.size() < 20:
			continue
		var box: AABB = AABB(vertices[indices[faces[0]]], Vector3.ZERO)
		for face: int in faces:
			for corner: int in 3:
				box = box.expand(vertices[indices[face + corner]])
		var size: Vector3 = box.size
		var axis: Vector3 = Vector3.ZERO
		if absf(size.x - size.y) < size.y * 0.25 and size.z < size.y * 0.6:
			axis = Vector3.BACK
		elif absf(size.z - size.y) < size.y * 0.25 and size.x < size.y * 0.6:
			axis = Vector3.RIGHT
		var low: bool = box.position.y < bounds.position.y + height * 0.08
		if low and size.y > height * 0.1 and axis != Vector3.ZERO:
			for face: int in faces:
				is_wheel[face] = true
			found.append({"faces": faces, "center": box.get_center(), "axis": axis, "radius": size.y * 0.5})
	if found.is_empty():
		return result
	var body_faces: Array = []
	for face: int in range(0, indices.size(), 3):
		if not is_wheel.has(face):
			body_faces.append(face)
	var material: Material = mesh.surface_get_material(0)
	result["body"] = _build(arrays, indices, body_faces, Vector3.ZERO, material)
	var list: Array[Dictionary] = []
	for wheel: Dictionary in found:
		list.append({"mesh": _build(arrays, indices, wheel["faces"], wheel["center"], material), "center": wheel["center"], "axis": wheel["axis"], "radius": wheel["radius"]})
	result["wheels"] = list
	return result


static func _find(parent: PackedInt32Array, index: int) -> int:
	while parent[index] != index:
		parent[index] = parent[parent[index]]
		index = parent[index]
	return index


## A mesh made of some faces of the source, moved by -offset.
static func _build(arrays: Array, indices: PackedInt32Array, faces: Array, offset: Vector3, material: Material) -> ArrayMesh:
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL] if arrays[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV] if arrays[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
	var out_vertices: PackedVector3Array = []
	var out_normals: PackedVector3Array = []
	var out_uvs: PackedVector2Array = []
	for face: int in faces:
		for corner: int in 3:
			var index: int = indices[face + corner]
			out_vertices.append(vertices[index] - offset)
			if not normals.is_empty():
				out_normals.append(normals[index])
			if not uvs.is_empty():
				out_uvs.append(uvs[index])
	var out: Array = []
	out.resize(Mesh.ARRAY_MAX)
	out[Mesh.ARRAY_VERTEX] = out_vertices
	if not out_normals.is_empty():
		out[Mesh.ARRAY_NORMAL] = out_normals
	if not out_uvs.is_empty():
		out[Mesh.ARRAY_TEX_UV] = out_uvs
	var result: ArrayMesh = ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, out)
	result.surface_set_material(0, material)
	return result
