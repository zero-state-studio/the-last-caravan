// Imported environment models (54) with the world palette drift (51) and
// the foreground see-through around Ottavia (53).
shader_type spatial;
render_mode diffuse_burley, specular_disabled;

#include "res://scenes/proto/materials/world_palette.gdshaderinc"
#include "res://scenes/proto/materials/foreground_fade.gdshaderinc"

uniform sampler2D albedo_texture : source_color, filter_nearest, hint_default_white;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Shadows stay whole: only the camera view gets the see-through.
	if (!IN_SHADOW_PASS && foreground_dithered(foreground_fade(VERTEX, VIEW_MATRIX, PROJECTION_MATRIX), UV, textureSize(albedo_texture, 0))) {
		discard;
	}
	ALBEDO = apply_world_palette(texture(albedo_texture, UV).rgb, world_position);
	ROUGHNESS = 1.0;
}
