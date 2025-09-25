extends Control
@onready var exit =preload("res://menuprincipal.tscn")

func _on_button_exit_down() -> void:
	get_tree().change_scene_to_packed(exit)
