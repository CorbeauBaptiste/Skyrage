extends Node
class_name AIStateEvaluator

## Évalue l'état tactique d'une unité.
##
## Analyse la situation actuelle (santé, ennemis) et détermine
## l'état tactique approprié.
##
## @tutorial: Utilisé par AIController
## @see: AIController

# ========================================
# CONSTANTES
# ========================================

## Seuil de PV pour repli (30%).
const LOW_HEALTH_THRESHOLD: float = 0.3

## Seuil de PV pour fuite (15%).
const CRITICAL_HEALTH_THRESHOLD: float = 0.15

# ========================================
# ÉVALUATION
# ========================================

## Évalue l'état tactique d'une unité.
##
## États possibles :
## - "FLEE" : Fuite (PV < 15%)
## - "RETREAT" : Repli (PV < 30%)
## - "ATTACK" : Combat (ennemi détecté)
## - "MOVE_TO_BASE" : Progression vers objectif
## - "IDLE" : Aucune action
##
## @param unit: Unité à évaluer
## @return: État tactique
func evaluate_state(unit: Unit) -> String:
	if not unit or not is_instance_valid(unit):
		return "IDLE"
	
	var health_percent := _get_health_percent(unit)
	var has_enemy := _has_enemy(unit)
	
	# Priorité 1 : Survie
	if health_percent < CRITICAL_HEALTH_THRESHOLD:
		return "FLEE"
	
	if health_percent < LOW_HEALTH_THRESHOLD:
		return "RETREAT"
	
	# Priorité 2 : Combat
	if has_enemy and unit.can_attack:
		return "ATTACK"
	
	# Priorité 3 : Objectif
	return "MOVE_TO_BASE"

# ========================================
# HELPERS
# ========================================

## Retourne le pourcentage de santé.
##
## @param unit: Unité à évaluer
## @return: Pourcentage entre 0.0 et 1.0
func _get_health_percent(unit: Unit) -> float:
	if unit.health_component:
		return unit.health_component.get_health_percent()
	return 0.0


## Vérifie si l'unité a un ennemi détecté.
##
## @param unit: Unité à évaluer
## @return: true si ennemi présent
func _has_enemy(unit: Unit) -> bool:
	if unit.targeting_component:
		return unit.targeting_component.current_enemy != null
	return false


## Trouve l'unité ennemie de type L la plus proche.
##
## @return: Unité L ennemie ou null
func find_closest_L_enemy() -> Unit:
	var parent_unit := get_parent() as Unit
	if not parent_unit or not parent_unit.is_inside_tree():
		return null
	
	var closest_L: Unit = null
	var min_distance := INF
	var unit_side := parent_unit.get_side()
	
	for unit in parent_unit.get_tree().get_nodes_in_group("units"):
		if not is_instance_valid(unit) or not unit is Unit:
			continue
		
		# Doit être ennemi
		if unit.get_side() == unit_side:
			continue
		
		# Doit être de type L
		if unit.unit_size != "L":
			continue
		
		var distance := parent_unit.global_position.distance_to(unit.global_position)
		if distance < min_distance:
			min_distance = distance
			closest_L = unit
	
	return closest_L
