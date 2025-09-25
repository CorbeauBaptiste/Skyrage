extends Projectile

func _on_body_entered(body: Node2D) -> void:
	if body.enfer == true and body.has_method("take_damage"):
		body.take_damage()
		queue_free()
