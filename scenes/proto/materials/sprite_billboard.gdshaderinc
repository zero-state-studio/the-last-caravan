// Character sprite billboard (99), sizes in 49. Included by sprite_billboard_*.gdshader.
// Draws the quad facing the camera (full billboard, square pixels at any
// camera angle) but writes the depth of an upright quad standing on the
// feet, so the top of the leaning sprite never sinks into walls behind it.
// Shadows come from a separate upright proxy, not from this quad.
// Lighting (lit variant) is sampled at one point for the whole sprite, so it
// is lit or shaded as a block; the point sits a little toward the sun so the
// shadow proxy never shades the sprite itself.

uniform sampler2D sprite_texture : source_color, filter_nearest;
// false: upright quad facing the camera yaw (fixed vertical axis).
uniform bool full_billboard = true;
// false: plain depth of the drawn quad (for comparison only).
uniform bool upright_depth = true;
// World offset from the sprite origin of the lighting sample point.
uniform vec3 light_sample_offset = vec3(0.0, 0.9, 0.0);
// Lantern glass (19): white where the sprite gives off its own light, so the
// glass stays lit in the shade and feeds the scene glow.
uniform sampler2D emission_mask : filter_nearest, hint_default_black;
uniform float emission_energy = 0.0;
// Hit flash and attack telegraphs (33): 0 = drawn colors, 1 = flash color.
uniform float flash = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0);

// Trade colours of the crowd (121): where the garment mask is white, the
// cloth is dyed along a dark-to-light ramp that keeps its shading, then
// sun-faded (98). Off while garment_strength is 0.
uniform sampler2D garment_mask : filter_nearest, hint_default_black;
uniform float garment_strength = 0.0;
uniform vec3 garment_dark : source_color = vec3(0.2);
uniform vec3 garment_light : source_color = vec3(0.8);
uniform float garment_fade = 0.0;

// A one-pixel outline around the sprite (small creatures, B1); off while
// its alpha is 0.
uniform vec4 outline_color : source_color = vec4(0.0);

varying vec4 upright_clip;

vec3 dyed(vec3 texel, vec2 uv) {
	float luma = dot(texel, vec3(0.299, 0.587, 0.114));
	vec3 cloth = mix(garment_dark, garment_light, smoothstep(0.06, 0.72, luma));
	float cloth_luma = dot(cloth, vec3(0.299, 0.587, 0.114));
	vec3 faded = mix(cloth, vec3(cloth_luma) * 1.08 + 0.06, garment_fade);
	return mix(texel, faded, texture(garment_mask, uv).r * garment_strength);
}

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	vec3 camera_right = INV_VIEW_MATRIX[0].xyz;
	vec3 horizontal_right = normalize(vec3(camera_right.x, 0.0, camera_right.z));
	vec3 upright = origin + horizontal_right * VERTEX.x + vec3(0.0, VERTEX.y, 0.0);
	vec3 facing = origin + camera_right * VERTEX.x + INV_VIEW_MATRIX[1].xyz * VERTEX.y;
	vec3 world = full_billboard ? facing : upright;
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(world, 1.0);
	upright_clip = PROJECTION_MATRIX * VIEW_MATRIX * vec4(upright_depth ? upright : world, 1.0);
	// VERTEX only feeds lighting, shadows and fog here (POSITION is set above).
	VERTEX = (inverse(MODEL_MATRIX) * vec4(origin + light_sample_offset, 1.0)).xyz;
}

void fragment() {
	vec4 texel = texture(sprite_texture, UV);
	if (texel.a < 0.5) {
		if (outline_color.a <= 0.0) {
			discard;
		}
		vec2 step_uv = 1.0 / vec2(textureSize(sprite_texture, 0));
		float near = texture(sprite_texture, UV + vec2(step_uv.x, 0.0)).a + texture(sprite_texture, UV - vec2(step_uv.x, 0.0)).a
			+ texture(sprite_texture, UV + vec2(0.0, step_uv.y)).a + texture(sprite_texture, UV - vec2(0.0, step_uv.y)).a;
		if (near < 0.5) {
			discard;
		}
		texel = vec4(outline_color.rgb, 1.0);
	}
	vec3 base = garment_strength > 0.0 ? dyed(texel.rgb, UV) : texel.rgb;
	vec3 color = mix(base, flash_color.rgb, clamp(flash, 0.0, 1.0));
	ALBEDO = color;
	float glass = texture(emission_mask, UV).r;
#ifdef SPRITE_LIT
	// Squared: faint tints stay tints, full hit flashes still light up in the shade.
	EMISSION = texel.rgb * glass * emission_energy + flash_color.rgb * pow(clamp(flash, 0.0, 1.0), 2.0) * 0.6;
#else
	ALBEDO = color * (1.0 + glass * emission_energy);
#endif
	// View-space normal toward the camera, used by the lit variant.
	NORMAL = vec3(0.0, 0.0, 1.0);
	DEPTH = upright_clip.z / upright_clip.w;
}
