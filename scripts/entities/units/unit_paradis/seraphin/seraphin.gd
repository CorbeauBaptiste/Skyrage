extends Unit

func _ready():
	unit_name = "Séraphin"
	unit_size = "L"
	max_health = 1600
	base_damage = 600
	base_speed = 20
	attack_range = 300.0
	attack_cooldown = 5.0
	detection_radius = 350.0
	is_hell_faction = false
	
	super._ready()

func _spawn_projectile() -> void:
	var projectile = arrow_scene.instantiate() as Projectile
	
	projectile.global_position = projectile_spawn.global_position
	projectile.rotation = projectile_spawn.rotation
	projectile.targets_enfer = true
	projectile.source_unit = self
	
	var final_damage = int(current_damage * damage_multiplier)
	projectile.damage = final_damage
	projectile.is_cupidon_arrow = true  # Utiliser le système de zone
	projectile.area_damage = final_damage
	projectile.area_radius = 80.0
	
	projectile.change_sprite("res://assets/sprites/projectiles/vent.png")
	
	get_parent().add_child(projectile)
	emit_signal("damage_dealt", final_damage)
