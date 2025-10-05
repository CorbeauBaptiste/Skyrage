extends CharacterBody2D
class_name Unit

@export var speed = 100: set = set_speed
@export var enfer = false: set = set_side
@export var health = 20: set = set_health
@export var attack_speed = 1: set = set_attack_speed

# Modificateurs d'effets d'items
var base_speed: float = 100.0  # Vitesse de base pour restauration
var speed_multiplier: float = 1.0  # Multiplicateur de vitesse
var damage_multiplier: float = 1.0  # Multiplicateur de dégâts
var attack_cooldown_modifier: float = 0.0  # Modificateur de cooldown en secondes

var av = Vector2.ZERO
var avoid_weight = 0.1
var target_radius = 50
var selected = false:
	set = set_selected
var target = null:
	set = set_target

var arrow = preload("res://projectile.tscn"):
	set = set_arrow

func set_selected(value):
	selected = value
	if selected:
		$Sprite2D.self_modulate = Color.AQUA
	else:
		$Sprite2D.self_modulate = Color.WHITE

func set_target(value):
	target = value

func set_arrow(value):
	arrow = value

func set_side(value):
	enfer = value
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color.RED if enfer else Color.WHITE
	print("Unit set_side: ", enfer)

func avoid():
	var result = Vector2.ZERO
	var neighbors = $Detect.get_overlapping_bodies()
	if neighbors:
		for i in neighbors:
			result += i.position.direction_to(position)
		result /= neighbors.size()
	return result.normalized()

func _physics_process(delta: float) -> void:
	velocity = Vector2.ZERO
	if target:
		var target_pos = target if target is Vector2 else target.global_position if target else Vector2.ZERO
		velocity = position.direction_to(target_pos)
		if position.distance_to(target_pos) < target_radius:
			target = null
	av = avoid()
	# Appliquer le multiplicateur de vitesse
	var effective_speed = speed * speed_multiplier
	velocity = (velocity + av * avoid_weight).normalized() * effective_speed
	move_and_collide(velocity * delta)
	if velocity != Vector2.ZERO:
		if abs(velocity.x) > abs(velocity.y):
			if velocity.x > 0:
				$AnimationPlayer.play("running-right")
			else:
				$AnimationPlayer.play("running-left")
		else:
			if velocity.y > 0:
				$AnimationPlayer.play("running-down")
			else:
				$AnimationPlayer.play("running-up")
	else:
		$AnimationPlayer.stop()
	
	if Input.is_action_just_pressed("right_mouse") and selected:
		var ennemies = $Range.get_overlapping_bodies()
		print("Ennemies détectées : ", ennemies.size(), " (debug)")
		if ennemies.size() > 0:
			var valid_enemies = [] 
			for ennemy in ennemies:
				if ennemy is Unit and ennemy.has_method("get_side") and ennemy.get_side() != self.get_side() and ennemy != self:
					valid_enemies.append(ennemy)
			if valid_enemies.size() > 0:
				if $Timer.is_stopped():
					valid_enemies.sort_custom(func(a, b): return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position))
					var closest = valid_enemies[0]
					var ennemy_pos = closest.global_position
					$Marker2D.look_at(ennemy_pos)
					var arrow_instance = arrow.instantiate()
					if self.get_side() == true:
						arrow_instance.change_sprite("res://Fire_0_Preview.png", 4, 7, 12)
						arrow_instance.set_target(false)
					else:
						arrow_instance.change_sprite("res://Pure.png", 5, 5, 16)
						arrow_instance.set_target(true)
					arrow_instance.rotation = $Marker2D.rotation
					arrow_instance.global_position = $Marker2D.global_position
					arrow_instance.source_unit = self  # Passer la référence pour multiplicateur de dégâts
					add_child(arrow_instance)
					# Appliquer le modificateur de cooldown
					var base_timer = attack_speed
					var modified_timer = base_timer + attack_cooldown_modifier
					$Timer.wait_time = max(0.1, modified_timer)  # Minimum 0.1 sec
					$Timer.start()
					print("Tir 1 projectile sur closest ennemy : ", closest.name)
			else:
				print("Pas d'ennemi valide dans range")

func set_speed(new_value):
	speed = new_value
	base_speed = new_value  # Sauvegarder la vitesse de base

func set_health(value):
	health = value
	
	if health == 0:
		queue_free()
		set_selected(false)

func set_attack_speed(value):
	attack_speed = value

func get_side():
	return enfer

func get_health():
	return health
