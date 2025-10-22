class_name UnitCombatComponent
extends Node

## Component gérant le combat et les attaques d'une unité.
##
## Responsabilités :
## - Gestion du cooldown d'attaque
## - Spawning de projectiles
## - Application des multiplicateurs de dégâts
## - Gestion des charges spéciales (Michaël, Cupidon)
##
## @tutorial: Utilisé par Unit pour handle_combat()

## Émis quand des dégâts sont infligés.
## @param amount: Montant des dégâts
signal damage_dealt(amount: int)

## Émis quand une attaque est lancée.
signal attack_performed()

## Dégâts de base de l'unité.
@export var base_damage: int = 10

## Portée d'attaque en pixels.
@export var attack_range: float = 150.0

## Cooldown entre deux attaques (secondes).
@export var attack_cooldown: float = 1.0

## Scene du projectile à spawner.
@export var projectile_scene: PackedScene

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


func _ready() -> void:
	current_damage = base_damage
	_parent_unit = get_parent()
	
	# Récupère les nodes nécessaires
	_timer = _parent_unit.get_node_or_null("Timer")
	_projectile_spawn = _parent_unit.get_node_or_null("Marker2D")
	
	if _timer:
		_timer.one_shot = true
		_timer.timeout.connect(_on_cooldown_finished)
	
	if not projectile_scene:
		projectile_scene = preload("res://scenes/entities/projectiles/projectile.tscn")


## Tente d'attaquer la cible actuelle.
##
## @return: true si attaque lancée, false sinon
func try_attack() -> bool:
	if not can_attack or not current_target or not is_instance_valid(current_target):
		return false
	
	_perform_attack()
	return true


## Effectue une attaque.
func _perform_attack() -> void:
	is_attacking = true
	can_attack = false
	
	_spawn_projectile()
	
	var final_cooldown: float = max(0.1, attack_cooldown + cooldown_modifier)
	if _timer:
		_timer.start(final_cooldown)
	
	attack_performed.emit()
	
	# Petit délai pour l'animation
	await get_tree().create_timer(0.2).timeout
	is_attacking = false


## Spawne un projectile vers la cible.
func _spawn_projectile() -> void:
	if not projectile_scene or not _projectile_spawn:
		return
	
	var projectile: Projectile = projectile_scene.instantiate() as Projectile
	if not projectile:
		return
	
	projectile.add_to_group("projectiles")
	projectile.global_position = _projectile_spawn.global_position
	projectile.rotation = _projectile_spawn.rotation
	
	# Configuration camp
	if _parent_unit.has("is_hell_faction"):
		projectile.targets_enfer = not _parent_unit.is_hell_faction
	
	projectile.source_unit = _parent_unit
	projectile.max_distance = attack_range
	
	# Dégâts finaux
	var final_damage := int(current_damage * damage_multiplier)
	projectile.damage = final_damage
	
	# Effets spéciaux
	if michael_charges > 0:
		projectile.is_michael_glaive = true
		michael_charges -= 1
	elif cupidon_arrows > 0:
		projectile.is_cupidon_arrow = true
		cupidon_arrows -= 1
	
	# Sprite selon le camp
	_apply_projectile_sprite(projectile)
	
	_parent_unit.get_parent().add_child(projectile)
	damage_dealt.emit(final_damage)


## Applique le sprite du projectile selon le camp.
##
## @param projectile: Projectile à configurer
func _apply_projectile_sprite(projectile: Projectile) -> void:
	if not _parent_unit.has("is_hell_faction"):
		return
	
	if _parent_unit.is_hell_faction:
		projectile.change_sprite("res://assets/sprites/projectiles/feu.png")
	else:
		projectile.change_sprite("res://assets/sprites/projectiles/vent.png")


## Callback du timer de cooldown.
func _on_cooldown_finished() -> void:
	can_attack = true


## Définit la cible actuelle.
##
## @param target: Node2D à cibler
func set_target(target: Node2D) -> void:
	current_target = target
	
	# Oriente le spawn vers la cible
	if _projectile_spawn and target and is_instance_valid(target):
		_projectile_spawn.look_at(target.global_position)


## Vérifie si la cible est à portée.
##
## @return: true si à portée
func is_target_in_range() -> bool:
	if not current_target or not is_instance_valid(current_target):
		return false
	
	var distance := _parent_unit.global_position.distance_to(current_target.global_position)
	return distance <= attack_range


## Réinitialise les modificateurs de combat.
func reset_modifiers() -> void:
	damage_multiplier = 1.0
	cooldown_modifier = 0.0
