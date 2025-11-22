extends CanvasLayer

var pause = false
var parametres_instance: Node = null

"Fonction qui permets de mettre en pause en fonction
de si le bouton echap à été présser ou pas"

func pause_unpause():
	pause = !pause
	if pause :
		get_tree().paused = true
		_set_huds_visible(false)  # Cacher les HUDs
		show()
	else :
		get_tree().paused = false
		_set_huds_visible(true)  # Réafficher les HUDs
		hide()

func _set_huds_visible(visible: bool) -> void:
	# Trouve le world et cache/affiche ses HUDs
	var world = get_tree().current_scene
	if world and world.has_method("get") and world.get("ui_layer"):
		world.ui_layer.visible = visible

func _input(event):
	if event.is_action_pressed("pause"):
		# Ne pas fermer la pause si le menu paramètres est ouvert
		if parametres_instance != null:
			return
		pause_unpause()

func _on_param_button_down() -> void:
	# Charger les paramètres en overlay au lieu de changer de scène
	var parametres_scene = load("res://scenes/ui/menus/parametres.tscn")
	var parametres_control = parametres_scene.instantiate()
	parametres_control.connect("fermer_parametres", _on_fermer_parametres)

	# Créer un CanvasLayer pour que les paramètres ne soient pas affectés par la luminosité
	parametres_instance = CanvasLayer.new()
	parametres_instance.layer = 101  # Au-dessus du menu pause
	parametres_instance.process_mode = Node.PROCESS_MODE_ALWAYS
	parametres_instance.add_child(parametres_control)
	get_tree().root.add_child(parametres_instance)
	hide()  # Cacher le menu pause pendant qu'on est dans les paramètres

func _on_fermer_parametres() -> void:
	if parametres_instance != null:
		parametres_instance.queue_free()
		parametres_instance = null
	show()  # Réafficher le menu pause

func _on_quitter_button_down() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/menus/menu_principal.tscn")
