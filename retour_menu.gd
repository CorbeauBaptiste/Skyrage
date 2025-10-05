extends Button

func _on_button_down() -> void:
	get_tree().change_scene_to_file("res://scripts/menuprincipal.tscn")
