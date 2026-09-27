// Character sprite billboard (49). Included by sprite_billboard_*.gdshader.
// Draws the quad facing the camera (full billboard, square pixels at any
// camera angle) but writes the depth of an upright quad standing on the
// feet, so the top of the leaning sprite never sinks into walls behind it.
// Shadows come from a separate upright proxy, not from this quad.

uniform sampler2D sprite_texture : source_color, filter_nearest;
// false: upright quad facing the camera yaw (fixed vertical axis).
uniform bool full_billboard = true;
// false: plain depth of the drawn quad (for comparison only).
uniform bool upright_depth = true;

varying vec4 upright_clip;

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	vec3 camera_right = INV_VIEW_MATRIX[0].xyz;
	vec3 horizontal_right = normalize(vec3(camera_right.x, 0.0, camera_right.z));
	vec3 upright = origin + horizontal_right * VERTEX.x + vec3(0.0, VERTEX.y, 0.0);
	vec3 facing = origin + camera_right * VERTEX.x + INV_VIEW_MATRIX[1].xyz * VERTEX.y;
	vec3 world = full_billboard ? facing : upright;
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(world, 1.0);
	upright_clip = PROJECTION_MATRIX * VIEW_MATRIX * vec4(upright_depth ? upright : world, 1.0);
}

void fragment() {
	vec4 texel = texture(sprite_texture, UV);
	if (texel.a < 0.5) {
		discard;
	}
	ALBEDO = texel.rgb;
	// View-space normal toward the camera, used by the lit variant.
	NORMAL = vec3(0.0, 0.0, 1.0);
	DEPTH = upright_clip.z / upright_clip.w;
}
