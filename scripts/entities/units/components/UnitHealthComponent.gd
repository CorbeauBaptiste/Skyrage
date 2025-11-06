class_name UnitHealthComponent
extends Node

## Component gérant la santé d'une unité.
##
## Responsabilités :
## - Gérer les PV actuels/max
## - Appliquer dégâts et soins
## - Émettre des signaux de changement
##
## @tutorial: Attaché à Unit, implémente IDamageable

## Émis quand la santé change.
## @param current: PV actuels
## @param max_health: PV maximum
signal health_changed(current: int, max_health: int)

## Émis quand l'entité meurt.
signal died()

## Points de vie maximum.
@export var max_health: int = 100

## Points de vie actuels (initialisés à max_health dans _ready).
var current_health: int = 0


func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)


## Inflige des dégâts à l'entité.
##
## @param amount: Montant des dégâts (positif)
## @param attacker: Source des dégâts (optionnel, pour logging)
func take_damage(amount: int, attacker: Node2D = null) -> void:
	if amount <= 0:
		return
	
	var old_health := current_health
	current_health = max(0, current_health - amount)
	
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0 and old_health > 0:
		died.emit()


## Soigne l'entité.
##
## @param amount: Montant de soin (positif)
## @return: Montant réellement soigné
func heal(amount: int) -> int:
	if amount <= 0:
		return 0
	
	var old_health := current_health
	current_health = min(max_health, current_health + amount)
	
	var healed := current_health - old_health
	
	if healed > 0:
		health_changed.emit(current_health, max_health)
	
	return healed


## Définit directement la santé (pour initialisation ou effets spéciaux).
##
## @param value: Nouvelle valeur de santé
func set_health(value: int) -> void:
	var old_health := current_health
	current_health = clamp(value, 0, max_health)
	
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0 and old_health > 0:
		died.emit()


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


## Retourne les PV manquants.
##
## @return: Différence entre max et actuel
func get_missing_health() -> int:
	return max_health - current_health


## Retourne si l'entité est vivante.
##
## @return: true si PV > 0
func is_alive() -> bool:
	return current_health > 0


## Retourne le pourcentage de santé.
##
## @return: Valeur entre 0.0 et 1.0
func get_health_percent() -> float:
	if max_health <= 0:
		return 0.0
	return float(current_health) / float(max_health)
