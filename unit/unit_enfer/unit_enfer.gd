extends Unit
class_name UnitEnfer

@export var enfer = true

#func _input(event: InputEvent) -> void:
	#var mouse_pos = get_global_mouse_position()
	#$Marker2D.look_at(mouse_pos)
	#
	#if selected and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		#var arrow_instance = arrow.instantiate()
		#arrow_instance.rotation = $Marker2D.rotation
		#arrow_instance.global_position = $Marker2D.global_position
		#add_child(arrow_instance)
