extends Unit

func _ready():
	unit_name = "Ange Déchu"
	unit_size = "M"
	max_health = 900
	base_damage = 250
	base_speed = 24
	attack_range = 150.0
	attack_cooldown = 2.0
	detection_radius = 200.0
	is_hell_faction = true
	
	super._ready()
