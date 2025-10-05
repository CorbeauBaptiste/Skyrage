extends Control
@onready var game_choose = preload("res://scripts/choosemode.tscn")
@onready var settings = preload("res://scripts/paramètres.tscn")
@onready var credits = preload("res://scripts/crédits.tscn")

func _on_start_btn_button_down() -> void:
	get_tree().change_scene_to_packed(game_choose)


func _on_param_btn_button_down() -> void:
	get_tree().change_scene_to_packed(settings)


func _on_credit_btn_button_down() -> void:
	get_tree().change_scene_to_packed(credits)



func _on_quit_btn_button_down() -> void:
	get_tree().quit()
