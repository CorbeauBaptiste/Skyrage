extends CharacterBody2D
class_name Unit

@export var speed = 100: set = set_speed
@export var enfer = false: set = set_side
@export var health = 20: set = set_health
@export var max_health = 20  # PV maximum pour soin
@export var attack_speed = 1: set = set_attack_speed
@export var unit_size: String = "S"  # Taille: S (Small), M (Medium), L (Large)

# Modificateurs d'effets d'items
var base_speed: float = 100.0  # Vitesse de base pour restauration
var speed_multiplier: float = 1.0  # Multiplicateur de vitesse
var damage_multiplier: float = 1.0  # Multiplicateur de dégâts
var attack_cooldown_modifier: float = 0.0  # Modificateur de cooldown en secondes

# Flèches de Cupidon (item spécial)
var cupidon_arrows: int = 0  # Nombre de flèches spéciales restantes
var cupidon_arrow_damage: int = 35  # Dégâts par flèche de Cupidon
var cupidon_area_radius: float = 80.0  # Rayon de la zone d'explosion

# Glaive de Michaël (item légendaire)
var michael_charges: int = 0  # Nombre d'utilisations du glaive
var michael_area_radius: float = 120.0  # Rayon plus grand que Cupidon

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
					
					# Vérifier si on a le Glaive de Michaël (priorité sur Cupidon)
					if michael_charges > 0:
						# Utiliser le Glaive de Michaël (dégâts massifs adaptatifs)
						arrow_instance.is_michael_glaive = true
						arrow_instance.area_radius = michael_area_radius
						michael_charges -= 1
						print("⚔️ Tir Glaive de Michaël ! (", michael_charges, " restantes)")
						
						# Sprite légendaire (or/divin)
						if self.get_side() == true:
							arrow_instance.change_sprite("res://Fire_0_Preview.png", 4, 7, 12)
							arrow_instance.set_target(false)
						else:
							arrow_instance.change_sprite("res://Pure.png", 5, 5, 16)
							arrow_instance.set_target(true)
						# Teinte or divin
						arrow_instance.modulate = Color(1.8, 1.5, 0.3)  # Or brillant
					
					# Vérifier si on a des flèches de Cupidon
					elif cupidon_arrows > 0:
						# Utiliser une flèche de Cupidon (avec explosion de zone)
						arrow_instance.is_cupidon_arrow = true
						arrow_instance.area_damage = cupidon_arrow_damage
						arrow_instance.area_radius = cupidon_area_radius
						cupidon_arrows -= 1
						print("💘 Tir flèche de Cupidon ! (", cupidon_arrows, " restantes)")
						
						# Sprite spécial pour flèche de Cupidon (rose/coeur)
						if self.get_side() == true:
							arrow_instance.change_sprite("res://Fire_0_Preview.png", 4, 7, 12)
							arrow_instance.set_target(false)
						else:
							arrow_instance.change_sprite("res://Pure.png", 5, 5, 16)
							arrow_instance.set_target(true)
						# Teinte rose pour distinguer
						arrow_instance.modulate = Color(1.5, 0.5, 1.0)  # Rose vif
					else:
						# Flèche normale
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

func heal(amount: int) -> int:
	"""
	Soigne l'unité d'un certain montant
	Args:
		amount: Montant de PV à restaurer
	Returns: Montant réellement soigné (en cas de cap)
	"""
	var old_health = health
	health = min(health + amount, max_health)
	var actual_heal = health - old_health
	
	if actual_heal > 0:
		print("💚 Unité ", name, " soignée: +", actual_heal, " PV (", old_health, " → ", health, ")")
		_show_heal_feedback(actual_heal)
	
	return actual_heal

func _show_heal_feedback(amount: int) -> void:
	"""Affiche un label de feedback visuel pour le soin"""
	var label = Label.new()
	label.text = "+%d PV" % amount
	label.modulate = Color.GREEN
	label.position = Vector2(-20, -40)
	label.z_index = 100
	
	# Style
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_font_size_override("font_size", 16)
	
	add_child(label)
	
	# Animation
	var tween = create_tween()
	tween.parallel().tween_property(label, "position:y", -60, 1.0)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(label.queue_free)

func get_missing_health() -> int:
	"""Retourne le nombre de PV manquants"""
	return max_health - health

func is_wounded() -> bool:
	"""Retourne true si l'unité n'est pas à pleine santé"""
	return health < max_health
