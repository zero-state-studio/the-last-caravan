class_name ZonePalette
extends Node
## World palette of a zone (51). Every zone scene has one.
## Colors of the environment drift toward white and ochre on the Day side and
## toward blue-violet on the Night side. The drift depends only on world
## position, never on the camera: a base value for the whole zone (how close
## it is to the Night or the Day, see 16) plus a gradient along the world
## west-east axis inside the zone. Characters, creatures and UI never drift.

const MODEL_SHADER: Shader = preload("res://scenes/proto/materials/model_palette.gdshader")

## -1 = at the edge of the Day, 0 = middle of the Twilight, +1 = edge of the Night.
@export_range(-1.0, 1.0, 0.05) var night_proximity: float = 0.0
## World X of the zone center (the gradient is 0 here).
@export var center_x: float = 0.0
## Meters from the center, along world X (east = Night), for a full step of drift.
@export var gradient_width: float = 15.0
## Global multiplier, tuned against the final textures in phase 2.
@export_range(0.0, 2.0, 0.05) var strength: float = 1.0


func _ready() -> void:
	apply()


func apply() -> void:
	RenderingServer.global_shader_parameter_set(&"palette_zone_proximity", night_proximity)
	RenderingServer.global_shader_parameter_set(&"palette_zone_center_x", center_x)
	RenderingServer.global_shader_parameter_set(&"palette_gradient_width", gradient_width)
	RenderingServer.global_shader_parameter_set(&"palette_strength", strength)


## Puts every textured mesh under `root` (imported 3D models of the
## environment) on the palette shader, keeping its albedo texture.
static func retint_models(root: Node) -> void:
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance: MeshInstance3D = node
		for surface: int in mesh_instance.mesh.get_surface_count():
			var original: BaseMaterial3D = mesh_instance.mesh.surface_get_material(surface) as BaseMaterial3D
			if original == null or original.albedo_texture == null:
				continue
			var material: ShaderMaterial = ShaderMaterial.new()
			material.shader = MODEL_SHADER
			material.set_shader_parameter(&"albedo_texture", original.albedo_texture)
			mesh_instance.set_surface_override_material(surface, material)
