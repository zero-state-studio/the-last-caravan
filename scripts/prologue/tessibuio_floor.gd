extends Node3D
## Space 1 of the prologue (106, docs/livelli/prologo.md): a floor of the
## camion-condominio (122) where the Tessibuio sleep, divided by heavy
## curtains, with no light but Ottavia's lantern. Ottavia wakes on her cot,
## learns to open the lantern and to walk; Zelinda, weaving in the dark,
## asks her to close it; at the far end a stair leads to the back door.
## Walking into the door takes her outside, with the glare (space 2).
##
## Layout, in metres: the floor runs 20 m along x (west to east, the way
## Ottavia goes) and 6 m along z. The walkway is on the camera side
## (z -3.5..0); the sleeping bays are against the north wall, behind
## curtains facing the camera.

enum Step { WAKE, OPEN_LANTERN, MOVE, WALK, CLOSE_LANTERN, TO_DOOR, OUTSIDE }

const LENGTH: float = 20.0
const DEPTH: float = 6.0
const WALL_HEIGHT: float = 3.0
const BAY_FRONT_Z: float = -3.5
const BAY_WIDTH: float = 3.0
const LANDING_X: float = 18.0
const LANDING_Y: float = -0.6
const START: Vector3 = Vector3(2.4, 0.0, -2.6)
const ZELINDA_POSITION: Vector3 = Vector3(11.6, 0.0, -3.1)
const ZELINDA_RADIUS: float = 3.2
## Distance Ottavia must walk before the "Move" hint goes away.
const MOVE_HINT_DISTANCE: float = 1.5
const DOOR_POSITION: Vector3 = Vector3(LENGTH - 0.1, LANDING_Y, -2.3)
const ZELINDA_TEXTURE: Texture2D = preload("res://assets/sprites/comparse/zelinda_tesse.png")

const TEX_DECK: Texture2D = preload("res://assets/textures/terrain/wood_deck_01.png")
const TEX_PLANKS: Texture2D = preload("res://assets/textures/terrain/wood_planks_01.png")
const TEX_CURTAIN: Texture2D = preload("res://assets/textures/interior/curtain_dark_01.png")
const TEX_CLOTH: Texture2D = preload("res://assets/textures/interior/cloth_patched_01.png")
const TEX_METAL: Texture2D = preload("res://assets/textures/interior/metal_plates_01.png")
const TEX_PAINTED: Texture2D = preload("res://assets/textures/interior/wood_painted_01.png")
## The Generators' beat, muffled by the floor's walls and curtains.
const GENERATOR_DB: float = -9.0

## Seconds of black while Ottavia wakes up; 0 skips it (tests).
@export var intro_seconds: float = 2.5
## False in tests: the door does everything but load the camp.
@export var leave_scene: bool = true

var step: Step = Step.WAKE
var _was_in_bay: bool = true
var zelinda_spoke: bool = false

@onready var ottavia: OttaviaProto = $Ottavia
@onready var camera_rig: FollowCameraRig = $CameraRig
@onready var dialogue: DialogueBox = $DialogueBox
@onready var hints: HintBanner = $HintBanner
@onready var level: Node3D = $Level

var _fade: ColorRect
var _move_origin: Vector3 = Vector3.ZERO
var _door: Area3D


func _ready() -> void:
	GameOptions.load_options()
	InputRemap.load_controls()
	PrologueState.reset()
	NpcSprite.sun_azimuth_degrees = NAN
	_build()
	# Lit by the scene like Zelinda: in the dark, only the lantern shows her.
	ottavia.set_shaded(true)
	ottavia.global_position = START
	ottavia.face_toward(Vector3.BACK)
	ottavia.set_lantern_open(false)
	# No music on the dark floor: only the muffled beat of the Generators (126).
	GameAudio.stop_music(0.0)
	GameAudio.play_loop(&"generator", GameAudio.load_sfx(&"generatore_attutito"), GENERATOR_DB, 1.5)
	# Dev arguments for captures: intro=0, lantern=1, start_x=<metres>, step=walk.
	for argument: String in OS.get_cmdline_user_args():
		if argument == "intro=0":
			intro_seconds = 0.0
		elif argument == "lantern=1":
			ottavia.set_lantern_open(true)
		elif argument.begins_with("start_x="):
			ottavia.global_position.x = argument.trim_prefix("start_x=").to_float()
	camera_rig.target = ottavia
	camera_rig.limits = Rect2(Vector2(1.5, -4.0), Vector2(LENGTH - 3.0, 2.0))
	camera_rig.snap_to_target()
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 40
	add_child(layer)
	_fade = ColorRect.new()
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.color = Color(0.0, 0.0, 0.0, 1.0 if intro_seconds > 0.0 else 0.0)
	layer.add_child(_fade)
	# Pause and options (96), with the farewell lantern once revealed (88).
	var menu: OptionsMenu = OptionsMenu.new()
	menu.name = "OptionsMenu"
	add_child(menu)
	_wake.call_deferred()


func _wake() -> void:
	ottavia.controls_enabled = false
	if intro_seconds > 0.0:
		# The waking is heard, not seen (106, 127): the cot, then a breath.
		_wake_sounds()
		var tween: Tween = create_tween()
		tween.tween_property(_fade, "color:a", 0.0, intro_seconds)
		await tween.finished
	ottavia.controls_enabled = true
	if "step=walk" in OS.get_cmdline_user_args():
		step = Step.WALK
		return
	step = Step.OPEN_LANTERN
	hints.show_hint(&"PRO_HINT_OPEN_LANTERN", &"lantern")


func _wake_sounds() -> void:
	await get_tree().create_timer(0.3).timeout
	SoundBank.play_sound(get_tree(), &"branda_cigolio", 0.0)
	await get_tree().create_timer(1.1).timeout
	SoundBank.play_sound(get_tree(), &"respiro_risveglio", 0.0)


func _physics_process(_delta: float) -> void:
	# The bay curtains rustle when she walks through them (127).
	var in_bay: bool = ottavia.global_position.z < BAY_FRONT_Z
	if in_bay != _was_in_bay:
		_was_in_bay = in_bay
		SoundBank.play_sound(get_tree(), &"fruscio_tende")
	match step:
		Step.OPEN_LANTERN:
			if ottavia.lantern_open:
				step = Step.MOVE
				_move_origin = ottavia.global_position
				hints.show_hint(&"PRO_HINT_MOVE", &"move")
		Step.MOVE:
			if _flat_distance(ottavia.global_position, _move_origin) >= MOVE_HINT_DISTANCE:
				step = Step.WALK
				hints.hide_hint()
		Step.WALK:
			if ottavia.lantern_open and _flat_distance(ottavia.global_position, ZELINDA_POSITION) <= ZELINDA_RADIUS:
				step = Step.CLOSE_LANTERN
				zelinda_spoke = true
				dialogue.show_line(&"SPEAKER_ZELINDA", &"PRO_ZELINDA_01")
				hints.show_hint(&"PRO_HINT_CLOSE_LANTERN", &"lantern")
			elif ottavia.global_position.x > ZELINDA_POSITION.x + ZELINDA_RADIUS:
				# Walked past her in the dark: nothing to ask.
				step = Step.TO_DOOR
		Step.CLOSE_LANTERN:
			if not ottavia.lantern_open:
				step = Step.TO_DOOR
				hints.hide_hint()
				_hide_dialogue_later()
			elif _flat_distance(ottavia.global_position, ZELINDA_POSITION) > ZELINDA_RADIUS * 2.0:
				dialogue.hide_box()


func _hide_dialogue_later() -> void:
	await get_tree().create_timer(2.0).timeout
	if step != Step.CLOSE_LANTERN:
		dialogue.hide_box()


func _on_door_entered(body: Node3D) -> void:
	if body == ottavia and step != Step.OUTSIDE:
		go_outside()


## The back door (space 2): the sunset light blinds her for a moment; the
## white is softened by the option that reduces flashes (96).
func go_outside() -> void:
	step = Step.OUTSIDE
	ottavia.controls_enabled = false
	hints.hide_hint()
	dialogue.hide_box()
	PrologueState.entered_from_door = true
	PrologueState.lantern_open = ottavia.lantern_open
	SoundBank.play_sound(get_tree(), &"porta_camion_vento", 0.0)
	GameAudio.stop_loop(&"generator", 0.8)
	var glare: Color = Color(1.0, 0.93, 0.8).lerp(Color(0.55, 0.42, 0.32), 1.0 - GameOptions.flash_strength)
	_fade.color = Color(glare, 0.0)
	var tween: Tween = create_tween()
	tween.tween_property(_fade, "color:a", 1.0, 0.6)
	await tween.finished
	if leave_scene:
		get_tree().change_scene_to_file(PrologueState.CAMP_SCENE)


static func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _build() -> void:
	var deck: ShaderMaterial = LevelBlocks.material(TEX_DECK, TEX_PLANKS)
	var planks: ShaderMaterial = LevelBlocks.material(TEX_PLANKS)
	var wall: ShaderMaterial = LevelBlocks.material(TEX_PLANKS, TEX_METAL)
	var curtain: ShaderMaterial = LevelBlocks.material(TEX_CURTAIN)
	var cloth: ShaderMaterial = LevelBlocks.material(TEX_CLOTH)
	var painted: ShaderMaterial = LevelBlocks.material(TEX_PAINTED)

	# Floor, the three steps down and the landing by the back door.
	LevelBlocks.box(level, Vector3(LANDING_X * 0.5 - 0.5, -0.1, -DEPTH * 0.5), Vector3(LANDING_X - 1.0, 0.2, DEPTH), deck)
	for index: int in 3:
		var top: float = LANDING_Y * 0.25 * (index + 1)
		var bottom: float = LANDING_Y - 0.2
		LevelBlocks.box(level, Vector3(LANDING_X - 1.0 + 0.33 * index + 0.165, (top + bottom) * 0.5, -DEPTH * 0.5), Vector3(0.33, top - bottom, DEPTH), deck)
	LevelBlocks.box(level, Vector3((LANDING_X + LENGTH) * 0.5, LANDING_Y - 0.1, -DEPTH * 0.5), Vector3(LENGTH - LANDING_X, 0.2, DEPTH), deck)
	# Walls: north, west, east (with the door); the camera side stays open.
	LevelBlocks.box(level, Vector3(LENGTH * 0.5, WALL_HEIGHT * 0.5 + LANDING_Y, -DEPTH - 0.15), Vector3(LENGTH, WALL_HEIGHT - LANDING_Y, 0.3), wall)
	LevelBlocks.box(level, Vector3(-0.15, WALL_HEIGHT * 0.5, -DEPTH * 0.5), Vector3(0.3, WALL_HEIGHT, DEPTH), wall)
	LevelBlocks.box(level, Vector3(LENGTH + 0.15, WALL_HEIGHT * 0.5 + LANDING_Y * 0.5, -DEPTH + 1.6), Vector3(0.3, WALL_HEIGHT - LANDING_Y, 3.2), wall)
	LevelBlocks.box(level, Vector3(LENGTH + 0.15, WALL_HEIGHT * 0.5 + LANDING_Y * 0.5, -0.9), Vector3(0.3, WALL_HEIGHT - LANDING_Y, 1.8), wall)
	LevelBlocks.box(level, Vector3(LENGTH + 0.15, 2.15, -2.3), Vector3(0.3, 1.1, 1.0), wall)
	# Invisible edge on the camera side, so the walkway has a limit.
	var edge: Node3D = LevelBlocks.box(level, Vector3(LENGTH * 0.5, 1.0, 0.15), Vector3(LENGTH, 2.0, 0.3), planks)
	edge.visible = false

	# Sleeping bays against the north wall, one every 3 m.
	var bays: int = int((LANDING_X - 2.0) / BAY_WIDTH)
	for index: int in bays:
		var x0: float = 1.0 + index * BAY_WIDTH
		# Divider curtain between bays, hanging from the ceiling.
		LevelBlocks.box(level, Vector3(x0, 1.45, (BAY_FRONT_Z - DEPTH) * 0.5), Vector3(0.12, 2.5, DEPTH + BAY_FRONT_Z), curtain)
		var zelinda_bay: bool = absf(x0 + BAY_WIDTH * 0.5 - ZELINDA_POSITION.x) < BAY_WIDTH * 0.5
		var own_bay: bool = index == 0
		# Front curtain: drawn most of the way, a gap shows the cot inside.
		if not zelinda_bay:
			var covered: float = 1.2 if own_bay else 2.1
			LevelBlocks.box(level, Vector3(x0 + BAY_WIDTH - covered * 0.5, 1.45, BAY_FRONT_Z), Vector3(covered, 2.5, 0.12), curtain)
		# Cot along the wall, with a blanket; a sleeper in the other bays.
		var cot_x: float = x0 + 1.1
		LevelBlocks.box(level, Vector3(cot_x, 0.22, -DEPTH + 0.6), Vector3(1.9, 0.44, 0.8), planks)
		LevelBlocks.box(level, Vector3(cot_x, 0.5, -DEPTH + 0.6), Vector3(1.8, 0.12, 0.75), cloth, false)
		if not own_bay and not zelinda_bay:
			LevelBlocks.cylinder(level, Vector3(cot_x, 0.72, -DEPTH + 0.6), 0.28, 1.5, cloth, true)
		# Rolls of dark cloth stacked in the corner of the bay.
		LevelBlocks.cylinder(level, Vector3(x0 + 2.5, 0.2, -DEPTH + 1.6), 0.2, 0.9, curtain, true)
		LevelBlocks.cylinder(level, Vector3(x0 + 2.5, 0.55, -DEPTH + 1.55), 0.18, 0.8, curtain, true)
	# Zelinda's loom and stool at the mouth of her bay.
	LevelBlocks.box(level, ZELINDA_POSITION + Vector3(0.9, 0.6, -0.3), Vector3(0.1, 1.2, 0.1), planks, false)
	LevelBlocks.box(level, ZELINDA_POSITION + Vector3(-0.9, 0.6, -0.3), Vector3(0.1, 1.2, 0.1), planks, false)
	LevelBlocks.box(level, ZELINDA_POSITION + Vector3(0.0, 1.15, -0.3), Vector3(1.9, 0.1, 0.1), planks, false)
	LevelBlocks.box(level, ZELINDA_POSITION + Vector3(0.0, 0.7, -0.35), Vector3(1.6, 0.8, 0.04), curtain, false)
	var zelinda: NpcSprite = NpcSprite.new()
	zelinda.name = "Zelinda"
	zelinda.sprite_texture = ZELINDA_TEXTURE
	# Weaving idle, one view only (118): hands and shuttle move slowly.
	zelinda.frame_count = 8
	zelinda.frames_per_second = 5.0
	zelinda.position = ZELINDA_POSITION
	level.add_child(zelinda)
	var zelinda_body: Node3D = LevelBlocks.box(level, ZELINDA_POSITION + Vector3(0.0, 0.5, 0.0), Vector3(0.9, 1.0, 0.6), planks)
	zelinda_body.visible = false

	# The back door, with the sunset leaking through the crack.
	LevelBlocks.box(level, DOOR_POSITION + Vector3(0.05, 1.1, 0.0), Vector3(0.1, 2.2, 1.0), painted, false)
	var leak: MeshInstance3D = MeshInstance3D.new()
	var strip: BoxMesh = BoxMesh.new()
	strip.size = Vector3(0.02, 2.2, 0.04)
	leak.mesh = strip
	var glow: StandardMaterial3D = StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = Color(1.0, 0.72, 0.4)
	glow.emission_enabled = true
	glow.emission = Color(1.0, 0.62, 0.3)
	glow.emission_energy_multiplier = 2.0
	leak.material_override = glow
	leak.position = DOOR_POSITION + Vector3(-0.01, 1.1, 0.5)
	level.add_child(leak)
	var spill: OmniLight3D = OmniLight3D.new()
	spill.light_color = Color(1.0, 0.62, 0.35)
	spill.light_energy = 0.5
	spill.omni_range = 2.2
	spill.position = DOOR_POSITION + Vector3(-0.4, 0.3, 0.4)
	level.add_child(spill)
	_door = Area3D.new()
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(0.6, 2.0, 1.0)
	shape.shape = box_shape
	_door.add_child(shape)
	_door.position = DOOR_POSITION + Vector3(-0.35, 1.0, 0.0)
	_door.body_entered.connect(_on_door_entered)
	level.add_child(_door)
