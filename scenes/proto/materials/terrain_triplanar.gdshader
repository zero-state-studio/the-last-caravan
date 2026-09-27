// World-space triplanar mapping for level geometry (46, 54).
// Picks the dominant axis instead of blending, so pixel art stays crisp,
// and uses one texture for upward faces and another for the sides.
// Texel density comes from the global uniform world_texels_per_meter,
// so every surface shares the same pixel size.
shader_type spatial;
render_mode diffuse_burley, specular_disabled;

global uniform float world_texels_per_meter;

uniform sampler2D top_texture : source_color, filter_nearest, repeat_enable, hint_default_white;
uniform sampler2D side_texture : source_color, filter_nearest, repeat_enable, hint_default_white;
uniform vec4 top_tint : source_color = vec4(1.0);
uniform vec4 side_tint : source_color = vec4(1.0);
// Faces whose world normal has a Y component above this use the top texture.
uniform float top_threshold = 0.7;

varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(mat3(MODEL_MATRIX) * NORMAL);
}

void fragment() {
	vec3 n = abs(world_normal);
	vec2 uv;
	if (n.y >= n.x && n.y >= n.z) {
		uv = world_position.xz;
	} else if (n.x >= n.z) {
		uv = vec2(world_position.z, -world_position.y);
	} else {
		uv = vec2(world_position.x, -world_position.y);
	}
	bool is_top = world_normal.y > top_threshold;
	vec3 color;
	if (is_top) {
		vec2 size = vec2(textureSize(top_texture, 0));
		color = texture(top_texture, uv * world_texels_per_meter / size).rgb * top_tint.rgb;
	} else {
		vec2 size = vec2(textureSize(side_texture, 0));
		color = texture(side_texture, uv * world_texels_per_meter / size).rgb * side_tint.rgb;
	}
	ALBEDO = color;
	ROUGHNESS = 1.0;
}
