extends UnitParadis

var HEALTH = 1

func take_damage():
	HEALTH -= 1
	
	if HEALTH == 0:
		queue_free()

func _on_range_body_entered(body: Node2D) -> void:
	inRange.append(body)

func _on_range_body_exited(body: Node2D) -> void:
	inRange.erase(body)
