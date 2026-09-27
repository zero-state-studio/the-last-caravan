class_name DarkArea
extends Area3D
## A place where the lantern is the main light (45): while Ottavia is inside,
## the lantern light casts shadows. Outside, in daylight, they stay off to
## keep the frame cheap on Steam Deck (7).


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if body is OttaviaProto:
		(body as OttaviaProto).enter_dark_area()


func _on_body_exited(body: Node3D) -> void:
	if body is OttaviaProto:
		(body as OttaviaProto).exit_dark_area()
