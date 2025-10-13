extends CharacterBody2D
class_name Unit

@export_group("Stats de base")
@export var unit_name: String = "Unit"
@export var unit_size: String = "M" 
@export var max_health: int = 100
@export var base_damage: int = 10
@export var base_speed: float = 50.0
@export var attack_range: float = 150.0
@export var attack_cooldown: float = 1.0
@export var detection_radius: float = 200.0

@export_group("Faction")
@export var is_hell_faction: bool = false

var current_health: int
var current_speed: float
var current_damage: int

var damage_multiplier: float = 1.0
var speed_multiplier: float = 1.0
var attack_cooldown_modifier: float = 0.0

var michael_charges: int = 0
var cupidon_arrows: int = 0

var target: Variant = null
var current_enemy: Node2D = null
var can_attack: bool = true
var is_attacking: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var detection_area: Area2D = $Detect
@onready var range_area: Area2D = $Range
@onready var attack_timer: Timer = $Timer
@onready var projectile_spawn: Marker2D = $Marker2D

var arrow_scene = preload("res://scenes/entities/projectiles/projectile.tscn")

const AVOIDANCE_WEIGHT: float = 0.3
const TARGET_RADIUS: float = 20.0

signal health_changed(current: int, max_hp: int)
signal unit_died()
signal damage_dealt(amount: int)

func _ready() -> void:
	current_health = max_health
	current_speed = base_speed
	current_damage = base_damage
	
	collision_layer = 2
	collision_mask = 3
	
	_setup_detection_area()
	_setup_range_area()
	
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	
	_apply_faction_color()
	
	add_to_group("units")

func _setup_detection_area() -> void:
	"""Configure la zone de détection des ennemis"""
	if not detection_area:
		return
	
	detection_area.collision_layer = 2
	detection_area.collision_mask = 3
	
	var shape = CircleShape2D.new()
	shape.radius = detection_radius
	
	var collision = detection_area.get_node("CollisionShape2D")
	if collision:
		collision.shape = shape

func _setup_range_area() -> void:
	"""Configure la zone d'attaque"""
	if not range_area:
		return
	
	range_area.collision_layer = 2
	range_area.collision_mask = 3
	range_area.body_entered.connect(_on_enemy_in_range)
	range_area.body_exited.connect(_on_enemy_out_of_range)
	
	var shape = CircleShape2D.new()
	shape.radius = attack_range
	
	var collision = range_area.get_node("CollisionShape2D")
	if collision:
		collision.shape = shape

func _apply_faction_color() -> void:
	"""Applique la couleur de faction au sprite"""
	if sprite:
		sprite.modulate = Color.RED if is_hell_faction else Color.WHITE

func _physics_process(delta: float) -> void:
	# stop l'unite si il attaque
	if is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	# enemy in range?
	if current_enemy and is_instance_valid(current_enemy):
		_handle_combat()
		return
	
	var enemy = _find_nearest_enemy()
	if enemy:
		target = enemy.global_position
	
	if target:
		_move_towards_target(delta)
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()
	
	_update_animation()

func _move_towards_target(delta: float) -> void:
	"""Déplace l'unité vers sa cible avec évitement"""
	var target_pos = target if target is Vector2 else target.global_position if target else Vector2.ZERO
	
	# direction vers la cible
	var direction = global_position.direction_to(target_pos)
	
	# évite les alliés
	var avoidance = _calculate_avoidance()
	direction = (direction + avoidance * AVOIDANCE_WEIGHT).normalized()
	
	var final_speed = current_speed * speed_multiplier
	velocity = direction * final_speed
	
	# s'arrêter si on est assez proche
	if global_position.distance_to(target_pos) < TARGET_RADIUS:
		target = null
		velocity = Vector2.ZERO

func _calculate_avoidance() -> Vector2:
	"""Calcule le vecteur d'évitement des alliés"""
	var result = Vector2.ZERO
	var neighbors = detection_area.get_overlapping_bodies()
	
	if neighbors.is_empty():
		return result
	
	for neighbor in neighbors:
		if not is_instance_valid(neighbor) or neighbor == self:
			continue
		
		if neighbor is Unit and neighbor.is_hell_faction == self.is_hell_faction:
			result += neighbor.global_position.direction_to(global_position)
	
	if neighbors.size() > 0:
		result /= neighbors.size()
	
	return result.normalized()

func _find_nearest_enemy() -> Node2D:
	"""Trouve l'ennemi le plus proche dans la zone de détection"""
	var enemies = range_area.get_overlapping_bodies()
	var nearest: Node2D = null
	var min_dist = INF
	
	for body in enemies:
		if not _is_valid_enemy(body):
			continue
		
		var dist = global_position.distance_to(body.global_position)
		if dist < min_dist:
			min_dist = dist
			nearest = body
	
	return nearest

func _handle_combat() -> void:
	"""Gère le combat avec l'ennemi actuel"""
	if not is_instance_valid(current_enemy):
		current_enemy = null
		return
	
	# se trourner vers l'ennemie
	projectile_spawn.look_at(current_enemy.global_position)
	
	# cooldown finis ? alors on attaque
	if can_attack:
		_perform_attack()

func _perform_attack() -> void:
	"""Effectue une attaque"""
	if not current_enemy or not is_instance_valid(current_enemy):
		return
	
	is_attacking = true
	can_attack = false
	
	_spawn_projectile()
	
	# active le cooldown de l'attaque
	var final_cooldown = max(0.1, attack_cooldown + attack_cooldown_modifier)
	attack_timer.start(final_cooldown)
	
	await get_tree().create_timer(0.2).timeout
	is_attacking = false

func _spawn_projectile() -> void:
	"""Crée un projectile selon le type d'item équipé"""
	var projectile = arrow_scene.instantiate() as Projectile
	
	projectile.global_position = projectile_spawn.global_position
	projectile.rotation = projectile_spawn.rotation
	projectile.targets_enfer = not is_hell_faction
	projectile.source_unit = self
	
	var final_damage = int(current_damage * damage_multiplier)
	projectile.damage = final_damage
	
	# Glaive de Michaël
	if michael_charges > 0:
		projectile.is_michael_glaive = true
		michael_charges -= 1
		print("⚔️ Tir Glaive de Michaël (charges restantes: %d)" % michael_charges)
	
	# Flèche de Cupidon
	elif cupidon_arrows > 0:
		projectile.is_cupidon_arrow = true
		cupidon_arrows -= 1
		print("💘 Tir Flèche de Cupidon (flèches restantes: %d)" % cupidon_arrows)
	
	# Apparence du projectile
	if is_hell_faction:
		projectile.change_sprite("res://assets/sprites/projectiles/feu.png")
	else:
		projectile.change_sprite("res://assets/sprites/projectiles/vent.png")
	
	get_parent().add_child(projectile)
	
	emit_signal("damage_dealt", final_damage)

func _on_enemy_in_range(body: Node2D) -> void:
	"""Callback quand un ennemi entre dans la portée d'attaque"""
	if _is_valid_enemy(body) and not current_enemy:
		current_enemy = body
		print("🎯 %s a détecté %s" % [unit_name, body.name])

func _on_enemy_out_of_range(body: Node2D) -> void:
	"""Callback quand un ennemi sort de la portée d'attaque"""
	if body == current_enemy:
		current_enemy = null
		target = null

func _is_valid_enemy(body: Node2D) -> bool:
	"""Vérifie si un body est un ennemi valide"""
	if not is_instance_valid(body) or body == self:
		return false
	
	if body is Unit:
		return body.is_hell_faction != self.is_hell_faction
	
	if body is Base:
		return (body.team == "enfer") != self.is_hell_faction
	
	return false

func _on_attack_timer_timeout() -> void:
	"""Callback quand le cooldown d'attaque est terminé"""
	can_attack = true

func take_damage(amount: int) -> void:
	"""Inflige des dégâts à l'unité"""
	set_health(current_health - amount)

func heal(amount: int) -> int:
	"""Soigne l'unité et retourne la quantité réellement soignée"""
	var old_health = current_health
	set_health(current_health + amount)
	return current_health - old_health

func set_health(value: int) -> void:
	"""Définit la santé actuelle"""
	current_health = clamp(value, 0, max_health)
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		_die()

func get_health() -> int:
	return current_health

func get_missing_health() -> int:
	return max_health - current_health

func _die() -> void:
	"""Appelé quand l'unité meurt"""
	emit_signal("unit_died")
	queue_free()

func _update_animation() -> void:
	"""Met à jour l'animation en fonction du mouvement"""
	if not anim_player:
		return
	
	if velocity.length() < 1.0:
		anim_player.stop()
		return
	
	# détermimer la	direction
	if abs(velocity.x) > abs(velocity.y):
		if velocity.x > 0:
			anim_player.play("running-right")
		else:
			anim_player.play("running-left")
	else:
		if velocity.y > 0:
			anim_player.play("running-down")
		else:
			anim_player.play("running-up")

func get_side() -> bool:
	return is_hell_faction

func set_side(value: bool) -> void:
	is_hell_faction = value
	_apply_faction_color()

# Pour le système de sélection
var selected: bool = false:
	set(value):
		selected = value
		if sprite:
			sprite.self_modulate = Color.AQUA if selected else Color.WHITE
