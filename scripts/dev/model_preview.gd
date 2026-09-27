extends SceneTree
## Renders a GLB from any path (also outside the project) from four sides and
## prints triangles, bounds and lean direction. Used to check Meshy models
## before spending on textures.
## Usage: godot --path . --resolution 1024x256 --script res://scripts/dev/model_preview.gd -- <model.glb> <out.png>

const VIEWS: Array[Vector3] = [Vector3(0, 0.35, 1), Vector3(1, 0.35, 0), Vector3(0, 0.35, -1), Vector3(0.01, 1, 0.01)]

var _out_path: String = ""
var _frames: int = 0
var _viewports: Array[SubViewport] = []


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var document: GLTFDocument = GLTFDocument.new()
	var state: GLTFState = GLTFState.new()
	if document.append_from_file(args[0], state) != OK:
		printerr("model_preview: cannot read " + args[0])
		quit(2)
		return
	_out_path = args[1]
	var model: Node3D = document.generate_scene(state)
	var bounds: AABB = AABB()
	var triangles: int = 0
	var first: bool = true
	var upper_sum: Vector3 = Vector3.ZERO
	var upper_count: int = 0
	var lower_sum: Vector3 = Vector3.ZERO
	var lower_count: int = 0
	var meshes: Array[Node] = model.find_children("*", "MeshInstance3D", true, false)
	for node: Node in meshes:
		var mesh_instance: MeshInstance3D = node
		# Bounds in model space: the scaling parent written by meshy_pixelize.py counts.
		var to_model: Transform3D = VegetationScatter.transform_in(model, mesh_instance)
		for surface: int in mesh_instance.mesh.get_surface_count():
			var arrays: Array = mesh_instance.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			triangles += (indices.size() if indices.size() > 0 else vertices.size()) / 3
			for local_vertex: Vector3 in vertices:
				var vertex: Vector3 = to_model * local_vertex
				if first:
					bounds = AABB(vertex, Vector3.ZERO)
					first = false
				else:
					bounds = bounds.expand(vertex)
	for node: Node in meshes:
		var mesh_instance: MeshInstance3D = node
		var to_model: Transform3D = VegetationScatter.transform_in(model, mesh_instance)
		for surface: int in mesh_instance.mesh.get_surface_count():
			for local_vertex: Vector3 in mesh_instance.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
				var vertex: Vector3 = to_model * local_vertex
				if vertex.y > bounds.position.y + bounds.size.y * 0.66:
					upper_sum += vertex
					upper_count += 1
				elif vertex.y < bounds.position.y + bounds.size.y * 0.2:
					lower_sum += vertex
					lower_count += 1
	var lean: Vector3 = upper_sum / maxi(1, upper_count) - lower_sum / maxi(1, lower_count)
	print("model_preview: triangles=%d size=%s lean_x=%.2f lean_z=%.2f (x: +east, z: +south)" % [triangles, bounds.size, lean.x, lean.z])

	var center: Vector3 = bounds.get_center()
	var radius: float = bounds.size.length() * 0.9
	var size: Vector2i = Vector2i(256, 256)
	for view: Vector3 in VIEWS:
		var viewport: SubViewport = SubViewport.new()
		viewport.size = size
		viewport.own_world_3d = true
		viewport.transparent_bg = false
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var environment: WorldEnvironment = WorldEnvironment.new()
		environment.environment = Environment.new()
		environment.environment.background_mode = Environment.BG_COLOR
		environment.environment.background_color = Color(0.16, 0.15, 0.2)
		environment.environment.ambient_light_color = Color(0.6, 0.6, 0.7)
		environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		viewport.add_child(environment)
		var light: DirectionalLight3D = DirectionalLight3D.new()
		light.rotation_degrees = Vector3(-40, -60, 0)
		viewport.add_child(light)
		var copy: Node3D = model.duplicate() as Node3D
		viewport.add_child(copy)
		var camera: Camera3D = Camera3D.new()
		viewport.add_child(camera)
		camera.look_at_from_position(center + view.normalized() * radius, center, Vector3.FORWARD if view.y > 0.9 else Vector3.UP)
		_viewports.append(viewport)
	model.free()


func _process(_delta: float) -> bool:
	if _out_path.is_empty():
		return false
	_frames += 1
	if _frames < 5:
		return false
	var sheet: Image = Image.create(256 * _viewports.size(), 256, false, Image.FORMAT_RGBA8)
	for index: int in _viewports.size():
		var image: Image = _viewports[index].get_texture().get_image()
		image.convert(Image.FORMAT_RGBA8)
		sheet.blit_rect(image, Rect2i(0, 0, 256, 256), Vector2i(index * 256, 0))
	sheet.save_png(_out_path)
	print("model_preview: saved " + _out_path)
	return true
