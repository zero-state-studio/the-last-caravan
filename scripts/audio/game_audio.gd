class_name GameAudio
extends Node
## The sound of the game across scenes (57, 58, 59).
## - Music (126) on the Music bus, with a crossfade between pieces, so a
##   piece can go on from one scene to the next.
## - Ambient loops (127: the Generators' beat, the flame, the crowd, the
##   swarm) by name, faded in and out.
## - Voices (59) by line ID: `assets/audio/voice/<language>/<ID>.ogg`, with
##   Italian as the fallback while the voices are only Italian.
## - One-shot effects keep going through SoundBank (a SoundBank child lives
##   here, so every scene has one).
## The node is the autoload `GameAudioNode`; call the static functions
## (GameAudio.play_music...), which do nothing where there is no autoload
## (headless test scripts).

const VOICE_DIR: String = "res://assets/audio/voice/"
const VOICE_FALLBACK: String = "it"
const SILENT_DB: float = -60.0
const NODE_PATH: NodePath = ^"/root/GameAudioNode"
## Voices come first (126): while one speaks the music goes down this much,
## and comes back up in the pauses.
const DUCK_DB: float = -10.0
const DUCK_DOWN_DB_PER_SECOND: float = 40.0
const DUCK_UP_DB_PER_SECOND: float = 16.0
## A voice placed in the world (the verdict chain): full at this distance
## from the listener, softer farther away.
const VOICE_3D_UNIT_METERS: float = 10.0
const VOICE_3D_MAX_METERS: float = 150.0

var _music: Array[AudioStreamPlayer] = []
var _music_on: int = 0
var _music_tween: Tween
var _current_music: AudioStream
var _loops: Dictionary = {}
var _loop_tweens: Dictionary = {}
var _voice: AudioStreamPlayer
var _voice_3d: AudioStreamPlayer3D
## When the voice now speaking ends (msec); kept even where nothing is heard.
var _voice_end_msec: int = 0
var _duck_db: float = 0.0
var _music_bus: int = -1
## Loops started and not stopped (their state, whether audible or not).
var _active_loops: Dictionary = {}
## Headless test runs keep the state but start no playback: a stream still
## playing at quit() is reported as a leak by the audio server.
var _audible: bool = DisplayServer.get_name() != "headless"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var bank: SoundBank = SoundBank.new()
	bank.name = "SoundBank"
	add_child(bank)
	for index: int in 2:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = &"Music"
		add_child(player)
		_music.append(player)
	_voice = AudioStreamPlayer.new()
	_voice.bus = &"Voice"
	add_child(_voice)
	_voice_3d = AudioStreamPlayer3D.new()
	_voice_3d.bus = &"Voice"
	_voice_3d.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	_voice_3d.unit_size = VOICE_3D_UNIT_METERS
	_voice_3d.max_distance = VOICE_3D_MAX_METERS
	add_child(_voice_3d)
	_music_bus = AudioServer.get_bus_index(&"Music")


func _process(delta: float) -> void:
	var target: float = DUCK_DB if _is_voice_playing() else 0.0
	var rate: float = DUCK_DOWN_DB_PER_SECOND if target < _duck_db else DUCK_UP_DB_PER_SECOND
	_duck_db = move_toward(_duck_db, target, rate * delta)
	if _music_bus >= 0:
		AudioServer.set_bus_volume_db(_music_bus, _duck_db)


func _exit_tree() -> void:
	var players: Array[AudioStreamPlayer] = [_voice]
	players.append_array(_music)
	for player: AudioStreamPlayer in _loops.values():
		players.append(player)
	for player: AudioStreamPlayer in players:
		player.stop()
		player.stream = null
	_voice_3d.stop()
	_voice_3d.stream = null
	_current_music = null


## Crossfades to `stream` (null fades the music out). The same stream
## already playing goes on untouched.
func _play_music(stream: AudioStream, fade_seconds: float = 1.5, volume_db: float = 0.0) -> void:
	var current: AudioStreamPlayer = _music[_music_on]
	if stream != null and stream == _current_music:
		return
	_current_music = stream
	if _music_tween != null:
		_music_tween.kill()
	if stream == null and not current.playing:
		return
	_music_tween = create_tween().set_parallel(true)
	if stream != null:
		_music_on = 1 - _music_on
		var next: AudioStreamPlayer = _music[_music_on]
		next.stream = stream
		next.volume_db = SILENT_DB if fade_seconds > 0.0 else volume_db
		if _audible:
			next.play()
		_music_tween.tween_property(next, "volume_db", volume_db, maxf(fade_seconds, 0.01))
	if current.playing:
		_music_tween.tween_property(current, "volume_db", SILENT_DB, maxf(fade_seconds, 0.01))
		_music_tween.chain().tween_callback(current.stop)


func _stop_music(fade_seconds: float = 1.5) -> void:
	_play_music(null, fade_seconds)


## The piece playing (or fading in), null after stop_music.
func _music_stream() -> AudioStream:
	return _current_music


## Starts (or retunes) a named ambient loop.
func _play_loop(loop_name: StringName, stream: AudioStream, volume_db: float = 0.0, fade_seconds: float = 1.0, pitch: float = 1.0) -> void:
	var player: AudioStreamPlayer = _loops.get(loop_name)
	if player == null:
		player = AudioStreamPlayer.new()
		player.bus = &"SFX"
		add_child(player)
		_loops[loop_name] = player
	if player.stream != stream or not _active_loops.has(loop_name):
		player.stream = stream
		player.volume_db = SILENT_DB if fade_seconds > 0.0 else volume_db
		if _audible:
			player.play()
	_active_loops[loop_name] = true
	player.pitch_scale = pitch
	_fade_loop(loop_name, player, volume_db, fade_seconds, false)


func _stop_loop(loop_name: StringName, fade_seconds: float = 1.0) -> void:
	var player: AudioStreamPlayer = _loops.get(loop_name)
	if player != null and _active_loops.has(loop_name):
		_active_loops.erase(loop_name)
		_fade_loop(loop_name, player, SILENT_DB, fade_seconds, true)


func _is_loop_playing(loop_name: StringName) -> bool:
	var player: AudioStreamPlayer = _loops.get(loop_name)
	return player != null and _active_loops.has(loop_name)


func _stop_all(fade_seconds: float = 0.5) -> void:
	_stop_music(fade_seconds)
	for loop_name: StringName in _loops:
		_stop_loop(loop_name, fade_seconds)
	_voice.stop()


func _fade_loop(loop_name: StringName, player: AudioStreamPlayer, volume_db: float, fade_seconds: float, then_stop: bool) -> void:
	var previous: Tween = _loop_tweens.get(loop_name)
	if previous != null:
		previous.kill()
	var tween: Tween = create_tween()
	tween.tween_property(player, "volume_db", volume_db, maxf(fade_seconds, 0.01))
	if then_stop:
		tween.tween_callback(player.stop)
	_loop_tweens[loop_name] = tween


## Plays the recorded voice of a line, if there is one; returns its length
## in seconds (0 when the line has no voice yet).
func _play_voice(line_key: StringName, volume_db: float = 0.0) -> float:
	var stream: AudioStream = voice_stream(line_key)
	_stop_voice()
	if stream == null:
		return 0.0
	_voice.stream = stream
	_voice.volume_db = volume_db
	if _audible:
		_voice.play()
	_voice_end_msec = Time.get_ticks_msec() + int(stream.get_length() * 1000.0)
	return stream.get_length()


## A voice heard from a point in the world: far away it is soft and comes
## from its side of the screen.
func _play_voice_at(line_key: StringName, at: Vector3, volume_db: float = 0.0) -> float:
	var stream: AudioStream = voice_stream(line_key)
	_stop_voice()
	if stream == null:
		return 0.0
	_voice_3d.stream = stream
	_voice_3d.volume_db = volume_db
	_voice_3d.global_position = at
	if _audible:
		_voice_3d.play()
	_voice_end_msec = Time.get_ticks_msec() + int(stream.get_length() * 1000.0)
	return stream.get_length()


func _stop_voice() -> void:
	_voice.stop()
	_voice_3d.stop()
	_voice_end_msec = 0


func _is_voice_playing() -> bool:
	return Time.get_ticks_msec() < _voice_end_msec


static func _node() -> GameAudio:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	return tree.root.get_node_or_null(NODE_PATH) as GameAudio if tree != null else null


static func play_music(stream: AudioStream, fade_seconds: float = 1.5, volume_db: float = 0.0) -> void:
	var node: GameAudio = _node()
	if node != null:
		node._play_music(stream, fade_seconds, volume_db)


static func stop_music(fade_seconds: float = 1.5) -> void:
	var node: GameAudio = _node()
	if node != null:
		node._stop_music(fade_seconds)


static func music_stream() -> AudioStream:
	var node: GameAudio = _node()
	return node._music_stream() if node != null else null


static func play_loop(loop_name: StringName, stream: AudioStream, volume_db: float = 0.0, fade_seconds: float = 1.0, pitch: float = 1.0) -> void:
	var node: GameAudio = _node()
	if node != null:
		node._play_loop(loop_name, stream, volume_db, fade_seconds, pitch)


static func stop_loop(loop_name: StringName, fade_seconds: float = 1.0) -> void:
	var node: GameAudio = _node()
	if node != null:
		node._stop_loop(loop_name, fade_seconds)


static func is_loop_playing(loop_name: StringName) -> bool:
	var node: GameAudio = _node()
	return node != null and node._is_loop_playing(loop_name)


static func stop_all(fade_seconds: float = 0.5) -> void:
	var node: GameAudio = _node()
	if node != null:
		node._stop_all(fade_seconds)


static func play_voice(line_key: StringName, volume_db: float = 0.0) -> float:
	var node: GameAudio = _node()
	return node._play_voice(line_key, volume_db) if node != null else 0.0


static func play_voice_at(line_key: StringName, at: Vector3, volume_db: float = 0.0) -> float:
	var node: GameAudio = _node()
	return node._play_voice_at(line_key, at, volume_db) if node != null else 0.0


## How far the music is pulled down under the voices now (dB, 0 or less).
static func music_duck_db() -> float:
	var node: GameAudio = _node()
	return node._duck_db if node != null else 0.0


static func stop_voice() -> void:
	var node: GameAudio = _node()
	if node != null:
		node._stop_voice()


static func is_voice_playing() -> bool:
	var node: GameAudio = _node()
	return node != null and node._is_voice_playing()


## A sound effect file by name, for loops (one-shots go through SoundBank).
static func load_sfx(sound: StringName) -> AudioStream:
	return load("res://assets/audio/sfx/%s.ogg" % sound)


static func voice_stream(line_key: StringName) -> AudioStream:
	if String(line_key).is_empty():
		return null
	var language: String = TranslationServer.get_locale().substr(0, 2)
	for folder: String in [language, VOICE_FALLBACK]:
		var path: String = VOICE_DIR + folder + "/" + String(line_key) + ".ogg"
		if ResourceLoader.exists(path):
			return load(path)
	return null
