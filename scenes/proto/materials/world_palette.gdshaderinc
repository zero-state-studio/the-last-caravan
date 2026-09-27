// World palette rule (51): warm base; colors drift toward white and ochre on
// the Day side and toward blue-violet on the Night side. The drift uses world
// position only: the zone's closeness to the Night or the Day (16) plus a
// gradient along world X (west = Day, east = Night) inside the zone.
// Values come from global uniforms set by ZonePalette (scripts/world/).

// Local names here must not match uniforms of the including shader:
// Godot resolves them to the uniform (e.g. "tint" in foreground_fade).
global uniform vec4 palette_day_tint;
global uniform vec4 palette_night_tint;
// -1 Day edge, 0 middle of the Twilight, +1 Night edge.
global uniform float palette_zone_proximity;
global uniform float palette_zone_center_x;
// Meters from the zone center, along world X, for a full step of drift.
global uniform float palette_gradient_width;
global uniform float palette_strength;

vec3 apply_world_palette(vec3 color, vec3 world_position) {
	// +X is east, toward the Night.
	float along_zone = (world_position.x - palette_zone_center_x) / max(palette_gradient_width, 0.001);
	float t = clamp(palette_zone_proximity + along_zone, -1.0, 1.0) * palette_strength;
	vec3 drift = t < 0.0 ? mix(vec3(1.0), palette_day_tint.rgb, -t) : mix(vec3(1.0), palette_night_tint.rgb, t);
	return color * drift;
}
