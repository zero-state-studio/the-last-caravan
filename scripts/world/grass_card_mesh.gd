class_name GrassCardMesh
extends RefCounted
## Crossed-plane mesh for grass tufts and small plants (101).
## Quads are turned by +-45 degrees around Y with their front faces toward
## the fixed camera, so art drawn leaning left still leans west (toward the
## Day, 100) on both planes. Normals point up and toward the camera: the
## tuft is lit evenly instead of going dark on one plane.


## Builds a mesh of `plane_count` crossed quads, `size` meters wide and tall,
## with the base at y = 0.
static func build(size: Vector2, plane_count: int = 2) -> ArrayMesh:
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_normal(Vector3(0.0, 0.6, 0.8))
	var half: float = size.x * 0.5
	for index: int in plane_count:
		# Spread the planes over 90 degrees, centred on the camera direction.
		var angle: float = deg_to_rad(-45.0 + 90.0 * float(index) / maxf(1.0, float(plane_count - 1)))
		var right: Vector3 = Vector3(cos(angle), 0.0, -sin(angle)) * half
		var up: Vector3 = Vector3.UP * size.y
		var corners: Array[Vector3] = [-right, right, right + up, -right + up]
		var uvs: Array[Vector2] = [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
		# Clockwise as seen from the camera: Godot 4 front faces.
		for triangle: Array[int] in [[0, 2, 1], [0, 3, 2]] as Array[Array]:
			for corner: int in triangle:
				surface.set_uv(uvs[corner])
				surface.add_vertex(corners[corner])
	return surface.commit()
