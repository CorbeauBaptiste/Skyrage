extends Unit

var HEALTH = 20

func take_damage():
	HEALTH -= 1
	
	if HEALTH == 0:
		queue_free()
