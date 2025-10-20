extends CharacterBody2D
class_name Unit

# ========================================
# PROPRIÉTÉS DE BASE (communes à tous)
# ========================================
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

# Stats actuelles
var current_health: int
var current_speed: float
var current_damage: int

# Multiplicateurs (items)
var damage_multiplier: float = 1.0
var speed_multiplier: float = 1.0
var attack_cooldown_modifier: float = 0.0
var michael_charges: int = 0
var cupidon_arrows: int = 0

# État
var target: Variant = null
var current_enemy: Node2D = null
var can_attack: bool = true
var is_attacking: bool = false
var is_attacking_base: bool = false
var base_attack_position: Vector2 = Vector2.ZERO

var selected: bool = false:
	set(value):
		selected = value
		_on_selection_changed()

# Nodes
var sprite: Sprite2D
var anim_player: AnimationPlayer
var detection_area: Area2D
var range_area: Area2D
var attack_timer: Timer
var projectile_spawn: Marker2D
var movement_collision: CollisionShape2D
var character_collision: CollisionShape2D

var arrow_scene = preload("res://scenes/entities/projectiles/projectile.tscn")

# Constantes d'évitement
const AVOIDANCE_WEIGHT: float = 0.3
const AVOIDANCE_RADIUS: float = 30.0

# Signaux
signal health_changed(current: int, max_hp: int)
signal unit_died()
signal damage_dealt(amount: int)

func _ready() -> void:
	current_health = max_health
	current_speed = base_speed
	current_damage = base_damage
	
	collision_layer = 2
	collision_mask = 1  # Collide UNIQUEMENT avec le terrain (layer 1)
	
	add_to_group("units")

func _setup_nodes() -> void:
	"""À appeler dans les enfants après _ready()"""
	sprite = get_node_or_null("Sprite2D")
	anim_player = get_node_or_null("AnimationPlayer")
	detection_area = get_node_or_null("Detect")
	range_area = get_node_or_null("Range")
	attack_timer = get_node_or_null("Timer")
	projectile_spawn = get_node_or_null("Marker2D")
	movement_collision = get_node_or_null("movement_collision")
	character_collision = get_node_or_null("character_collision")
	
	# Désactiver character_collision pour le movement (utilisé que pour les Area2D)
	if character_collision:
		character_collision.disabled = true
	
	if attack_timer:
		attack_timer.one_shot = true
		attack_timer.timeout.connect(_on_attack_cooldown_finished)
	
	if range_area:
		range_area.body_entered.connect(_on_enemy_in_range)
		range_area.body_exited.connect(_on_enemy_out_of_range)
	
	_apply_faction_color()
	_set_initial_target()

func _set_initial_target() -> void:
	"""Définit la base ennemie comme cible initiale"""
	var bases = get_tree().get_nodes_in_group("bases")
	for base in bases:
		if base.has_method("get_side") and base.get_side() != is_hell_faction:
			target = base
			break

# ========================================
# à override dans les enfants
# ========================================
func _physics_process(_delta: float) -> void:
	# Handle movement and combat
	if not is_attacking_base and current_enemy is Base:
		# If we were attacking a base but now can't, find another target
		_find_alternative_target()
	
	# If we're too far from our base attack position, return to it
	if is_attacking_base and base_attack_position.distance_to(global_position) > 50:
		_move_to_position(base_attack_position)
		return

# ========================================
# SYSTÈME D'ÉVITEMENT (helper pour les enfants)
# ========================================
func _calculate_avoidance() -> Vector2:
	"""Calcule un vecteur d'évitement des unités proches"""
	var avoidance = Vector2.ZERO
	var nearby_count = 0
	
	# Cherche les unités proches dans le groupe
	for unit in get_tree().get_nodes_in_group("units"):
		if unit == self or not is_instance_valid(unit):
			continue
		
		var distance = global_position.distance_to(unit.global_position)
		
		# Si trop proche, on s'écarte
		if distance < AVOIDANCE_RADIUS and distance > 0:
			var push_direction = global_position.direction_to(unit.global_position)
			# Plus on est proche, plus on pousse fort
			var push_strength = 1.0 - (distance / AVOIDANCE_RADIUS)
			avoidance -= push_direction * push_strength
			nearby_count += 1
	
	# Normaliser si on évite plusieurs unités
	if nearby_count > 0:
		avoidance = avoidance.normalized()
	
	return avoidance

func _apply_movement_with_avoidance(direction: Vector2) -> void:
	"""Applique le mouvement avec évitement automatique"""
	# Calcule l'évitement
	var avoidance = _calculate_avoidance()
	
	# Combine direction + évitement
	var final_direction = (direction + avoidance * AVOIDANCE_WEIGHT).normalized()
	
	# Applique la vitesse
	velocity = final_direction * current_speed * speed_multiplier

# ========================================
# SYSTÈME DE COMBAT
# ========================================
func _handle_combat() -> void:
	"""Gère le combat avec l'ennemi actuel (appeler dans _physics_process des enfants)"""
	if not is_instance_valid(current_enemy):
		current_enemy = null
		return
	
	# Se tourner vers l'ennemi
	if projectile_spawn:
		projectile_spawn.look_at(current_enemy.global_position)
	
	# Attaquer si cooldown terminé
	if can_attack:
		_perform_attack()

func _perform_attack() -> void:
	"""Effectue une attaque"""
	# Double check : ennemi toujours valide ?
	if not current_enemy or not is_instance_valid(current_enemy):
		current_enemy = null
		return
	
	is_attacking = true
	can_attack = false
	
	_spawn_projectile()
	
	# Cooldown
	var final_cooldown = max(0.1, attack_cooldown + attack_cooldown_modifier)
	if attack_timer:
		attack_timer.start(final_cooldown)
	
	await get_tree().create_timer(0.2).timeout
	is_attacking = false

func _find_alternative_target() -> void:
	"""Trouve une autre cible ou continue vers la base"""
	# Si la cible actuelle est une base, on continue vers elle
	if current_enemy is Base:
		is_attacking_base = true
		return
		
	# Sinon, on cherche d'autres cibles
	var potential_targets = get_tree().get_nodes_in_group("units")
	for target in potential_targets:
		if _is_valid_enemy(target):
			current_enemy = target
			is_attacking_base = false
			return

func _move_to_position(position: Vector2) -> void:
	"""Move to a specific position"""
	var direction = global_position.direction_to(position)
	_apply_movement_with_avoidance(direction)
	_update_animation()

func _spawn_projectile() -> void:
	"""Crée un projectile (peut être override pour AoE)"""
	var projectile = arrow_scene.instantiate() as Projectile
	projectile.add_to_group("projectiles")
	
	projectile.global_position = projectile_spawn.global_position
	projectile.rotation = projectile_spawn.rotation
	projectile.targets_enfer = not is_hell_faction
	projectile.source_unit = self
	projectile.max_distance = attack_range  # Set the maximum travel distance
	
	var final_damage = int(current_damage * damage_multiplier)
	projectile.damage = final_damage
	
	# Glaive de Michaël
	if michael_charges > 0:
		projectile.is_michael_glaive = true
		michael_charges -= 1
	# Flèche de Cupidon
	elif cupidon_arrows > 0:
		projectile.is_cupidon_arrow = true
		cupidon_arrows -= 1
	
	# Sprite du projectile
	if is_hell_faction:
		projectile.change_sprite("res://assets/sprites/projectiles/feu.png")
	else:
		projectile.change_sprite("res://assets/sprites/projectiles/vent.png")
	
	get_parent().add_child(projectile)
	emit_signal("damage_dealt", final_damage)

# ========================================
# DÉTECTION D'ENNEMIS
# ========================================
func _on_enemy_in_range(body: Node2D) -> void:
	"""Callback quand un ennemi entre dans la portée"""
	if _is_valid_enemy(body):
		if body is Base:
			# Toujours permettre d'attaquer la base ennemie
			if current_enemy != body:
				current_enemy = body
				is_attacking_base = true
				# Store the attack position to maintain formation
				base_attack_position = global_position
				# Notifier la base qu'on l'attaque
				if body.has_method("take_damage"):
					body.take_damage(0, self)  # 0 dégâts, juste pour l'enregistrer comme attaquant
		elif not current_enemy:  # Only switch to a new target if we don't have one
			current_enemy = body
			is_attacking_base = false

func _on_enemy_out_of_range(body: Node2D) -> void:
	"""Callback quand un ennemi sort de la portée"""
	if body == current_enemy:
		if body is Base:
			# Notify the base we're no longer attacking
			body.stop_attacking(self)
			is_attacking_base = false
		current_enemy = null

func _on_base_attacked(base: Base) -> void:
	"""Called when this unit successfully attacks a base"""
	if base == current_enemy and not is_attacking_base:
		is_attacking_base = true
		base_attack_position = global_position

func _is_valid_enemy(body: Node2D) -> bool:
	"""Vérifie si c'est un ennemi valide"""
	if not is_instance_valid(body) or body == self:
		return false
	
	if body is Unit:
		return body.is_hell_faction != self.is_hell_faction
	
	if body is Base:
		return body.get_side() != self.is_hell_faction
	
	return false

func _on_attack_cooldown_finished() -> void:
	"""Callback du timer d'attaque"""
	can_attack = true

# ========================================
# HEALTH
# ========================================
func take_damage(amount: int) -> void:
	set_health(current_health - amount)

func heal(amount: int) -> int:
	var old_health = current_health
	set_health(current_health + amount)
	return current_health - old_health

func set_health(value: int) -> void:
	current_health = clamp(value, 0, max_health)
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		_die()

func get_health() -> int:
	return current_health

func get_missing_health() -> int:
	return max_health - current_health

# ========================================
# UTILITAIRES
# ========================================
func get_side() -> bool:
	return is_hell_faction

func set_side(value: bool) -> void:
	is_hell_faction = value
	_apply_faction_color()

func _apply_faction_color() -> void:
	if sprite:
		sprite.modulate = Color.RED if is_hell_faction else Color.WHITE

func _on_selection_changed() -> void:
	if sprite:
		sprite.self_modulate = Color.AQUA if selected else Color.WHITE

func _die() -> void:
	if current_enemy is Base:
		current_enemy.stop_attacking(self)
	emit_signal("unit_died")
	queue_free()

func _update_animation() -> void:
	"""Helper pour animer selon velocity (appeler dans _physics_process des enfants)"""
	if not anim_player:
		return
	
	if velocity.length() < 1.0:
		anim_player.stop()
		return
	
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
