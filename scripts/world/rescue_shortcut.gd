class_name RescueShortcut
extends Node3D
## The way back that a saved person opens with Ottavia (chapter 1, section
## 4): a rope ladder let down, a plank bridge lowered, a rope tied to a
## post. Everything under this node stays hidden and without collision
## until `open`, then grows into place; it stays open for the rest of the
## dungeon and after a save (a GameState flag). Its Marker3D children, in
## order, are the path the saved person walks home alone.

signal opened

## Unique in the game, for example "c01_shortcut_ruggero".
@export var shortcut_id: StringName
@export var open_seconds: float = 1.2
## How it appears: the ladder unrolls downward (scale on Y from the top),
## the bridge swings down (rotation on X), or it simply fades in.
@export_enum("unroll", "lower", "appear") var reveal: String = "unroll"

var is_open: bool = false


func _ready() -> void:
	# Deferred: the level may add the pieces after adding this node.
	_set_open.call_deferred(GameState.has_flag(shortcut_id))


func open() -> void:
	if is_open:
		return
	GameState.set_flag(shortcut_id)
	_set_open(true)
	# Provisional sound until the chapter 1 effects (phase 4b step 5).
	SoundBank.play_sound(get_tree(), &"corda_nodo", 0.0)
	var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	match reveal:
		"unroll":
			scale = Vector3(1.0, 0.05, 1.0)
			tween.tween_property(self, "scale", Vector3.ONE, open_seconds)
		"lower":
			rotation.x = -PI * 0.5
			tween.tween_property(self, "rotation:x", 0.0, open_seconds)
		_:
			scale = Vector3.ONE * 0.05
			tween.tween_property(self, "scale", Vector3.ONE, open_seconds)
	await tween.finished
	opened.emit()


## The markers under this node, in order: the walk home.
func path_points() -> Array[Vector3]:
	var points: Array[Vector3] = []
	for node: Node in find_children("*", "Marker3D", true, false):
		points.append((node as Marker3D).global_position)
	return points


func _set_open(value: bool) -> void:
	is_open = value
	visible = value
	for node: Node in find_children("*", "CollisionShape3D", true, false):
		if not node.get_parent() is Area3D:
			(node as CollisionShape3D).set_deferred(&"disabled", not value)
	for node: Node in find_children("*", "Area3D", true, false):
		(node as Area3D).set_deferred(&"monitoring", value)
