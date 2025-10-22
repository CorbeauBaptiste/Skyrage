class_name BaseHealthComponent
extends Node

## Component gérant la santé d'une base.
##
## Responsabilités :
## - Gérer les PV de la base
## - Détecter la destruction
## - Émettre des signaux de changement
##
## @tutorial: Similaire à HealthComponent mais pour bases

## Émis quand la santé change.
## @param current: PV actuels
## @param max_health: PV maximum
signal health_changed(current: int, max_health: int)

## Émis quand la base est détruite.
## @param winning_team: Camp victorieux ("enfer" ou "paradis")
signal base_destroyed(winning_team: String)

## Points de vie maximum de la base.
@export var max_health: int = 2500

## Points de vie actuels.
var current_health: int = 2500

## Référence à la base parente.
var _parent_base: Node2D = null


func _ready() -> void:
	_parent_base = get_parent()
	current_health = max_health
	health_changed.emit(current_health, max_health)


## Inflige des dégâts à la base.
##
## @param amount: Montant des dégâts
## @param attacker: Source des dégâts (pour tracking)
## @return: true si base détruite, false sinon
func take_damage(amount: int, _attacker: Node2D = null) -> bool:
	if amount <= 0:
		return false
	
	var old_health := current_health
	current_health = max(0, current_health - amount)
	
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0 and old_health > 0:
		_on_destroyed()
		return true
	
	return false


## Callback quand la base est détruite.
func _on_destroyed() -> void:
	if not _parent_base:
		return
	
	var parent_team = _parent_base.get("team")
	if parent_team == null:
		push_warning("BaseHealthComponent: Parent base missing 'team' property")
		return
	
	var winner := "paradis" if parent_team == "enfer" else "enfer"
	
	base_destroyed.emit(winner)


## Définit directement la santé.
##
## @param value: Nouvelle valeur de santé
func set_health(value: int) -> void:
	var old_health := current_health
	current_health = clamp(value, 0, max_health)
	
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0 and old_health > 0:
		_on_destroyed()


## Retourne la santé actuelle.
##
## @return: PV actuels
func get_health() -> int:
	return current_health


## Retourne la santé maximum.
##
## @return: PV maximum
func get_max_health() -> int:
	return max_health


## Retourne le pourcentage de santé.
##
## @return: Valeur entre 0.0 et 1.0
func get_health_percent() -> float:
	if max_health <= 0:
		return 0.0
	return float(current_health) / float(max_health)
