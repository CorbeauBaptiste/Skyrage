extends Unit

func _ready():
	unit_name = "Diablotin"
	unit_size = "S"
	max_health = 600
	base_damage = 150
	base_speed = 30
	attack_range = 50.0
	attack_cooldown = 1.0
	detection_radius = 200.0
	is_hell_faction = true
	
	super._ready()
