class_name FieldLever
extends Interactable
## The lever the Voltacampi use to tilt a field toward the low sun (83). It
## can be pulled again only after `cooldown` seconds.

const HANDLE_REST_DEGREES: float = -35.0
const HANDLE_PULLED_DEGREES: float = 35.0

var cooldown: float = 12.0
var _cooldown_left: float = 0.0
var _handle: Node3D


func _ready() -> void:
	var post: MeshInstance3D = MeshInstance3D.new()
	var post_mesh: BoxMesh = BoxMesh.new()
	post_mesh.size = Vector3(0.3, 0.9, 0.3)
	post.mesh = post_mesh
	post.position = Vector3(0.0, 0.45, 0.0)
	post.material_override = _material(Color(0.45, 0.3, 0.2))
	add_child(post)
	_handle = Node3D.new()
	_handle.position = Vector3(0.0, 0.85, 0.0)
	add_child(_handle)
	var bar: MeshInstance3D = MeshInstance3D.new()
	var bar_mesh: BoxMesh = BoxMesh.new()
	bar_mesh.size = Vector3(0.12, 1.1, 0.12)
	bar.mesh = bar_mesh
	bar.position = Vector3(0.0, 0.55, 0.0)
	bar.material_override = _material(Color(0.62, 0.45, 0.3))
	_handle.add_child(bar)
	_handle.rotation_degrees.z = HANDLE_REST_DEGREES


func can_use() -> bool:
	return _cooldown_left <= 0.0


func use() -> void:
	if not can_use():
		return
	_cooldown_left = cooldown
	var tween: Tween = create_tween()
	tween.tween_property(_handle, "rotation_degrees:z", HANDLE_PULLED_DEGREES, 0.25)
	SoundBank.play_sound(get_tree(), &"sportello_lanterna", 0.0)
	super.use()


func reset_lever() -> void:
	_cooldown_left = 0.0
	_handle.rotation_degrees.z = HANDLE_REST_DEGREES


func _process(delta: float) -> void:
	if _cooldown_left > 0.0:
		_cooldown_left -= delta
		if _cooldown_left <= 0.0:
			var tween: Tween = create_tween()
			tween.tween_property(_handle, "rotation_degrees:z", HANDLE_REST_DEGREES, 0.4)


static func _material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	return material
