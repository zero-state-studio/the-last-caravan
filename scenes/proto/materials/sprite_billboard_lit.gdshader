// Character sprite lit by the scene lights (comparison option).
shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_disabled;

#define SPRITE_LIT
#include "res://scenes/proto/materials/sprite_billboard.gdshaderinc"
