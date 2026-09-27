extends SceneTree
## Checks VegetationScatter (101): deterministic placement, spacing, the
## +-20 degree lean rule (100), the ellipse, and one MultiMesh per element
## with models at their size in meters.
## Usage: godot --headless --path . --script res://tests/test_vegetation_scatter.gd

const KIT: String = "res://assets/vegetation_kit/"

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	var scatter: VegetationScatter = VegetationScatter.new()
	scatter.entries = [
		load(KIT + "ciuffo_erba_01.tres") as VegetationEntry,
		load(KIT + "ciuffo_erba_02.tres") as VegetationEntry,
		load(KIT + "cespuglio_01.tres") as VegetationEntry,
		load(KIT + "albero_storto_01.tres") as VegetationEntry,
	]
	scatter.extents = Vector2(4.0, 3.0)
	scatter.density = 6.0
	scatter.random_seed = 5

	var first: Array[Array] = scatter.compute_placements()
	var second: Array[Array] = scatter.compute_placements()
	_check(first.size() > 50, "scatter places instances (got %d)" % first.size())
	_check(first == second, "scatter is deterministic for a seed")

	var inside: bool = true
	var yaw_ok: bool = true
	var spacing_ok: bool = true
	for a: int in first.size():
		var index_a: int = first[a][0]
		var transform_a: Transform3D = first[a][1]
		var spot_a: Vector2 = Vector2(transform_a.origin.x, transform_a.origin.z)
		if Vector2(spot_a.x / scatter.extents.x, spot_a.y / scatter.extents.y).length() > 1.0001:
			inside = false
		var forward: Vector3 = transform_a.basis.z.normalized()
		if absf(rad_to_deg(atan2(forward.x, forward.z))) > scatter.max_yaw_degrees + 0.01:
			yaw_ok = false
		for b: int in range(a + 1, first.size()):
			var transform_b: Transform3D = first[b][1]
			var spot_b: Vector2 = Vector2(transform_b.origin.x, transform_b.origin.z)
			var needed: float = scatter.entries[index_a].footprint_radius + scatter.entries[first[b][0]].footprint_radius
			if spot_a.distance_to(spot_b) < needed - 0.0001:
				spacing_ok = false
	_check(inside, "every instance is inside the ellipse")
	_check(yaw_ok, "every instance turns at most max_yaw_degrees (lean toward the Day kept)")
	_check(spacing_ok, "no two instances closer than their footprints")

	# The root enters the tree after _initialize: the scatter builds on the first frame.
	root.add_child(scatter)
	await process_frame
	var multimeshes: Array[MultiMeshInstance3D] = []
	for child: Node in scatter.get_children(true):
		if child is MultiMeshInstance3D:
			multimeshes.append(child)
	var used: Dictionary = {}
	for placement: Array in scatter.placements:
		used[placement[0]] = true
	_check(not multimeshes.is_empty(), "scatter builds its MultiMesh nodes in the tree")
	_check(multimeshes.size() == used.size(), "one MultiMesh per placed element (%d, %d)" % [multimeshes.size(), used.size()])
	var total: int = 0
	for instance: MultiMeshInstance3D in multimeshes:
		total += instance.multimesh.instance_count
		_check(instance.material_override != null, "scatter MultiMesh has a material")
	_check(total == scatter.placements.size(), "MultiMesh instances match the placements")
	# The crooked tree is 3.6 m tall: the scaling parent written by
	# tools/meshy_pixelize.py must be part of the mesh transform. (The headless
	# renderer does not store MultiMesh transforms, so this checks the source.)
	var tree_mesh: Array = VegetationScatter.load_model_mesh(load("res://assets/models/vegetation/albero_storto_01.glb"))
	var tree_height: float = ((tree_mesh[1] as Transform3D) * (tree_mesh[0] as Mesh).get_aabb()).size.y
	_check(is_equal_approx(snappedf(tree_height, 0.01), 3.6), "tree mesh keeps its size in meters (got %.2f m)" % tree_height)
	scatter.queue_free()

	print("TESTS: scatter %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		print("FAIL: " + message)
