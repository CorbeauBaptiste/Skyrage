class_name UnitMovementComponent
extends Node

## Component fournissant des utilitaires de mouvement pour les unités.
##
## ⚠️ NE GÈRE PAS la logique de mouvement ! Chaque Unit doit override handle_movement().
##
## Responsabilités :
## - Fournir des helpers pour le calcul d'évitement
## - Stocker la vitesse et ses multiplicateurs
## - Appliquer la velocity au CharacterBody2D
##
## @tutorial: Utilisé par les Units dans leur handle_movement() custom

## Vitesse de base de l'unité (px/sec).
@export var base_speed: float = 50.0

## Rayon d'évitement des autres unités.
@export var avoidance_radius: float = 30.0

## Poids de l'évitement dans le calcul final.
@export_range(0.0, 1.0) var avoidance_weight: float = 0.3

## Vitesse actuelle (peut être modifiée par buffs/debuffs).
var current_speed: float = 50.0

## Multiplicateur de vitesse (items, buffs).
var speed_multiplier: float = 1.0

## Référence au CharacterBody2D parent.
var _body: CharacterBody2D = null


func _ready() -> void:
	current_speed = base_speed
	_body = get_parent() as CharacterBody2D
	
	if not _body:
		push_error("MovementComponent must be child of CharacterBody2D")


## HELPER: Calcule le vecteur d'évitement des unités proches.
##
## @return: Vecteur d'évitement normalisé (à combiner avec direction de mouvement)
func calculate_avoidance() -> Vector2:
	if not _body:
		return Vector2.ZERO
	
	var avoidance := Vector2.ZERO
	var nearby_count := 0
	
	for unit in _body.get_tree().get_nodes_in_group("units"):
		if unit == _body or not is_instance_valid(unit):
			continue
		
		var distance := _body.global_position.distance_to(unit.global_position)
		
		if distance < avoidance_radius and distance > 0:
			var push_direction := _body.global_position.direction_to(unit.global_position)
			var push_strength := 1.0 - (distance / avoidance_radius)
			avoidance -= push_direction * push_strength
			nearby_count += 1
	
	if nearby_count > 0:
		avoidance = avoidance.normalized()
	
	return avoidance


## HELPER: Applique une vélocité finale au CharacterBody2D.
##
## À appeler depuis handle_movement() après avoir calculé la direction.
##
## @param direction: Direction finale du mouvement (normalisée)
func apply_velocity(direction: Vector2) -> void:
	if not _body:
		return
	
	_body.velocity = direction.normalized() * current_speed * speed_multiplier


## HELPER: Arrête le mouvement (met velocity à zéro).
func stop() -> void:
	if _body:
		_body.velocity = Vector2.ZERO


## Met à jour la vitesse de base (pour buffs/debuffs).
##
## @param new_speed: Nouvelle vitesse de base
func set_base_speed(new_speed: float) -> void:
	current_speed = new_speed


## Réinitialise la vitesse à la valeur de base.
func reset_speed() -> void:
	current_speed = base_speed
	speed_multiplier = 1.0


## Retourne la vitesse effective actuelle.
##
## @return: Vitesse en px/sec
func get_effective_speed() -> float:
	return current_speed * speed_multiplier
