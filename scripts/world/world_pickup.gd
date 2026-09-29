class_name WorldPickup
extends Area3D
## An item lying in the world (128): walking onto it puts it in the
## bisaccia, without a button (only people take the interact action, 67).
## Once taken it is gone for good, also after a save (GameState.taken); a
## warm stone stays where it is while Ottavia already carries the maximum.
## A small glint marks it until the final models (phase 4b step 4).

signal picked(item_id: StringName)

@export var item_id: StringName
## Unique in the whole game, for example "c01_truce_felt".
@export var pickup_id: StringName
@export var glint_color: Color = Color(1.0, 0.85, 0.5)

var _time: float = 0.0
var _marker: MeshInstance3D
var _light: OmniLight3D


func _ready() -> void:
	if GameState.is_taken(pickup_id):
		queue_free()
		return
	monitoring = true
	var shape: CollisionShape3D = CollisionShape3D.new()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 0.7
	shape.shape = sphere
	shape.position = Vector3.UP * 0.5
	add_child(shape)
	_marker = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(0.28, 0.2, 0.28)
	_marker.mesh = mesh
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = glint_color
	material.emission_enabled = true
	material.emission = glint_color
	material.emission_energy_multiplier = 1.2
	_marker.material_override = material
	_marker.position = Vector3.UP * 0.2
	add_child(_marker)
	_light = OmniLight3D.new()
	_light.light_color = glint_color
	_light.light_energy = 0.6
	_light.omni_range = 1.4
	_light.position = Vector3.UP * 0.5
	add_child(_light)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	_marker.position.y = 0.2 + 0.06 * sin(_time * 3.0)
	_marker.rotation.y = _time * 1.2
	_light.light_energy = 0.45 + 0.2 * sin(_time * 5.0)


func _on_body_entered(body: Node3D) -> void:
	var ottavia: OttaviaProto = body as OttaviaProto
	if ottavia == null:
		return
	take(ottavia)


func take(ottavia: OttaviaProto) -> bool:
	if not GameState.receive(item_id, ottavia.combat.tuning.warm_stone_max):
		return false
	GameState.mark_taken(pickup_id)
	SoundBank.play_sound(get_tree(), &"presa_arrampicata")
	picked.emit(item_id)
	queue_free()
	return true
