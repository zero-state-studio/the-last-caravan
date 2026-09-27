class_name BossEnemy
extends CombatEnemy
## Base of the chapter bosses (35, 36): a name shown with a health bar while
## the fight is on, and a fight that restarts from the beginning when
## Ottavia falls (105).

@export var title_key: StringName = &""

var active: bool = false


func shows_health_bar() -> bool:
	return false


func targets_companions() -> bool:
	return false


func activate() -> void:
	active = true
	add_to_group(&"active_boss")


func deactivate() -> void:
	active = false
	remove_from_group(&"active_boss")


func _on_defeated() -> void:
	deactivate()
	var tween: Tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 1.2)


func _on_reset() -> void:
	sprite.modulate.a = 1.0
