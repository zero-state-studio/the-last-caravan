class_name FrinitoreSwarm
extends Node3D
## The look of a Frinitore swarm (B38): many insects of a few pixels, each
## with two wing frames beating together, drifting in a loose cloud about
## 1.5 m across. Drawn in code at the world density (30 px per metre, 49);
## the whole cloud is what reads on screen, not the single insect.

const INSECTS: int = 64
const FLAP_SECONDS: float = 0.08
const BODY: Color = Color(0.36, 0.25, 0.1)
const WING: Color = Color(1.0, 0.84, 0.42)

@export var radius: float = 0.75

var _insects: Array[Sprite3D] = []
var _phases: PackedFloat32Array = []
var _speeds: PackedFloat32Array = []
var _time: float = 0.0
var _frames: Array[ImageTexture] = []


func _ready() -> void:
	_frames = [_frame(true), _frame(false)]
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = get_instance_id()
	for index: int in INSECTS:
		var insect: Sprite3D = Sprite3D.new()
		insect.texture = _frames[0]
		insect.pixel_size = WorldScale.METERS_PER_PIXEL
		insect.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		insect.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		insect.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		insect.shaded = false
		add_child(insect)
		_insects.append(insect)
		_phases.append(random.randf() * TAU)
		_speeds.append(random.randf_range(0.6, 1.4))


func _process(delta: float) -> void:
	_time += delta
	# All the wings beat together: one frame for the whole swarm.
	var frame: ImageTexture = _frames[int(_time / FLAP_SECONDS) % 2]
	for index: int in _insects.size():
		var phase: float = _phases[index]
		var speed: float = _speeds[index]
		var angle: float = phase + _time * speed
		var offset: Vector3 = Vector3(cos(angle) * sin(phase * 3.0), sin(angle * 1.7 + phase) * 0.6, sin(angle) * cos(phase * 2.0))
		_insects[index].position = offset * radius
		_insects[index].texture = frame


## A 5 x 4 pixel insect: a dark body and two light wings, up or down.
static func _frame(wings_up: bool) -> ImageTexture:
	var image: Image = Image.create(5, 4, false, Image.FORMAT_RGBA8)
	image.set_pixel(2, 2, BODY)
	image.set_pixel(2, 3, BODY)
	if wings_up:
		image.set_pixel(1, 1, WING)
		image.set_pixel(3, 1, WING)
		image.set_pixel(0, 0, WING)
		image.set_pixel(4, 0, WING)
	else:
		image.set_pixel(1, 2, WING)
		image.set_pixel(3, 2, WING)
		image.set_pixel(0, 3, WING)
		image.set_pixel(4, 3, WING)
	return ImageTexture.create_from_image(image)
