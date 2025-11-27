class_name UnitCombatComponent
extends Node

## Component gérant le combat et les attaques d'une unité.
##
## Responsabilités :
## - Gestion du cooldown d'attaque
## - Spawning de projectiles
## - Application des multiplicateurs de dégâts
## - Gestion des charges spéciales (Michaël, Cupidon)

# ========================================
# SIGNAUX
# ========================================

## Émis quand des dégâts sont infligés.
signal damage_dealt(amount: int)

## Émis quand une attaque est lancée.
signal attack_performed()

# ========================================
# PROPRIÉTÉS EXPORTÉES
# ========================================

## Dégâts de base de l'unité.
@export var base_damage: int = 10

## Portée d'attaque en pixels.
@export var attack_range: float = 150.0

## Cooldown entre deux attaques (secondes).
@export var attack_cooldown: float = 1.0

## Scene du projectile à spawner.
@export var projectile_scene: PackedScene

# ========================================
# VARIABLES D'ÉTAT
# ========================================

## Dégâts actuels (modifiés par buffs).
var current_damage: int = 10

## Multiplicateur de dégâts (items, buffs).
var damage_multiplier: float = 1.0

## Modification du cooldown (buffs/debuffs).
var cooldown_modifier: float = 0.0

## Charges de Glaive de Michaël.
var michael_charges: int = 0

## Charges de Flèche de Cupidon.
var cupidon_arrows: int = 0

## Si l'unité peut attaquer actuellement.
var can_attack: bool = true

## Si l'unité est en train d'attaquer.
var is_attacking: bool = false

## Cible actuelle.
var current_target: Node2D = null

## Nodes requis du parent.
var _timer: Timer = null
var _projectile_spawn: Marker2D = null
var _parent_unit: Node2D = null

## Si le component est actif (peut attaquer)
var is_enabled: bool = true

# ========================================
# INITIALISATION
# ========================================

func _ready() -> void:
	current_damage = base_damage
	_parent_unit = get_parent()
	
	_timer = _parent_unit.get_node_or_null("Timer")
	_projectile_spawn = _parent_unit.get_node_or_null("Marker2D")
	
	if _timer:
		_timer.one_shot = true
		_timer.timeout.connect(_on_cooldown_finished)
	
	if not projectile_scene:
		projectile_scene = preload("res://scenes/entities/projectiles/projectile.tscn")

# ========================================
# SYSTÈME D'ATTAQUE
# ========================================

func try_attack() -> bool:
	## Tente d'attaquer la cible actuelle.
	##
	## @return: true si attaque lancée, false sinon
	if not is_enabled:
		return false
	
	if not can_attack or not current_target or not is_instance_valid(current_target):
		return false
	
	_perform_attack()
	return true


func _perform_attack() -> void:
	## Effectue une attaque.
	is_attacking = true
	can_attack = false
	
	_spawn_projectile()

	var final_cooldown: float = max(0.1, attack_cooldown + cooldown_modifier)
	if _timer:
		_timer.start(final_cooldown)

	attack_performed.emit()

	if is_inside_tree():
		await get_tree().create_timer(0.2).timeout
	is_attacking = false


func _spawn_projectile() -> void:
	## Spawne un projectile vers la cible.
	if not projectile_scene or not _projectile_spawn:
		return
	
	var projectile: Projectile = projectile_scene.instantiate() as Projectile
	if not projectile:
		return
	
	projectile.add_to_group("projectiles")
	projectile.global_position = _projectile_spawn.global_position
	projectile.rotation = _projectile_spawn.rotation
	
	if _parent_unit is Unit:
		projectile.targets_enfer = not _parent_unit.is_hell_faction
	
	projectile.source_unit = _parent_unit
	projectile.source_unit = _parent_unit
	if current_target is Base:
		# a revoir la valeur, si on en met une pour chaque unite, ou une globale (200px)
		projectile.max_distance = attack_range + 200.0
	else:
		projectile.max_distance = attack_range + 50.0
	
	var final_damage := int(current_damage * damage_multiplier)
	projectile.damage = final_damage
	
	if michael_charges > 0:
		projectile.is_michael_glaive = true
		michael_charges -= 1
	elif cupidon_arrows > 0:
		projectile.is_cupidon_arrow = true
		cupidon_arrows -= 1
	
	_apply_projectile_sprite(projectile)
	
	_parent_unit.get_parent().add_child(projectile)
	damage_dealt.emit(final_damage)


func _apply_projectile_sprite(projectile: Projectile) -> void:
	## Applique le sprite du projectile selon le camp.
	##
	## @param projectile: Projectile à configurer
	if not (_parent_unit is Unit):
		return
	
	if _parent_unit.is_hell_faction:
		projectile.change_sprite("res://assets/sprites/projectiles/feu.png")
	else:
		projectile.change_sprite("res://assets/sprites/projectiles/vent.png")

# ========================================
# CALLBACKS
# ========================================

func _on_cooldown_finished() -> void:
	## Callback du timer de cooldown.
	can_attack = true

# ========================================
# UTILITAIRES
# ========================================

func set_target(target: Node2D) -> void:
	## Définit la cible actuelle.
	##
	## @param target: Node2D à cibler
	current_target = target
	
	if _projectile_spawn and target and is_instance_valid(target):
		_projectile_spawn.look_at(target.global_position)


func is_target_in_range() -> bool:
	## Vérifie si la cible est à portée.
	##
	## @return: true si à portée
	if not _parent_unit or not (_parent_unit is Unit):
		return false
	
	if not _parent_unit.targeting_component:
		return false
	
	var enemy: Node2D = _parent_unit.targeting_component.current_enemy
	
	if not enemy or not is_instance_valid(enemy):
		return false
	
	var distance := _parent_unit.global_position.distance_to(enemy.global_position)
	return distance <= attack_range


func reset_modifiers() -> void:
	## Réinitialise les modificateurs de combat.
	damage_multiplier = 1.0
	cooldown_modifier = 0.0
