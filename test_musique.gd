extends Node

var sound_manager: SoundManager

func _ready():
	sound_manager = SoundManager.new()
	add_child(sound_manager)
	
	await get_tree().create_timer(0.5).timeout
	
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				test_single_sound("res://audio/items/bonus/activation_fleche_cupidon_corde_coeur_enchantement.mp3")
			KEY_2:
				test_single_sound("res://audio/items/bonus/benediction_ploutos_cascade_pieces_prosperite.mp3")
			KEY_3:
				test_single_sound("res://audio/items/bonus/activation_glaive_michael_embrasement_legendaire.mp3")

func test_single_sound(sound_path: String):
	var success = SoundManager.play_item_sound(sound_path)
	if success:
		print("✓")
	else:
		print("✗")
