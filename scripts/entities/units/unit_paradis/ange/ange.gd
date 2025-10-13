extends Unit

func _ready():
	unit_name = "Chérubin"
	unit_size = "M"
	max_health = 800
	base_damage = 300
	base_speed = 24
	attack_range = 150.0
	attack_cooldown = 2.5
	detection_radius = 200.0
	is_hell_faction = false
	
	super._ready()
