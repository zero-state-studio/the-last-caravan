class_name WorldScale
extends RefCounted
## Pixel density of the whole game (49, 54), derived from Ottavia v1:
## her body is 48 px tall (head to feet, staff excluded) on a 64x64 canvas,
## and she stands about 1.6 m tall, so 48 / 1.6 = 30 px per meter.
## Every world texture and every sprite uses this density.
## Keep in sync with the shader global world_texels_per_meter (project.godot);
## tests/run_tests.gd checks it.

const CHARACTER_CANVAS_PIXELS: int = 64
const OTTAVIA_BODY_PIXELS: int = 48
const OTTAVIA_HEIGHT_METERS: float = 1.6
const PIXELS_PER_METER: float = 30.0
const METERS_PER_PIXEL: float = 1.0 / PIXELS_PER_METER
