class_name SystemsYard
extends Node3D
## The systems of chapter 1 tried in the diorama before the chapter (phase
## 4b step 1), with plain shapes. The meadow stands for the caravan in the
## Truce: the sundial runs there, patches can be sewn. The yard, south of
## the diorama, stands for a dungeon room: the sundial stops, entering it
## autosaves. In the yard:
## - a turning platform with a crate, cabbages, a fence and a Voltafaccia
##   on it, turned by a lever (hint «Use the lever») and by a second lever
##   locked by a crust of ice;
## - someone saved on a ledge: tied to the rope, a knot, the hint, a plank
##   shortcut lowers and they walk home alone;
## - pickups: a patch, warm stones, a memory on the platform.
## When the Truce runs out, a Fieldturner runs to Ottavia, speaks and takes
## her to the yard (as Iole will).

const CENTER: Vector3 = Vector3(0.0, 0.0, 60.0)
const SIZE: Vector2 = Vector2(32.0, 26.0)
const ROOM_ID: StringName = &"banco"
const ENTRY_ID: StringName = &"ingresso"
const ENTRY_POINT: Vector3 = Vector3(-13.0, 0.05, 64.0)
const CHAPTER_TUNING: ChapterTuning = preload("res://assets/combat/chapter_01_tuning.tres")
const VOLTAFACCIA_SCENE: PackedScene = preload("res://scenes/creatures/voltafaccia.tscn")
const CALLER_TEXTURE: Texture2D = preload("res://assets/sprites/folla/donna_adulta_south.png")
const CALLER_WALK: Texture2D = preload("res://assets/sprites/folla/donna_adulta_walk_east.png")
const SAVED_TEXTURE: Texture2D = preload("res://assets/sprites/comparse/ruggero_south.png")
const GROUND_COLOR: Color = Color(0.46, 0.4, 0.3)
const WOOD_COLOR: Color = Color(0.55, 0.4, 0.26)
const ICE_COLOR: Color = Color(0.72, 0.86, 0.98)
const CALLER_LINES: Array[Array] = [
	[&"SPEAKER_IOLE", &"C01_IOLE_01"],
	[&"SPEAKER_OTTAVIA", &"C01_OTTAVIA_01"],
	[&"SPEAKER_IOLE", &"C01_IOLE_02"],
]

var manager: RoomManager
var ottavia: OttaviaProto
var platform: TurningPlatform
var lever: TurnLever
var locked_lever: TurnLever
var crust: Breakable
var saved: RescuedPerson
var shortcut: RescueShortcut
var clock: TruceClock
var sundial: TruceSundial
var caller: TruceCaller
var room: Room


func setup(target_manager: RoomManager, player: OttaviaProto) -> void:
	manager = target_manager
	ottavia = player
	_build_room()
	_build_ground()
	_build_platform()
	_build_levers()
	_build_saved()
	_build_pickups()
	_build_truce()


func _build_room() -> void:
	room = Room.new()
	room.room_id = ROOM_ID
	room.size = Vector3(SIZE.x, 10.0, SIZE.y)
	room.default_entry = ENTRY_ID
	room.dungeon = true
	room.autosave_on_enter = true
	add_child(room)
	room.global_position = CENTER + Vector3.UP * 4.0
	var entry: RoomEntry = RoomEntry.new()
	entry.entry_id = ENTRY_ID
	room.add_child(entry)
	entry.global_position = ENTRY_POINT
	var exit: RoomExit = RoomExit.new()
	exit.target_room = &"prato"
	exit.target_entry = &"inizio"
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(1.0, 2.0, 4.0)
	shape.shape = box
	exit.add_child(shape)
	room.add_child(exit)
	exit.global_position = ENTRY_POINT + Vector3(-2.4, 1.0, 0.0)


func _build_ground() -> void:
	_box(self, CENTER + Vector3(0.0, -0.5, 0.0), Vector3(SIZE.x, 1.0, SIZE.y), GROUND_COLOR)
	for side: Vector4 in [Vector4(0.0, -SIZE.y * 0.5, SIZE.x, 0.4), Vector4(0.0, SIZE.y * 0.5, SIZE.x, 0.4), Vector4(-SIZE.x * 0.5, 0.0, 0.4, SIZE.y), Vector4(SIZE.x * 0.5, 0.0, 0.4, SIZE.y)]:
		_box(self, CENTER + Vector3(side.x, 0.6, side.y), Vector3(side.z, 1.2, side.w), GROUND_COLOR.darkened(0.3))
	# The ledge of the saved person, and the ramp up to it.
	_box(self, CENTER + Vector3(10.0, 1.25, -8.0), Vector3(5.0, 2.5, 4.0), GROUND_COLOR.lightened(0.1))
	_box(self, CENTER + Vector3(5.0, 1.2, -8.0), Vector3(5.8, 0.2, 2.0), WOOD_COLOR, Vector3(0.0, 0.0, atan2(2.5, 5.0)))


func _build_platform() -> void:
	platform = TurningPlatform.new()
	platform.name = "Platform"
	platform.tuning = CHAPTER_TUNING
	platform.carry_size = Vector3(8.0, 3.0, 8.0)
	platform.carry_offset = Vector3(0.0, 2.5, 0.0)
	add_child(platform)
	platform.global_position = CENTER
	_shape_and_mesh(platform, Vector3(0.0, 0.5, 0.0), Vector3(8.0, 1.0, 8.0), WOOD_COLOR)
	# The ramp on the east side: after each quarter turn it points elsewhere.
	var ramp_length: float = sqrt(3.0 * 3.0 + 1.0)
	_shape_and_mesh(platform, Vector3(5.5, 0.5, 0.0), Vector3(ramp_length + 0.2, 0.2, 2.4), WOOD_COLOR.darkened(0.15), Vector3(0.0, 0.0, -atan2(1.0, 3.0)))
	_shape_and_mesh(platform, Vector3(-2.0, 1.4, -2.0), Vector3(0.8, 0.8, 0.8), WOOD_COLOR.lightened(0.15))
	_shape_and_mesh(platform, Vector3(-1.0, 1.45, 2.6), Vector3(3.0, 0.9, 0.15), WOOD_COLOR.darkened(0.3))
	for spot: Vector3 in [Vector3(1.4, 1.0, -2.2), Vector3(2.4, 1.0, -2.2), Vector3(1.9, 1.0, -1.2)]:
		var cabbage: MeshInstance3D = MeshInstance3D.new()
		var mesh: CylinderMesh = CylinderMesh.new()
		mesh.top_radius = 0.45
		mesh.bottom_radius = 0.2
		mesh.height = 1.1
		cabbage.mesh = mesh
		cabbage.material_override = _material(Color(0.42, 0.55, 0.36))
		cabbage.position = spot + Vector3.UP * 0.55
		platform.add_child(cabbage)
	var beast: Voltafaccia = VOLTAFACCIA_SCENE.instantiate() as Voltafaccia
	beast.name = "YardVoltafaccia"
	# Placed before entering the tree: its start point (105) is read there.
	beast.position = CENTER + Vector3(1.5, 1.05, 1.5)
	add_child(beast)


func _build_levers() -> void:
	lever = TurnLever.new()
	lever.name = "Lever"
	lever.hint_when_near = true
	add_child(lever)
	lever.global_position = CENTER + Vector3(-6.0, 0.0, -3.0)
	lever.platform_path = lever.get_path_to(platform)
	lever.platform = platform
	# The second lever is locked by ice until the crust breaks (room 6).
	var look: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(0.9, 0.8, 0.8)
	look.mesh = mesh
	look.material_override = _material(ICE_COLOR)
	look.position = Vector3.UP * 0.4
	crust = Breakable.create(self, CENTER + Vector3(-5.2, 0.0, 3.0), look, 20.0, ICE_COLOR)
	crust.name = "IceCrust"
	locked_lever = TurnLever.new()
	locked_lever.name = "LockedLever"
	add_child(locked_lever)
	locked_lever.global_position = CENTER + Vector3(-6.0, 0.0, 3.0)
	locked_lever.platform = platform
	locked_lever.locked = true
	crust.broken.connect(locked_lever.unlock)


func _build_saved() -> void:
	shortcut = RescueShortcut.new()
	shortcut.name = "Shortcut"
	shortcut.shortcut_id = &"yard_shortcut"
	shortcut.reveal = "lower"
	add_child(shortcut)
	shortcut.global_position = CENTER + Vector3(10.0, 2.5, -6.0)
	_box(shortcut, Vector3(0.0, -1.25, 2.2), Vector3(1.6, 0.15, 5.2), WOOD_COLOR.lightened(0.2), Vector3(atan2(2.5, 4.4), 0.0, 0.0))
	for point: Vector3 in [Vector3(10.0, 2.5, -6.4), Vector3(10.0, 0.05, -1.5), Vector3(10.0, 0.05, 7.0), Vector3(-10.0, 0.05, 7.0), ENTRY_POINT - CENTER]:
		var marker: Marker3D = Marker3D.new()
		shortcut.add_child(marker)
		marker.global_position = CENTER + point
	saved = RescuedPerson.new()
	saved.name = "Saved"
	saved.person_id = &"yard_saved"
	saved.radius = 1.8
	var sprite: NpcSprite = NpcSprite.new()
	sprite.sprite_texture = SAVED_TEXTURE
	saved.add_child(sprite)
	add_child(saved)
	saved.global_position = CENTER + Vector3(11.0, 2.5, -8.5)
	saved.shortcut_path = saved.get_path_to(shortcut)
	saved.shortcut = shortcut


func _build_pickups() -> void:
	_pickup(self, &"patch_felt", &"yard_felt", CENTER + Vector3(-9.0, 0.0, -7.0))
	_pickup(self, &"warm_stone", &"yard_stone_1", CENTER + Vector3(12.0, 0.0, 6.0))
	_pickup(self, &"warm_stone", &"yard_stone_2", CENTER + Vector3(13.5, 0.0, 8.0))
	# On the platform: it turns with it.
	var seed: WorldPickup = _pickup(platform, &"memory_black_seed", &"yard_seed", Vector3.ZERO)
	seed.position = Vector3(2.5, 1.0, 2.5)
	# In the meadow, which stands for the caravan: a patch to sew there.
	_pickup(get_parent(), &"patch_field_canvas", &"yard_canvas", Vector3(-4.0, 0.05, 2.5))


func _build_truce() -> void:
	clock = TruceClock.new()
	clock.name = "TruceClock"
	clock.tuning = CHAPTER_TUNING
	add_child(clock)
	clock.bind_rooms(manager)
	sundial = TruceSundial.new()
	add_child(sundial)
	sundial.bind(clock)
	caller = TruceCaller.new()
	caller.name = "Caller"
	caller.sprite_texture = CALLER_TEXTURE
	caller.walk_texture = CALLER_WALK
	add_child(caller)
	clock.expired.connect(_on_truce_expired)
	clock.warning.connect(_on_truce_warning)


func start_truce(seconds: float = -1.0) -> void:
	if seconds > 0.0:
		clock.tuning = clock.tuning.duplicate() as ChapterTuning
		clock.tuning.truce_seconds = seconds
		clock.tuning.truce_warning_seconds = minf(clock.tuning.truce_warning_seconds, seconds * 0.5)
	clock.start(ottavia.combat.tuning.warm_stone_max)
	SaveGame.autosave(get_tree(), manager.current_room.room_id if manager.current_room != null else &"prato", &"inizio", &"truce")


func go_to_yard() -> void:
	await manager.travel(ROOM_ID, ENTRY_ID)


func _on_truce_warning() -> void:
	var dialogue: DialogueBox = get_parent().get_node_or_null(^"DialogueBox") as DialogueBox
	if dialogue == null:
		return
	dialogue.show_line(&"SPEAKER_VOLTACAMPI", &"C01_VOLTACAMPI_WARNING")
	get_tree().create_timer(3.0).timeout.connect(dialogue.hide_box)


func _on_truce_expired() -> void:
	caller.call_player(ottavia)
	await caller.arrived
	var dialogue: DialogueBox = get_parent().get_node_or_null(^"DialogueBox") as DialogueBox
	if dialogue != null:
		for line: Array in CALLER_LINES:
			var voice: float = dialogue.show_line(line[0], line[1])
			await get_tree().create_timer(DialogueBox.line_wait(2.2, voice)).timeout
		dialogue.hide_box()
	caller.visible = false
	ottavia.controls_enabled = true
	go_to_yard()


# --- Shapes -----------------------------------------------------------------

## A solid box under `parent`, at `at` in the parent's space (the yard
## sits at the origin, so for the yard that is the world).
func _box(parent: Node3D, at: Vector3, size: Vector3, color: Color, turn: Vector3 = Vector3.ZERO) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	parent.add_child(body)
	body.position = at
	_shape_and_mesh(body, Vector3.ZERO, size, color, turn)
	return body


## A box of collision and its mesh under `body`, at `at` in its space,
## turned by `turn` (for slopes).
func _shape_and_mesh(body: CollisionObject3D, at: Vector3, size: Vector3, color: Color, turn: Vector3 = Vector3.ZERO) -> void:
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = at
	shape.rotation = turn
	body.add_child(shape)
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _material(color)
	mesh_instance.position = at
	mesh_instance.rotation = turn
	body.add_child(mesh_instance)


func _pickup(parent: Node, item: StringName, id: StringName, at: Vector3) -> WorldPickup:
	var pickup: WorldPickup = WorldPickup.new()
	pickup.item_id = item
	pickup.pickup_id = id
	parent.add_child(pickup)
	if parent is Node3D:
		pickup.global_position = at
	return pickup


static func _material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	return material
