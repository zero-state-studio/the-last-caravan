// Foreground vegetation cards that thin out around Ottavia (53), see
// foreground_fade.gdshaderinc.
shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_disabled;

#include "res://scenes/proto/materials/world_palette.gdshaderinc"
#include "res://scenes/proto/materials/foreground_fade.gdshaderinc"

uniform sampler2D albedo_texture : source_color, filter_nearest, hint_default_white;
uniform vec4 tint : source_color = vec4(1.0);

void fragment() {
	vec4 texel = texture(albedo_texture, UV);
	vec3 world_position = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	ALBEDO = apply_world_palette(texel.rgb * tint.rgb, world_position);
	ROUGHNESS = 1.0;
	float fade = foreground_fade(VERTEX, VIEW_MATRIX, PROJECTION_MATRIX);
	ALPHA = foreground_dithered(fade, UV, textureSize(albedo_texture, 0)) ? 0.0 : texel.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
