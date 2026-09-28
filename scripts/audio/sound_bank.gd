class_name SoundBank
extends Node
## Sound effects (58, 127), generated with ElevenLabs (see
## docs/asset-log.csv): the provisional ones of the combat prototype (phase
## 3) and those of the prologue (phase 4a). Play them from anywhere with
## SoundBank.play_sound(get_tree(), &"name"); GameAudio always holds one.
## Loops (the Generators, the flame, the crowd, the swarm) go through
## GameAudio.play_loop instead.

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
	&"branda_cigolio": preload("res://assets/audio/sfx/branda_cigolio.ogg"),
	&"respiro_risveglio": preload("res://assets/audio/sfx/respiro_risveglio.ogg"),
	&"fruscio_tende": preload("res://assets/audio/sfx/fruscio_tende.ogg"),
	&"lanterna_apre": preload("res://assets/audio/sfx/lanterna_apre.ogg"),
	&"lanterna_chiude": preload("res://assets/audio/sfx/lanterna_chiude.ogg"),
	&"porta_camion_vento": preload("res://assets/audio/sfx/porta_camion_vento.ogg"),
	&"passo_erba": preload("res://assets/audio/sfx/passo_erba.ogg"),
	&"passo_brina": preload("res://assets/audio/sfx/passo_brina.ogg"),
	&"salto": preload("res://assets/audio/sfx/salto.ogg"),
	&"atterraggio": preload("res://assets/audio/sfx/atterraggio.ogg"),
	&"presa_arrampicata": preload("res://assets/audio/sfx/presa_arrampicata.ogg"),
	&"bastone_legno": preload("res://assets/audio/sfx/bastone_legno.ogg"),
	&"bastone_ghiaccio": preload("res://assets/audio/sfx/bastone_ghiaccio.ogg"),
	&"bastone_creatura": preload("res://assets/audio/sfx/bastone_creatura.ogg"),
	&"arbusto_spezza": preload("res://assets/audio/sfx/arbusto_spezza.ogg"),
	&"crosta_spezza": preload("res://assets/audio/sfx/crosta_spezza.ogg"),
	&"coda_libera": preload("res://assets/audio/sfx/coda_libera.ogg"),
	&"brinacchio_sconfitto": preload("res://assets/audio/sfx/brinacchio_sconfitto.ogg"),
	&"respiro_affannato": preload("res://assets/audio/sfx/respiro_affannato.ogg"),
	&"corda_nodo": preload("res://assets/audio/sfx/corda_nodo.ogg"),
	&"tromba_gnomone": preload("res://assets/audio/sfx/tromba_gnomone.ogg"),
	&"colpo_subito_ottavia": preload("res://assets/audio/sfx/colpo_subito_ottavia.ogg"),
}
## Mix: every file is normalized to the same peak, so quiet sounds (steps,
## breaths) are turned down here. Missing names play at 0 dB.
const VOLUMES: Dictionary = {
	&"passo_erba": -14.0,
	&"passo_brina": -12.0,
	&"respiro_risveglio": -6.0,
	&"respiro_affannato": -6.0,
	&"fruscio_tende": -8.0,
	&"salto": -8.0,
	&"atterraggio": -8.0,
	&"presa_arrampicata": -6.0,
	&"tromba_gnomone": -4.0,
	&"porta_camion_vento": -3.0,
}
const VOICES: int = 8

var _players: Array[AudioStreamPlayer] = []
var _next: int = 0


func _enter_tree() -> void:
	add_to_group(&"sound_bank")


func _ready() -> void:
	for index: int in VOICES:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = &"SFX"
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
	# Headless test runs hear nothing, and a one-shot started just before
	# quit() is still held by the audio server at exit (a reported leak).
	if DisplayServer.get_name() == "headless":
		return
	var player: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % _players.size()
	player.stream = SOUNDS[sound]
	player.volume_db = VOLUMES.get(sound, 0.0)
	player.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	player.play()
