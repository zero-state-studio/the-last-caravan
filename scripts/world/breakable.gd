class_name Breakable
extends CombatEnemy
## Something that breaks under the staff (106): dry bushes, fallen branches
## and crusts of frost blocking a wheel or a Tail. It is a combat target so
## strikes and the aim assist find it, but it never attacks or moves.
## `model` is shown until it breaks; then it bursts into chips and hides.

signal broken

@export var model: Node3D
@export var chip_color: Color = Color(0.85, 0.9, 1.0)


func _ready() -> void:
	super._ready()
	radius = 0.5


func shows_health_bar() -> bool:
	return false


func _behave(_delta: float) -> void:
	velocity = Vector3.ZERO


func _on_hit(_hit: CombatHit) -> void:
	CombatEffects.spark(get_tree().current_scene, global_position + Vector3.UP * 0.4, chip_color, 10.0)


func _on_defeated() -> void:
	CombatEffects.spark(get_tree().current_scene, global_position + Vector3.UP * 0.4, chip_color, 22.0)
	if model != null:
		model.visible = false
	broken.emit()


func _on_reset() -> void:
	if model != null:
		model.visible = true


## A breakable built from code: an invisible body with `model` as its look.
static func create(parent: Node3D, at: Vector3, look: Node3D, health: float, color: Color) -> Breakable:
	var item: Breakable = Breakable.new()
	item.max_health = health
	item.chip_color = color
	item.collision_layer = 1
	var shape: CollisionShape3D = CollisionShape3D.new()
	var cylinder: CylinderShape3D = CylinderShape3D.new()
	cylinder.radius = 0.45
	cylinder.height = 0.8
	shape.shape = cylinder
	shape.position = Vector3.UP * 0.4
	item.add_child(shape)
	var sprite: Sprite3D = Sprite3D.new()
	sprite.name = "Sprite3D"
	sprite.visible = false
	item.add_child(sprite)
	item.add_child(look)
	item.model = look
	item.position = at
	parent.add_child(item)
	return item
