// Ground of an open zone (54, 100): a base texture broken by large patches
// of a second one, plus dirt roads, gravel and frost painted in a world-space
// mask (R road, G gravel, B frost; 1 px per metre over mask_rect).
// Every texel picks one layer, never a blend, so pixel art stays crisp; a
// texel-level noise makes the borders ragged instead of straight.
shader_type spatial;
render_mode diffuse_burley, specular_disabled;

global uniform float world_texels_per_meter;

#include "res://scenes/proto/materials/world_palette.gdshaderinc"

uniform sampler2D base_texture : source_color, filter_nearest, repeat_enable;
uniform sampler2D base_alt_texture : source_color, filter_nearest, repeat_enable;
uniform sampler2D road_texture : source_color, filter_nearest, repeat_enable;
uniform sampler2D gravel_texture : source_color, filter_nearest, repeat_enable;
uniform sampler2D frost_texture : source_color, filter_nearest, repeat_enable;
uniform sampler2D layer_mask : filter_linear, repeat_disable, hint_default_black;
// x, z of the mask corner and its size in metres.
uniform vec4 mask_rect = vec4(-120.0, -80.0, 240.0, 160.0);
// Size in metres of the patches of the second base texture.
uniform float alt_patch_meters = 14.0;
uniform float alt_amount = 0.42;
// How ragged the borders are (0 = straight).
uniform float edge_noise = 0.35;
// Slow brightness drift over the ground, so the repeat does not show.
uniform float macro_variation = 0.07;
// The road texture runs along x (wheel ruts along the column).

varying vec3 world_position;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

vec3 sample_layer(sampler2D tex, vec2 texel) {
	vec2 size = vec2(textureSize(tex, 0));
	return texture(tex, (texel + 0.5) / size).rgb;
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 meters = world_position.xz;
	// Work on the texel grid: every decision is taken per world pixel.
	vec2 texel = floor(meters * world_texels_per_meter);
	vec2 snapped = (texel + 0.5) / world_texels_per_meter;
	float jitter = (hash(texel) - 0.5) * 0.25 + (value_noise(snapped * 0.9) - 0.5) * 0.75;
	vec2 mask_uv = (snapped - mask_rect.xy) / mask_rect.zw;
	vec4 mask = texture(layer_mask, mask_uv);
	float road = mask.r + jitter * edge_noise;
	float gravel = mask.g + jitter * edge_noise;
	float frost = mask.b + jitter * edge_noise;
	float alt = value_noise(snapped / alt_patch_meters) + jitter * 0.12;
	vec3 color;
	if (frost > 0.5 && frost >= road && frost >= gravel) {
		color = sample_layer(frost_texture, texel);
	} else if (road > 0.5 && road >= gravel) {
		color = sample_layer(road_texture, texel);
	} else if (gravel > 0.5) {
		color = sample_layer(gravel_texture, texel);
	} else if (alt > 1.0 - alt_amount) {
		color = sample_layer(base_alt_texture, texel);
	} else {
		color = sample_layer(base_texture, texel);
	}
	float drift = (value_noise(snapped / 23.0) - 0.5) * 2.0 * macro_variation;
	color *= 1.0 + drift;
	ALBEDO = apply_world_palette(color, world_position);
	ROUGHNESS = 1.0;
}
