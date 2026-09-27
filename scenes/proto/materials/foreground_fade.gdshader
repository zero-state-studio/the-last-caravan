// Foreground vegetation that thins out around Ottavia (53).
// When a fragment is closer to the camera than the player and near her
// on screen, it is discarded with an ordered dither in texture space,
// so the see-through area keeps the pixel grid and needs no sorting.
shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_disabled;

global uniform vec3 player_position;

uniform sampler2D albedo_texture : source_color, filter_nearest, hint_default_white;
uniform vec4 tint : source_color = vec4(1.0);
// Radius of the see-through area, in meters at the player's depth.
uniform float fade_radius = 1.4;
uniform float fade_softness = 0.7;
// Share of pixels removed at the center (1.0 = fully transparent).
uniform float max_fade = 0.85;
// How much closer than the player a fragment must be to fade.
uniform float depth_margin = 0.3;

const float BAYER_4X4[16] = float[](
	0.0 / 16.0, 8.0 / 16.0, 2.0 / 16.0, 10.0 / 16.0,
	12.0 / 16.0, 4.0 / 16.0, 14.0 / 16.0, 6.0 / 16.0,
	3.0 / 16.0, 11.0 / 16.0, 1.0 / 16.0, 9.0 / 16.0,
	15.0 / 16.0, 7.0 / 16.0, 13.0 / 16.0, 5.0 / 16.0);

void fragment() {
	vec4 texel = texture(albedo_texture, UV);
	ALBEDO = texel.rgb * tint.rgb;
	ROUGHNESS = 1.0;

	vec3 player_view = (VIEW_MATRIX * vec4(player_position, 1.0)).xyz;
	bool orthographic = PROJECTION_MATRIX[3][3] == 1.0;
	vec2 fragment_xy = orthographic ? VERTEX.xy : VERTEX.xy * (player_view.z / VERTEX.z);
	float screen_distance = length(fragment_xy - player_view.xy);
	float in_front = step(player_view.z + depth_margin, VERTEX.z);
	float fade = in_front * max_fade * (1.0 - smoothstep(fade_radius - fade_softness, fade_radius, screen_distance));

	ivec2 cell = ivec2(UV * vec2(textureSize(albedo_texture, 0))) % 4;
	float threshold = BAYER_4X4[cell.y * 4 + cell.x];
	ALPHA = fade > threshold ? 0.0 : texel.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
