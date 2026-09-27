// Foreground see-through (53). A fragment closer to the camera than Ottavia
// and near her on screen is dropped with a 4x4 ordered dither in texture
// space: the see-through area keeps the pixel grid (no soft transparency)
// and needs no sorting. Shared by vegetation cards and environment models.

global uniform vec3 player_position;

// Radius of the see-through area, in meters at the player's depth.
uniform float fade_radius = 1.4;
uniform float fade_softness = 0.7;
// Share of pixels removed at the center (1.0 = fully transparent).
uniform float max_fade = 1.0;
// How much closer than the player a fragment must be to fade.
uniform float depth_margin = 0.3;

const float BAYER_4X4[16] = float[](
	0.0 / 16.0, 8.0 / 16.0, 2.0 / 16.0, 10.0 / 16.0,
	12.0 / 16.0, 4.0 / 16.0, 14.0 / 16.0, 6.0 / 16.0,
	3.0 / 16.0, 11.0 / 16.0, 1.0 / 16.0, 9.0 / 16.0,
	15.0 / 16.0, 7.0 / 16.0, 13.0 / 16.0, 5.0 / 16.0);

// Share of pixels to remove at a fragment (view-space `vertex`).
float foreground_fade(vec3 vertex, mat4 view_matrix, mat4 projection_matrix) {
	vec3 player_view = (view_matrix * vec4(player_position, 1.0)).xyz;
	bool orthographic = projection_matrix[3][3] == 1.0;
	vec2 fragment_xy = orthographic ? vertex.xy : vertex.xy * (player_view.z / vertex.z);
	float screen_distance = length(fragment_xy - player_view.xy);
	float in_front = step(player_view.z + depth_margin, vertex.z);
	return in_front * max_fade * (1.0 - smoothstep(fade_radius - fade_softness, fade_radius, screen_distance));
}

// True when this fragment's texel falls under the dither for `fade`.
bool foreground_dithered(float fade, vec2 uv, ivec2 texture_size) {
	ivec2 cell = ivec2(uv * vec2(texture_size)) % 4;
	return fade > BAYER_4X4[cell.y * 4 + cell.x];
}
