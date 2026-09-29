class_name TurnLever
extends Interactable
## The lever of the Voltacampi (chapter 1, section 4): a big wooden lever
## with an iron ring and bare gears. Each pull turns its platform a quarter
## clockwise; it can be pulled again once the turn is over. A crust of ice
## can lock it (room 6): break the crust (a Breakable) and it works.
## Placeholder shapes until the final model (phase 4b step 4).

signal pulled

const HANDLE_REST_DEGREES: float = -35.0
const HANDLE_PULLED_DEGREES: float = 35.0
const HINT_FLAG: StringName = &"hint_use_lever"

## Path, not a typed node export (see docs/tecnica.md).
@export var platform_path: NodePath
## Locked by a crust of ice until `crust_path` (a Breakable) breaks.
@export var crust_path: NodePath
## The first lever of the game shows «Use the lever» when Ottavia is near.
@export var hint_when_near: bool = false

var platform: TurningPlatform
var locked: bool = false
var _handle: Node3D
var _gear: MeshInstance3D
var _hint_shown: bool = false


func _ready() -> void:
	platform = get_node_or_null(platform_path) as TurningPlatform
	_build()
	var crust: Node = get_node_or_null(crust_path)
	if crust != null and crust.has_signal(&"broken"):
		locked = true
		crust.connect(&"broken", unlock)


func can_use() -> bool:
	return not locked and platform != null and not platform.turning


func use() -> void:
	if not can_use():
		return
	platform.turn()
	var tween: Tween = create_tween()
	tween.tween_property(_handle, "rotation_degrees:z", HANDLE_PULLED_DEGREES, 0.25)
	tween.tween_property(_handle, "rotation_degrees:z", HANDLE_REST_DEGREES, platform.turn_seconds())
	# Provisional sounds until the chapter 1 effects (phase 4b step 5).
	SoundBank.play_sound(get_tree(), &"bastone_legno", 0.0)
	_hide_hint()
	pulled.emit()
	super.use()


func unlock() -> void:
	locked = false


func _process(delta: float) -> void:
	if platform != null and platform.turning:
		_gear.rotation.z -= delta * 4.0
	if hint_when_near and not _hint_shown and not GameState.has_flag(HINT_FLAG):
		var player: Node3D = get_tree().get_first_node_in_group(&"player") as Node3D
		if player != null and player.global_position.distance_to(global_position) < radius + 2.5:
			var banner: HintBanner = get_tree().get_first_node_in_group(&"hint_banner") as HintBanner
			if banner != null:
				banner.show_hint(&"HINT_USE_LEVER", &"interact")
				_hint_shown = true


func _hide_hint() -> void:
	if not _hint_shown:
		return
	GameState.set_flag(HINT_FLAG)
	var banner: HintBanner = get_tree().get_first_node_in_group(&"hint_banner") as HintBanner
	if banner != null and banner.current_hint() == &"HINT_USE_LEVER":
		banner.hide_hint()


func _build() -> void:
	var wood: StandardMaterial3D = _material(Color(0.5, 0.34, 0.2))
	var iron: StandardMaterial3D = _material(Color(0.3, 0.3, 0.33))
	var base: MeshInstance3D = MeshInstance3D.new()
	var base_mesh: BoxMesh = BoxMesh.new()
	base_mesh.size = Vector3(0.7, 0.5, 0.5)
	base.mesh = base_mesh
	base.position = Vector3(0.0, 0.25, 0.0)
	base.material_override = wood
	add_child(base)
	_gear = MeshInstance3D.new()
	var gear_mesh: CylinderMesh = CylinderMesh.new()
	gear_mesh.top_radius = 0.32
	gear_mesh.bottom_radius = 0.32
	gear_mesh.height = 0.08
	gear_mesh.radial_segments = 10
	_gear.mesh = gear_mesh
	_gear.rotation_degrees.x = 90.0
	_gear.position = Vector3(0.0, 0.55, 0.3)
	_gear.material_override = iron
	add_child(_gear)
	_handle = Node3D.new()
	_handle.position = Vector3(0.0, 0.5, 0.0)
	add_child(_handle)
	var bar: MeshInstance3D = MeshInstance3D.new()
	var bar_mesh: BoxMesh = BoxMesh.new()
	bar_mesh.size = Vector3(0.12, 1.3, 0.12)
	bar.mesh = bar_mesh
	bar.position = Vector3(0.0, 0.65, 0.0)
	bar.material_override = wood
	_handle.add_child(bar)
	var ring: MeshInstance3D = MeshInstance3D.new()
	var ring_mesh: TorusMesh = TorusMesh.new()
	ring_mesh.inner_radius = 0.1
	ring_mesh.outer_radius = 0.16
	ring.mesh = ring_mesh
	ring.rotation_degrees.x = 90.0
	ring.position = Vector3(0.0, 1.35, 0.0)
	ring.material_override = iron
	_handle.add_child(ring)
	_handle.rotation_degrees.z = HANDLE_REST_DEGREES


static func _material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	return material
