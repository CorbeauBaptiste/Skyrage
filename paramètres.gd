extends Control
@onready var exit =preload("res://menuprincipal.tscn")

func _on_exit_button_down() -> void:
	get_tree().change_scene_to_packed(exit)
