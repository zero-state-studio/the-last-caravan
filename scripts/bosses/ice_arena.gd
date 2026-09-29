class_name IceArena
extends BossArena
## The frozen pond of the Vecchio Spartighiaccio (41): a floor of ice plates.
## A charge cracks the plates it crosses; crossing a cracked plate in a later
## charge breaks it into open water. Ottavia falling in loses some health and
## comes back on the last safe plate. Everything freezes again when the
## fight restarts (105).

enum Plate { INTACT, CRACKED, BROKEN }

const FROST_TEXTURE: Texture2D = preload("res://assets/textures/terrain/frost_ground.png")
const TERRAIN_SHADER: Shader = preload("res://scenes/proto/materials/terrain_triplanar.gdshader")

## Plates per side and plate size in meters; the floor is centered on the node.
@export var plates_per_side: int = 8
@export var plate_size: float = 1.5

var _states: Array[int] = []
var _cracked_by: Array[int] = []
var _bodies: Array[StaticBody3D] = []
var _meshes: Array[MeshInstance3D] = []
var _intact_material: ShaderMaterial
var _cracked_material: ShaderMaterial
var _last_safe: Vector3
var _falling: bool = false


func _ready() -> void:
	super._ready()
	_intact_material = _frost_material(Color(1.25, 1.35, 1.55))
	_cracked_material = _frost_material(Color(0.6, 0.66, 0.85))
	for index: int in plates_per_side * plates_per_side:
		var body: StaticBody3D = StaticBody3D.new()
		var shape: CollisionShape3D = CollisionShape3D.new()
		var box: BoxShape3D = BoxShape3D.new()
		box.size = Vector3(plate_size, 0.4, plate_size)
		shape.shape = box
		shape.position = Vector3(0.0, -0.2, 0.0)
		body.add_child(shape)
		var mesh: MeshInstance3D = MeshInstance3D.new()
		var box_mesh: BoxMesh = BoxMesh.new()
		box_mesh.size = Vector3(plate_size - 0.06, 0.4, plate_size - 0.06)
		mesh.mesh = box_mesh
		mesh.position = Vector3(0.0, -0.2, 0.0)
		body.add_child(mesh)
		add_child(body)
		body.position = _plate_center(index)
		_bodies.append(body)
		_meshes.append(mesh)
		_states.append(Plate.INTACT)
		_cracked_by.append(0)
	(boss as VecchioSpartighiaccio).ice = self
	_refresh_all()


## The plate under `point` gets cracked by charge `charge_id`; a plate
## cracked by an earlier charge breaks.
func crack_at(point: Vector3, charge_id: int) -> void:
	var index: int = plate_index(point)
	if index < 0:
		return
	match _states[index]:
		Plate.INTACT:
			_states[index] = Plate.CRACKED
			_cracked_by[index] = charge_id
			SoundBank.play_sound(get_tree(), &"parata", 0.3)
		Plate.CRACKED:
			if _cracked_by[index] != charge_id:
				_states[index] = Plate.BROKEN
				SoundBank.play_sound(get_tree(), &"nemico_sconfitto", 0.3)
	_refresh(index)


func is_broken_at(point: Vector3) -> bool:
	var index: int = plate_index(point)
	return index >= 0 and _states[index] == Plate.BROKEN


func plate_state(point: Vector3) -> int:
	var index: int = plate_index(point)
	return _states[index] if index >= 0 else -1


## Index of the plate under `point`, or -1 outside the ice.
func plate_index(point: Vector3) -> int:
	var local: Vector3 = point - global_position
	var half: float = plates_per_side * plate_size * 0.5
	var column: int = floori((local.x + half) / plate_size)
	var row: int = floori((local.z + half) / plate_size)
	if column < 0 or row < 0 or column >= plates_per_side or row >= plates_per_side:
		return -1
	return row * plates_per_side + column


## Distance from `point` along `direction` to the edge of the ice.
func distance_to_edge(point: Vector3, direction: Vector3) -> float:
	var distance: float = 0.0
	while distance < 30.0 and plate_index(point + direction * distance) >= 0:
		distance += 0.25
	return distance


func _physics_process(_delta: float) -> void:
	if manager == null or manager.current_room != room or _falling:
		return
	var ottavia: OttaviaProto = player()
	if ottavia == null:
		return
	var index: int = plate_index(ottavia.global_position)
	# The stone rim around the ice counts as safe ground too.
	if index < 0 or _states[index] != Plate.BROKEN:
		if ottavia.is_on_floor():
			_last_safe = ottavia.global_position
	elif ottavia.global_position.y < global_position.y - 0.3:
		_fall(ottavia)


## Into the water: a little damage and back on the last safe plate.
func _fall(ottavia: OttaviaProto) -> void:
	_falling = true
	var cold: float = ottavia.combat.patch_multiplier(CoatPatches.EFFECT_COLD)
	ottavia.take_damage((boss as VecchioSpartighiaccio).creature.ice_fall_damage * cold * Difficulty.enemy_damage())
	ottavia.flash(1.0, Color(0.6, 0.75, 1.0))
	SoundBank.play_sound(get_tree(), &"colpo_subito")
	ottavia.global_position = _last_safe + Vector3.UP * 0.1
	ottavia.velocity = Vector3.ZERO
	_falling = false


func _on_room_changed(new_room: Room) -> void:
	super._on_room_changed(new_room)
	if new_room == room and manager != null:
		_last_safe = manager.respawn_position


func _reset_arena() -> void:
	if manager != null:
		_last_safe = manager.respawn_position
	for index: int in _states.size():
		_states[index] = Plate.INTACT
		_cracked_by[index] = 0
	_refresh_all()


func _plate_center(index: int) -> Vector3:
	var half: float = plates_per_side * plate_size * 0.5
	var column: int = index % plates_per_side
	var row: int = index / plates_per_side
	return Vector3(-half + (column + 0.5) * plate_size, 0.0, -half + (row + 0.5) * plate_size)


func _refresh_all() -> void:
	for index: int in _states.size():
		_refresh(index)


func _refresh(index: int) -> void:
	var broken: bool = _states[index] == Plate.BROKEN
	_meshes[index].visible = not broken
	_meshes[index].material_override = _cracked_material if _states[index] == Plate.CRACKED else _intact_material
	(_bodies[index].get_child(0) as CollisionShape3D).set_deferred(&"disabled", broken)


static func _frost_material(tint: Color) -> ShaderMaterial:
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = TERRAIN_SHADER
	material.set_shader_parameter(&"top_texture", FROST_TEXTURE)
	material.set_shader_parameter(&"side_texture", FROST_TEXTURE)
	material.set_shader_parameter(&"top_tint", tint)
	material.set_shader_parameter(&"side_tint", tint * 0.8)
	return material
