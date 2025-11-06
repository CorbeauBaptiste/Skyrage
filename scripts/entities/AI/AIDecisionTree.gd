extends Node
class_name AIDecisionTree

## Arbre de décision tactique pour l'IA.
##
## Évalue les options disponibles et retourne la meilleure action selon :
## - L'état de santé de l'unité
## - La proximité et le type des ennemis
## - La distance à l'objectif
##
## @tutorial: Utilisé par AIController
## @see: AIController, UnitTargetingComponent

# ========================================
# CLASSE DECISION
# ========================================

## Représente une décision prise par l'IA.
class Decision:
	## Action à effectuer.
	var action: String
	
	## Priorité (plus élevé = plus important).
	var priority: int
	
	## Raison de la décision.
	var reason: String
	
	## Cible spécifique.
	var target: Node2D
	
	func _init(p_action: String, p_priority: int = 0, p_reason: String = "", p_target: Node2D = null):
		action = p_action
		priority = p_priority
		reason = p_reason
		target = p_target

# ========================================
# CONSTANTES
# ========================================

## Seuil de PV pour fuir (20%).
const FLEE_HEALTH_THRESHOLD: float = 0.2

## Seuil de PV pour se replier (40%).
const RETREAT_HEALTH_THRESHOLD: float = 0.4

# ========================================
# LOGIQUE DE DÉCISION
# ========================================

## Prend une décision tactique.
##
## Hiérarchie de priorités :
## 1. Survie (PV bas)
## 2. Combat (ennemi détecté)
## 3. Objectif (progression vers base)
##
## @param unit: Unité concernée
## @param nearest_enemy: Ennemi prioritaire
## @param enemy_base: Base ennemie
## @param ally_base: Base alliée
## @param state: État tactique actuel
## @return: Decision à exécuter
func decide(
	unit: Node2D,
	nearest_enemy: Node2D,
	enemy_base: Base,
	ally_base: Base,
	state: String
) -> Decision:
	
	if not unit or not is_instance_valid(unit) or not (unit is Unit):
		return Decision.new("IDLE", 0, "Unité invalide")
	
	var unit_typed := unit as Unit
	var health_percent := _get_health_percent(unit_typed)
	var can_attack: bool = unit_typed.can_attack
	
	# Priorité 1 : Survie
	if health_percent < FLEE_HEALTH_THRESHOLD:
		return Decision.new("FLEE", 100, "PV critiques (%.0f%%)" % (health_percent * 100))
	
	if health_percent < RETREAT_HEALTH_THRESHOLD:
		return Decision.new("RETREAT", 90, "PV bas (%.0f%%)" % (health_percent * 100))
	
	# Priorité 2 : Combat
	if can_attack and nearest_enemy and is_instance_valid(nearest_enemy):
		return _evaluate_combat_decision(unit_typed, nearest_enemy)
	
	# Priorité 3 : Objectif
	if enemy_base and is_instance_valid(enemy_base):
		var distance := unit.global_position.distance_to(enemy_base.global_position)
		return Decision.new("MOVE_TO_BASE", 50, "Vers base (%.0fm)" % distance, enemy_base)
	
	# Fallback
	return Decision.new("IDLE", 0, "Aucune action disponible")


## Évalue une décision de combat.
##
## @param unit: Unité concernée
## @param target: Cible ennemie
## @return: Decision de combat appropriée
func _evaluate_combat_decision(unit: Unit, target: Node2D) -> Decision:
	var distance := unit.global_position.distance_to(target.global_position)
	var attack_range := unit.combat_component.attack_range if unit.combat_component else 150.0
	var range_margin := 60.0 if target is Base else 10.0
	
	# À portée : attaque
	if distance <= attack_range + range_margin:
		if target is Unit:
			return Decision.new("ATTACK_UNIT", 80, "Unité à portée (%.0fm)" % distance, target)
		else:
			return Decision.new("ATTACK_BASE", 80, "Base à portée (%.0fm)" % distance, target)
	
	# Hors portée : poursuit
	if target is Unit:
		var target_unit := target as Unit
		if target_unit.unit_size == "L":
			return Decision.new("PURSUE_L_UNIT", 70, "Poursuite unité L (%.0fm)" % distance, target)
		else:
			return Decision.new("PURSUE_UNIT", 60, "Poursuite unité S/M (%.0fm)" % distance, target)
	else:
		return Decision.new("MOVE_TO_BASE", 50, "Vers base (%.0fm)" % distance, target)

# ========================================
# HELPERS
# ========================================

## Retourne le pourcentage de santé d'une unité.
##
## @param unit: Unité à évaluer
## @return: Pourcentage entre 0.0 et 1.0
func _get_health_percent(unit: Unit) -> float:
	if unit.health_component:
		return unit.health_component.get_health_percent()
	return 0.0
