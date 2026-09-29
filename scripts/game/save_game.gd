class_name SaveGame
extends RefCounted
## Saves (95): one file with GameState and the point of the story where
## Ottavia is (a checkpoint: scene, room, entry, stage of the chapter).
## Written automatically at the start of every Truce and at the entry of
## every dungeon; «Continue» at start reads it back. Three slots and the
## Steam cloud come later (phase 6).

const PATH: String = "user://save_1.json"
const VERSION: int = 1

## Where to put Ottavia after `continue_game` changes scene: read once by
## the level with `take_pending`.
static var _pending: Dictionary = {}
## Tests and captures write elsewhere, not over the player's save.
static var path_override: String = ""


static func path() -> String:
	return path_override if path_override != "" else PATH


static func has_save() -> bool:
	return FileAccess.file_exists(path())


## Writes the state with a checkpoint {"scene", "room", "entry", "stage"}.
static func save(checkpoint: Dictionary) -> Error:
	var data: Dictionary = {
		"version": VERSION,
		"saved_at": Time.get_datetime_string_from_system(),
		"checkpoint": checkpoint,
		"state": GameState.to_data(),
	}
	var file: FileAccess = FileAccess.open(path(), FileAccess.WRITE)
	if file == null:
		push_warning("SaveGame: cannot write %s (error %d)" % [path(), FileAccess.get_open_error()])
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "\t"))
	return OK


## Autosave at a checkpoint of the current scene (95).
static func autosave(tree: SceneTree, room: StringName, entry: StringName, stage: StringName) -> Error:
	return save({"scene": tree.current_scene.scene_file_path, "room": String(room), "entry": String(entry), "stage": String(stage)})


static func read() -> Dictionary:
	if not has_save():
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path()))
	if not parsed is Dictionary or int((parsed as Dictionary).get("version", 0)) != VERSION:
		return {}
	return parsed


## Loads the state and goes to the saved scene; false when there is no
## readable save.
static func continue_game(tree: SceneTree) -> bool:
	var data: Dictionary = read()
	if data.is_empty():
		return false
	var checkpoint: Dictionary = data.get("checkpoint", {})
	var scene: String = str(checkpoint.get("scene", ""))
	if scene == "" or not ResourceLoader.exists(scene):
		return false
	GameState.reset()
	GameState.from_data(data.get("state", {}))
	_pending = checkpoint
	tree.change_scene_to_file(scene)
	return true


## The checkpoint to restore in `scene_path`, once; empty when none.
static func take_pending(scene_path: String) -> Dictionary:
	if _pending.is_empty() or str(_pending.get("scene", "")) != scene_path:
		return {}
	var checkpoint: Dictionary = _pending
	_pending = {}
	return checkpoint


## Sets a pending checkpoint by hand (tests, dev arguments).
static func set_pending(checkpoint: Dictionary) -> void:
	_pending = checkpoint
