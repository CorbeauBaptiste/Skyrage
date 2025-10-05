extends CharacterBody2D
class_name Unit

@export var speed = 100: set = set_speed
@export var enfer = false: set = set_side
@export var health = 20: set = set_health
@export var attack_speed = 1: set = set_attack_speed

# ============================================================================
# PROPRIÉTÉS POUR LES EFFETS D'ITEMS
# ============================================================================
var max_health: int = 20  # PV maximum
var michael_charges: int = 0  # Charges du Glaive de Michaël
var cupidon_arrows: int = 0  # Flèches de Cupidon
var attack_cooldown_modifier: float = 0.0  # Modificateur de cooldown (-0.5 = -50%)
var damage_multiplier: float = 1.0  # Multiplicateur de dégâts
var speed_multiplier: float = 1.0  # Multiplicateur de vitesse

# ============================================================================
# PROPRIÉTÉS EXISTANTES
# ============================================================================
var av = Vector2.ZERO
var avoid_weight = 0.1
var target_radius = 50
var selected = false: set = set_selected
var target = null: set = set_target

var arrow = preload("res://projectile.tscn"): set = set_arrow

# ============================================================================
# INITIALISATION
# ============================================================================
func _ready() -> void:
	max_health = health  # Initialise max_health avec la valeur de départ
	add_to_group("units")  # Important pour le système d'items

# ============================================================================
# SETTERS
# ============================================================================
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

func set_speed(new_value):
	speed = new_value

func set_health(value):
	health = value
	
	if health <= 0:
		queue_free()
		set_selected(false)

func set_attack_speed(value):
	attack_speed = value

# ============================================================================
# MÉTHODES DE SOINS (pour les effets d'items)
# ============================================================================
func get_missing_health() -> int:
	return max_health - health

func is_wounded() -> bool:
	return health < max_health

func heal(amount: int) -> int:
	var old_health = health
	health = min(max_health, health + amount)
	return health - old_health

# ============================================================================
# GETTERS
# ============================================================================
func get_side() -> bool:
	return enfer

func get_health() -> int:
	return health

# ============================================================================
# MOUVEMENT
# ============================================================================
func avoid() -> Vector2:
	var result = Vector2.ZERO
	var neighbors = $Detect.get_overlapping_bodies()
	if neighbors:
		for i in neighbors:
			result += i.position.direction_to(position)
		result /= neighbors.size()
	return result.normalized()

func _physics_process(delta: float) -> void:
	self.z_index = 900
	velocity = Vector2.ZERO
	if target:
		var target_pos = target if target is Vector2 else target.global_position if target else Vector2.ZERO
		velocity = position.direction_to(target_pos)
		if position.distance_to(target_pos) < target_radius:
			target = null
	av = avoid()
	
	# Applique le multiplicateur de vitesse (effets d'items)
	var effective_speed = speed * speed_multiplier
	velocity = (velocity + av * avoid_weight).normalized() * effective_speed
	
	move_and_collide(velocity * delta)
	
	# Animation
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
	
	# Attaque
	if Input.is_action_just_pressed("right_mouse") and selected:
		var ennemies = $Range.get_overlapping_bodies()
		print("Ennemies détectées : ", ennemies.size(), " (debug)")
		if ennemies.size() > 0:
			var valid_enemies = [] 
			for ennemy in ennemies:
				if ennemy.has_method("get_side") and ennemy.get_side() != self.get_side() and ennemy != self:
					valid_enemies.append(ennemy)
			if valid_enemies.size() > 0:
				if $Timer.is_stopped():
					valid_enemies.sort_custom(func(a, b): 
						return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position)
					)
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
					add_child(arrow_instance)
					
					# Applique le modificateur de cooldown (effets d'items)
					var effective_cooldown = attack_speed + attack_cooldown_modifier
					effective_cooldown = max(0.1, effective_cooldown)  # Minimum 0.1 sec
					$Timer.wait_time = effective_cooldown
					$Timer.start()
					
					print("Tir 1 projectile sur closest ennemy : ", closest.name)
			else:
				print("Pas d'ennemi valide dans range")
