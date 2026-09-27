class_name Interactable
extends Node3D
## Something Ottavia can use with the interact action (A, E): levers,
## doors, people. The nearest one within `radius` is used.

signal used

@export var radius: float = 1.6


func _enter_tree() -> void:
	add_to_group(&"interactables")


## Called by Ottavia; override to add behaviour, and call super.
func use() -> void:
	used.emit()


func can_use() -> bool:
	return true
