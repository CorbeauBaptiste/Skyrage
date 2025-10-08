extends Node


var brightness: float = 0.9
var volume: float = 1.0
var music_player: AudioStreamPlayer2D

func _ready():
	if music_player == null:
		music_player = AudioStreamPlayer2D.new()
		music_player.stream = preload("res://assets/audio/menu/musique_menu_principal_orchestrale_epique.mp3")
		music_player.volume_db = lerp(-5, 0, volume)
		add_child(music_player)
		music_player.play()
		music_player.connect("finished", Callable(self, "_on_music_finished"))

func _on_music_finished():
	music_player.play()

func set_volume(value: float) -> void:
	volume = value
	if music_player:
		music_player.volume_db = lerp(-5, 0, volume)
