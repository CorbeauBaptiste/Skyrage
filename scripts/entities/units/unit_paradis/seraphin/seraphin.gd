extends Unit

func _ready() -> void:
	# Stats du Séraphin (L - lent, AoE)
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
	_setup_nodes()

func _physics_process(delta: float) -> void:
	# 1. Si on attaque, on bouge pas
	if is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	# 2. Combat si ennemi à portée
	if current_enemy and is_instance_valid(current_enemy):
		_handle_combat()
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	# 3. Déplacement normal
	if not target:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	var target_pos = target if target is Vector2 else target.global_position if target else Vector2.ZERO
	var distance = global_position.distance_to(target_pos)
	
	# Si à portée, on s'arrête
	if distance <= attack_range:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	# Sinon on avance
	var direction = global_position.direction_to(target_pos)
	_apply_movement_with_avoidance(direction)
	
	move_and_slide()
	_update_animation()

# Override pour attaque AoE
func _spawn_projectile() -> void:
	var projectile = arrow_scene.instantiate() as Projectile
	
	projectile.global_position = projectile_spawn.global_position
	projectile.rotation = projectile_spawn.rotation
	projectile.targets_enfer = true
	projectile.source_unit = self
	
	var final_damage = int(current_damage * damage_multiplier)
	projectile.damage = final_damage
	
	# Attaque de zone
	projectile.is_cupidon_arrow = true
	projectile.area_damage = final_damage
	projectile.area_radius = 80.0
	
	projectile.change_sprite("res://assets/sprites/projectiles/vent.png")
	
	get_parent().add_child(projectile)
	emit_signal("damage_dealt", final_damage)
