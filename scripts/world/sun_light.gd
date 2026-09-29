class_name SunLight
extends RefCounted
## Is a point in the sun or in the shade? A ray toward the scene's sun (the
## DirectionalLight3D in the group "sun", or the node named Sun): lit if
## nothing solid is in the way. Used by the creatures that live by the
## light (B32 Specchietto, B38 Frinitore) and turned by the terraces (51).

const RAY_METERS: float = 40.0


static func find_sun(tree: SceneTree) -> DirectionalLight3D:
	var sun: DirectionalLight3D = tree.get_first_node_in_group(&"sun") as DirectionalLight3D
	if sun == null and tree.current_scene != null:
		sun = tree.current_scene.get_node_or_null(^"Sun") as DirectionalLight3D
	return sun


## `exclude` lists the bodies that do not cast shade here (the creature
## itself, Ottavia).
static func is_lit(world_node: Node3D, point: Vector3, exclude: Array[RID] = []) -> bool:
	var sun: DirectionalLight3D = find_sun(world_node.get_tree())
	if sun == null:
		return true
	var toward_sun: Vector3 = sun.global_basis.z.normalized()
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(point, point + toward_sun * RAY_METERS)
	query.exclude = exclude
	return world_node.get_world_3d().direct_space_state.intersect_ray(query).is_empty()
