class_name SoundManager
extends Node

static var instance: SoundManager

var item_players: Array[AudioStreamPlayer] = []
var max_item_sounds: int = 5

var sound_cache: Dictionary = {}

func _ready():
	# Creer le singleton	
	if instance == null:
		instance = self
		setup_audio_pool()
	else:
		queue_free()

func setup_audio_pool():
	# Pool pour les sons d'items
	for i in max_item_sounds:
		var player = AudioStreamPlayer.new()
		add_child(player)
		item_players.append(player)

static func play_item_sound(sound_path: String, volume_db: float = 0.0, pitch: float = 1.0) -> bool:
	if not instance:
		return false
	
	return instance._play_item_sound(sound_path, volume_db, pitch)

func _play_item_sound(sound_path: String, volume_db: float, pitch: float) -> bool:
	var audio_stream = get_or_load_sound(sound_path)
	if not audio_stream:
		return false
	
	var player = get_available_player()
	if not player:
		return false
	
	player.stream = audio_stream
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()
	
	return true

func get_or_load_sound(sound_path: String) -> AudioStream:
	if sound_cache.has(sound_path):
		return sound_cache[sound_path]
	
	if not ResourceLoader.exists(sound_path):
		push_error("Son introuvable: " + sound_path)
		return null
	
	var audio_stream = load(sound_path)
	if audio_stream:
		sound_cache[sound_path] = audio_stream
	
	return audio_stream

func get_available_player() -> AudioStreamPlayer:
	""" Trouve un player libre dans le pool, sinon interrompt le premier """
	for player in item_players:
		if not player.playing:
			return player
	
	return item_players[0]
