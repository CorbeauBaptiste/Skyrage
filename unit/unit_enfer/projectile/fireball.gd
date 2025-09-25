extends Projectile

func _on_body_entered(body: Node2D) -> void:
	if body.enfer == false:
		body.set_health(body.get_health() - 1)
		queue_free()
