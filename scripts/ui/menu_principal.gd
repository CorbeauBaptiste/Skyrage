extends Control
@onready var game_choose = preload("res://scenes/ui/menus/choose_mode.tscn")
@onready var settings = preload("res://scenes/ui/menus/parametres.tscn")
@onready var credits = preload("res://scenes/ui/menus/credits.tscn")

func _on_start_btn_button_down() -> void:
	get_tree().change_scene_to_packed(game_choose)


func _on_param_btn_button_down() -> void:
	get_tree().change_scene_to_packed(settings)


func _on_credit_btn_button_down() -> void:
	get_tree().change_scene_to_packed(credits)



func _on_quit_btn_button_down() -> void:
	get_tree().quit()
