extends Unit
class_name UnitParadis

@export var enfer = false

#var inRange = []
#
#func _input(event: InputEvent) -> void:
	#for ennemy in inRange:
		#print(ennemy.global_position)
		#var ennemy_pos = ennemy.global_position
		#$Marker2D.look_at(ennemy_pos)
		#
		#if selected and event.is_action_pressed("tirer"):
			#var arrow_instance = arrow.instantiate()
			#arrow_instance.rotation = $Marker2D.rotation
			#arrow_instance.global_position = $Marker2D.global_position
			#add_child(arrow_instance)
