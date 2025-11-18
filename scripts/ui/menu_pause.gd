extends CanvasLayer

var pause = false

"Fonction qui permets de mettre en pause en fonction 
de si le bouton echap à été présser ou pas"

func pause_unpause():
	pause = !pause
	if pause : 
		get_tree().paused = true
		show()
	else : 
		get_tree().paused = false
		hide()

func _input(event):
	if event.is_action_pressed("pause"):
		pause_unpause()

func _on_param_button_down() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/menus/parametres.tscn")

func _on_quitter_button_down() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/menus/menu_principal.tscn")
