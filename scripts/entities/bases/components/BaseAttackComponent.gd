class_name BaseAttackComponent
extends Node

## Component gérant les attaquants d'une base.
##
## Responsabilités :
## - Suivre les unités attaquant la base
## - Limiter le nombre d'attaquants simultanés
## - Gérer la file d'attente
##
## @tutorial: Évite que trop d'unités attaquent en même temps

## Émis quand une unité commence à attaquer.
## @param attacker: Unité qui attaque
signal base_under_attack(attacker: Node2D)

## Émis quand une unité arrête d'attaquer.
## @param attacker: Unité qui arrête
signal attack_ended(attacker: Node2D)

## Nombre maximum d'attaquants simultanés.
@export var max_simultaneous_attackers: int = 3

## Liste des unités attaquant actuellement.
var attacking_units: Array[Node2D] = []


## Enregistre une unité comme attaquant.
##
## @param unit: Unité à enregistrer
## @return: true si enregistrée, false si limite atteinte
func register_attacker(unit: Node2D) -> bool:
	if not unit or not is_instance_valid(unit):
		return false
	
	if attacking_units.has(unit):
		return true
	
	if attacking_units.size() >= max_simultaneous_attackers:
		return false
	
	attacking_units.append(unit)
	base_under_attack.emit(unit)
	
	return true


## Retire une unité de la liste des attaquants.
##
## @param unit: Unité à retirer
func unregister_attacker(unit: Node2D) -> void:
	if attacking_units.has(unit):
		attacking_units.erase(unit)
		attack_ended.emit(unit)


## Vérifie si une unité peut attaquer la base.
##
## @param unit: Unité à vérifier
## @return: true si peut attaquer
func can_attack(unit: Node2D) -> bool:
	return has_room() or attacking_units.has(unit)


## Vérifie si la base peut accepter plus d'attaquants.
##
## @return: true si place disponible
func has_room() -> bool:
	return attacking_units.size() < max_simultaneous_attackers


## Nettoie les références invalides.
func cleanup_invalid_attackers() -> void:
	attacking_units = attacking_units.filter(func(unit): return is_instance_valid(unit))


## Retourne le nombre d'attaquants actuels.
##
## @return: Nombre d'unités attaquant
func get_attacker_count() -> int:
	cleanup_invalid_attackers()
	return attacking_units.size()


## Retourne si la base est sous attaque.
##
## @return: true si au moins un attaquant
func is_under_attack() -> bool:
	return get_attacker_count() > 0
