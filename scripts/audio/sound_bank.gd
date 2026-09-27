class_name SoundBank
extends Node
## Provisional sound effects of the combat prototype (phase 3, generated with
## ElevenLabs, see docs/asset-log.csv). Play them from anywhere with
## SoundBank.play_sound(get_tree(), &"name").

const SOUNDS: Dictionary = {
	&"colpo_bastone": preload("res://assets/audio/sfx/colpo_bastone.ogg"),
	&"parata": preload("res://assets/audio/sfx/parata.ogg"),
	&"deviazione": preload("res://assets/audio/sfx/deviazione.ogg"),
	&"passo": preload("res://assets/audio/sfx/passo.ogg"),
	&"sportello_lanterna": preload("res://assets/audio/sfx/sportello_lanterna.ogg"),
	&"uncino": preload("res://assets/audio/sfx/uncino.ogg"),
	&"colpo_subito": preload("res://assets/audio/sfx/colpo_subito.ogg"),
	&"nemico_colpito": preload("res://assets/audio/sfx/nemico_colpito.ogg"),
	&"nemico_sconfitto": preload("res://assets/audio/sfx/nemico_sconfitto.ogg"),
	&"fiato_esaurito": preload("res://assets/audio/sfx/fiato_esaurito.ogg"),
	&"segnale_enea": preload("res://assets/audio/sfx/segnale_enea.ogg"),
	&"rampone_tosca": preload("res://assets/audio/sfx/rampone_tosca.ogg"),
}
const VOICES: int = 8

var _players: Array[AudioStreamPlayer] = []
var _next: int = 0


func _enter_tree() -> void:
	add_to_group(&"sound_bank")


func _ready() -> void:
	for index: int in VOICES:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)


func _exit_tree() -> void:
	for player: AudioStreamPlayer in _players:
		player.stop()
		player.stream = null


static func play_sound(tree: SceneTree, sound: StringName, pitch_jitter: float = 0.05) -> void:
	var bank: SoundBank = tree.get_first_node_in_group(&"sound_bank") as SoundBank
	if bank != null:
		bank.play(sound, pitch_jitter)


func play(sound: StringName, pitch_jitter: float = 0.05) -> void:
	if not SOUNDS.has(sound):
		push_warning("SoundBank: unknown sound %s" % sound)
		return
	var player: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % _players.size()
	player.stream = SOUNDS[sound]
	player.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	player.play()
