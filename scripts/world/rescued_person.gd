class_name RescuedPerson
extends Interactable
## Someone lost in a dungeon (38): Ottavia reaches them and, with the
## interact action, ties them to the rope. A knot tightens on the rope
## (125), the first time the hint «Those you save open the way back»
## appears, their shortcut opens, and they walk home along it alone, without
## an escort (chapter 1, section 4). The level adds their lines through
## `tied`. Saved once, they are gone for good (a GameState flag).

signal tied
signal walked_home

## Unique in the game, for example "c01_saved_pia".
@export var person_id: StringName
## Path, not a typed node export (see docs/tecnica.md).
@export var shortcut_path: NodePath
@export var walk_speed: float = 1.6
## The level waits for its dialogue before the walk home.
@export var wait_for_level: bool = false

const HINT_FLAG: StringName = &"hint_saved_open_way"
const HINT_SECONDS: float = 5.0

var shortcut: RescueShortcut
var saved: bool = false
## Not reachable yet (Pia in the cage of plants, room 6).
var locked: bool = false
var _going_home: bool = false


func _ready() -> void:
	if not shortcut_path.is_empty():
		shortcut = get_node_or_null(shortcut_path) as RescueShortcut
	if GameState.has_flag(person_id):
		saved = true
		visible = false


func can_use() -> bool:
	return not saved and not locked


func use() -> void:
	if saved:
		return
	saved = true
	var ottavia: OttaviaProto = get_tree().get_first_node_in_group(&"player") as OttaviaProto
	if ottavia != null:
		ottavia.controls_enabled = false
		ottavia.face_toward(global_position - ottavia.global_position)
		await ottavia.play_scripted("tie_rope")
		ottavia.stop_scripted()
		ottavia.controls_enabled = true
	GameState.set_flag(person_id)
	GameState.add_knot()
	SoundBank.play_sound(get_tree(), &"corda_nodo", 0.0)
	var rope: RopeCounter = get_tree().get_first_node_in_group(&"rope_counter") as RopeCounter
	if rope != null:
		rope.add_knot()
	_show_first_hint()
	super.use()
	tied.emit()
	if not wait_for_level:
		go_home()


## Opens the shortcut and walks along it, then leaves the scene.
func go_home() -> void:
	if _going_home:
		return
	_going_home = true
	if shortcut != null:
		await shortcut.open()
		for point: Vector3 in shortcut.path_points():
			await _walk_to(point)
	visible = false
	walked_home.emit()


func _walk_to(point: Vector3) -> void:
	while is_inside_tree() and global_position.distance_to(point) > 0.05:
		var step: float = walk_speed * get_physics_process_delta_time()
		global_position = global_position.move_toward(point, step)
		await get_tree().physics_frame


func _show_first_hint() -> void:
	if GameState.has_flag(HINT_FLAG):
		return
	GameState.set_flag(HINT_FLAG)
	var banner: HintBanner = get_tree().get_first_node_in_group(&"hint_banner") as HintBanner
	if banner == null:
		return
	banner.show_hint(&"HINT_SAVED_OPEN_WAY", &"")
	get_tree().create_timer(HINT_SECONDS).timeout.connect(func() -> void:
		if is_instance_valid(banner) and banner.current_hint() == &"HINT_SAVED_OPEN_WAY":
			banner.hide_hint())
