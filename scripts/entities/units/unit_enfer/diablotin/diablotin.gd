extends Unit

func _ready() -> void:
	# Stats du Diablotin (S - rapide, courte portée)
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
