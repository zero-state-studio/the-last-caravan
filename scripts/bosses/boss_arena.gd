class_name BossArena
extends Node3D
## A boss room (102): when Ottavia enters, the boss wakes and its name is
## shown; if she falls, the room manager brings her back to the entry and
## the arena and the boss start over (105); when the boss falls, the victory
## is shown. Subclasses reset their own mechanics in _reset_arena().

## Paths, not typed node exports (hand-written .tscn paths, see tecnica.md).
@export var room_path: NodePath
@export var boss_path: NodePath

var room: Room
var boss: BossEnemy
var manager: RoomManager
var won: bool = false


func _ready() -> void:
	room = get_node(room_path) as Room
	boss = get_node(boss_path) as BossEnemy
	boss.defeated.connect(_on_boss_defeated)
	_connect_manager.call_deferred()


func _connect_manager() -> void:
	manager = get_tree().get_first_node_in_group(&"room_manager") as RoomManager
	if manager != null:
		manager.room_changed.connect(_on_room_changed)
		manager.player_respawned.connect(_on_player_respawned)
		manager.room_restarted.connect(_on_room_restarted)


func _on_room_changed(new_room: Room) -> void:
	if new_room == room and not won:
		boss.activate()
		_show(boss.title_key)
	elif new_room != room:
		boss.deactivate()
		_on_left()


func _on_room_restarted(restart_room: Room) -> void:
	if restart_room == room and not won:
		_reset_arena()


func _on_player_respawned(respawn_room: Room) -> void:
	if respawn_room != room or won:
		return
	boss.activate()
	_show(boss.title_key)


func _on_boss_defeated() -> void:
	won = true
	_show(&"BOSS_DEFEATED")
	_on_won()


func _show(key: StringName) -> void:
	var hud: CombatHud = get_tree().get_first_node_in_group(&"combat_hud") as CombatHud
	if hud != null and key != &"":
		hud.show_message(key)


func player() -> OttaviaProto:
	return get_tree().get_first_node_in_group(&"player") as OttaviaProto


# --- For subclasses ----------------------------------------------------------

func _reset_arena() -> void:
	pass


func _on_left() -> void:
	pass


func _on_won() -> void:
	pass
