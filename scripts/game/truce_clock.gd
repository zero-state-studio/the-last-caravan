class_name TruceClock
extends Node
## The time of the Truce (39, 125): the shadow on the sundial grows from
## start to end. At the start Ottavia is at the caravan (patches can be
## sewn) and her warm stones come back (129); a minute before the end comes
## the warning; inside a dungeon room the clock stops (38, the caravan
## waits); at the end `expired` tells the level (chapter 1: Iole runs to
## Ottavia). The first Truce shows the two hints of the sundial.

signal started
signal warning
signal expired

const HINT_SUNDIAL: StringName = &"HINT_TRUCE_SUNDIAL"
const HINT_LEFT_BEHIND: StringName = &"HINT_TRUCE_LEFT_BEHIND"
const HINT_SECONDS: float = 5.0
const HINTS_FLAG: StringName = &"hint_truce_sundial"

@export var tuning: ChapterTuning
## Paths, not typed node exports (see docs/tecnica.md).
@export var room_manager_path: NodePath

var seconds_left: float = 0.0
var running: bool = false
## Stopped by a dungeon room (or by a scene, for a dialogue).
var paused: bool = false
var _warned: bool = false
var _hint_left: float = 0.0
var _hint_step: int = 0
var _manager: RoomManager


func _ready() -> void:
	add_to_group(&"truce_clock")
	if tuning == null:
		tuning = ChapterTuning.new()
	if not room_manager_path.is_empty():
		bind_rooms(get_node(room_manager_path) as RoomManager)


## The clock stops in dungeon rooms: it follows the rooms of `manager`.
func bind_rooms(manager: RoomManager) -> void:
	_manager = manager
	if not _manager.room_changed.is_connected(_on_room_changed):
		_manager.room_changed.connect(_on_room_changed)


func start(max_stones: int = -1) -> void:
	seconds_left = tuning.truce_seconds
	running = true
	paused = false
	_warned = false
	GameState.at_caravan = true
	GameState.refill_warm_stones(tuning.truce_warm_stones if max_stones < 0 else mini(tuning.truce_warm_stones, max_stones))
	if _manager != null and _manager.current_room != null:
		paused = _manager.current_room.dungeon
	started.emit()
	if not GameState.has_flag(HINTS_FLAG):
		GameState.set_flag(HINTS_FLAG)
		_hint_step = 1
		_hint_left = HINT_SECONDS
		_show_hint(HINT_SUNDIAL)


## The Truce is over for good (the dungeon was entered or the time ran out).
func stop() -> void:
	running = false
	GameState.at_caravan = false


## Share of the Truce gone, 0 at the start, 1 at the end: the shadow.
func share() -> float:
	if tuning.truce_seconds <= 0.0:
		return 1.0
	return clampf(1.0 - seconds_left / tuning.truce_seconds, 0.0, 1.0)


func in_warning() -> bool:
	return running and seconds_left <= tuning.truce_warning_seconds


func _process(delta: float) -> void:
	_update_hints(delta)
	if not running or paused:
		return
	seconds_left = maxf(0.0, seconds_left - delta)
	if not _warned and seconds_left <= tuning.truce_warning_seconds:
		_warned = true
		warning.emit()
	if seconds_left <= 0.0:
		stop()
		expired.emit()


func _on_room_changed(room: Room) -> void:
	paused = room.dungeon
	GameState.at_caravan = running and not room.dungeon


func _update_hints(delta: float) -> void:
	if _hint_step == 0:
		return
	_hint_left -= delta
	if _hint_left > 0.0:
		return
	if _hint_step == 1:
		_hint_step = 2
		_hint_left = HINT_SECONDS
		_show_hint(HINT_LEFT_BEHIND)
		return
	_hint_step = 0
	var banner: HintBanner = get_tree().get_first_node_in_group(&"hint_banner") as HintBanner
	if banner != null and banner.current_hint() == HINT_LEFT_BEHIND:
		banner.hide_hint()


func _show_hint(key: StringName) -> void:
	var banner: HintBanner = get_tree().get_first_node_in_group(&"hint_banner") as HintBanner
	if banner != null:
		banner.show_hint(key, &"")
