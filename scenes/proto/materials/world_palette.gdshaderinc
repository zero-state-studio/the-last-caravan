// World palette rule (51): warm base; colors drift toward white and ochre on
// the Day side (west, screen left) and toward blue-violet on the Night side
// (east, screen right). Values come from global shader uniforms set by
// the scene (see [shader_globals] in project.godot).

// Local names here must not match uniforms of the including shader:
// Godot resolves them to the uniform (e.g. "tint" in foreground_fade).
global uniform vec4 palette_day_tint;
global uniform vec4 palette_night_tint;
// Meters from the scene center at which the drift reaches full strength.
global uniform float palette_gradient_width;
global uniform float palette_strength;

vec3 apply_world_palette(vec3 color, vec3 world_position) {
	// +X is east, toward the Night.
	float t = clamp(world_position.x / max(palette_gradient_width, 0.001), -1.0, 1.0) * palette_strength;
	vec3 drift = t < 0.0 ? mix(vec3(1.0), palette_day_tint.rgb, -t) : mix(vec3(1.0), palette_night_tint.rgb, t);
	return color * drift;
}
