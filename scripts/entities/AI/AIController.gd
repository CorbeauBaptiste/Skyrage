extends Node
class_name AIController

## Contrôleur d'intelligence artificielle pour les unités.
##
## Orchestre le processus de décision en combinant :
## - L'évaluation d'état (StateEvaluator)
## - L'arbre de décision (DecisionTree)
## - Le pathfinding
## - La coordination en groupe
##
## @tutorial: Attaché comme enfant d'une Unit
## @see: AIDecisionTree, AIStateEvaluator, AIPathfinding, AIGroupCoordinator

# ========================================
# COMPOSANTS IA
# ========================================

## Référence à l'unité contrôlée.
var unit: Unit = null

## Arbre de décision.
var decision_tree: Node = null

## Évaluateur d'état.
var state_evaluator: Node = null

## Système de pathfinding.
var pathfinding: Node = null

## Coordinateur de groupe (singleton)
var group_coordinator: AIGroupCoordinator = null

# ========================================
# ÉTAT
# ========================================

## État tactique actuel.
var current_state: String = "IDLE"

## Dernière action décidée.
var last_decision: String = ""

# ========================================
# INITIALISATION
# ========================================

func _ready() -> void:
	await get_tree().process_frame
	
	unit = get_parent() as Unit
	if not unit:
		push_error("[IA] AIController doit être enfant d'une Unit")
		queue_free()
		return
	
	_setup_components()
	
	# Récupère le singleton du coordinateur
	group_coordinator = AIGroupCoordinator.get_instance()


## Configure les composants IA.
func _setup_components() -> void:
	decision_tree = unit.get_node_or_null("AIDecisionTree")
	state_evaluator = unit.get_node_or_null("AIStateEvaluator")
	pathfinding = unit.get_node_or_null("AIPathfinding")
	
	if not decision_tree:
		push_error("[IA] AIDecisionTree manquant pour %s" % unit.unit_name)
		return
	
	if not state_evaluator:
		push_error("[IA] AIStateEvaluator manquant pour %s" % unit.unit_name)
		return
	
	if not pathfinding:
		push_error("[IA] AIPathfinding manquant pour %s" % unit.unit_name)
		return
	
	print("[IA] Contrôleur initialisé pour %s" % unit.unit_name)

# ========================================
# BOUCLE PRINCIPALE
# ========================================

func _process(_delta: float) -> void:
	# Nettoie les unités mortes toutes les secondes
	if Engine.get_physics_frames() % 60 == 0 and group_coordinator:
		group_coordinator.cleanup_dead_units()


## Point d'entrée principal de l'IA, appelé depuis Unit.handle_movement().
##
## @param delta: Temps écoulé depuis la dernière frame
func process_ai(delta: float) -> void:
	if not _is_valid():
		return
	
	# Évalue l'état tactique
	current_state = state_evaluator.evaluate_state(unit)
	
	# Trouve la cible prioritaire
	var priority_target: Node2D = null
	if unit.targeting_component:
		priority_target = unit.targeting_component.find_priority_target()
		if priority_target and priority_target is Unit:
			unit.targeting_component.current_enemy = priority_target

	# Prend une décision
	var decision_result = decision_tree.decide(
		unit,
		priority_target,
		_find_enemy_base(),
		_find_ally_base(),
		current_state
	)
	
	if not decision_result:
		return
	
	var decision: String = decision_result.action
	
	# Log les changements de décision
	if decision != last_decision:
		last_decision = decision
		print("[IA] %s - Nouvelle décision: %s" % [unit.unit_name, decision])
	
	_execute_decision(decision, delta)


## Vérifie que tous les composants sont valides.
##
## @return: true si tout est prêt
func _is_valid() -> bool:
	return unit and is_instance_valid(unit) and decision_tree and state_evaluator

# ========================================
# EXÉCUTION DES ACTIONS
# ========================================

## Exécute l'action décidée par l'arbre de décision.
##
## @param decision: Action à exécuter
## @param _delta: Temps écoulé (non utilisé actuellement)
func _execute_decision(decision: String, _delta: float) -> void:
	match decision:
		"MOVE_TO_BASE":
			_move_to_base()
		"PURSUE_L_UNIT":
			_pursue_l_unit()
		"PURSUE_UNIT":
			_pursue_target()
		"ATTACK_UNIT", "ATTACK_BASE":
			pass  # Géré par Unit._physics_process()
		"FLEE":
			_flee()
		"RETREAT":
			_retreat_to_base()
		"IDLE":
			_idle()
		_:
			_move_to_base()


## Déplace l'unité vers la base ennemie.
##
## Calcule un point accessible près de la base au lieu d'aller au centre.
func _move_to_base() -> void:
	var enemy_base: Base = _find_enemy_base()
	if not enemy_base or not pathfinding:
		return
	
	# Calcule un point accessible près de la base
	var base_pos := enemy_base.global_position
	var unit_pos := unit.global_position
	var direction := unit_pos.direction_to(base_pos)
	
	# Point à 200px de la base (en dehors de la zone d'obstacles)
	var target_offset := -direction * 200.0
	var accessible_target := base_pos + target_offset
	
	# Utilise A* vers ce point accessible
	if pathfinding.has_method("move_towards_target"):
		pathfinding.move_towards_target(accessible_target)


## Poursuit une unité L en coordination avec un partenaire.
func _pursue_l_unit() -> void:
	if not state_evaluator or not group_coordinator:
		_pursue_target()  # Fallback sur poursuite normale
		return
	
	# Trouve la cible L la plus proche
	var target_large = state_evaluator.find_closest_L_enemy()

	if not target_large or not is_instance_valid(target_large):
		_move_to_base()  # Pas de cible L, va à la base
		return

	# Assigne cette unité à la cible L dans le coordinateur
	group_coordinator.assign_to_target(unit, target_large)

	# Récupère la position d'attaque assignée (gauche ou droite de la cible)
	var attack_position := group_coordinator.get_attack_position(unit, target_large)

	# Vérifie si on est déjà en formation
	var in_formation := group_coordinator.is_in_formation(unit, target_large)

	if in_formation:
		# En formation : attaque la cible directement
		var distance := unit.global_position.distance_to(target_large.global_position)
		var attack_range := unit.combat_component.attack_range if unit.combat_component else 150.0

		if distance <= attack_range:
			# À portée : définit la cible pour que Unit._physics_process() gère l'attaque
			if unit.targeting_component:
				unit.targeting_component.set_target(target_large)
		else:
			# Trop loin : se rapproche légèrement
			var direction := unit.global_position.direction_to(target_large.global_position)
			if unit.movement_component:
				unit.movement_component.apply_velocity(direction)
	else:
		# Pas encore en formation : va à la position assignée
		var distance_to_pos := unit.global_position.distance_to(attack_position)

		# Si très proche de la position, mouvement direct (évite U-turns)
		if distance_to_pos < 80.0:
			var direction := unit.global_position.direction_to(attack_position)
			if unit.movement_component:
				unit.movement_component.apply_velocity(direction)
		elif pathfinding.has_method("move_towards_target"):
			pathfinding.move_towards_target(attack_position)


## Poursuit la cible prioritaire (comportement classique).
func _pursue_target() -> void:
	if not unit.targeting_component:
		return

	var target: Node2D = unit.targeting_component.find_priority_target()
	if target and is_instance_valid(target):
		var distance := unit.global_position.distance_to(target.global_position)
		var attack_range := unit.combat_component.attack_range if unit.combat_component else 150.0

		# Si très proche de la cible, mouvement direct sans évitement d'obstacles
		if distance < attack_range + 50.0:
			var direction := unit.global_position.direction_to(target.global_position)
			if unit.movement_component:
				unit.movement_component.apply_velocity(direction)
		elif pathfinding.has_method("move_towards_target"):
			pathfinding.move_towards_target(target.global_position)


## Fuit les ennemis proches.
func _flee() -> void:
	if pathfinding.has_method("flee_from_danger"):
		pathfinding.flee_from_danger()
	else:
		_retreat_to_base()


## Se replie vers la base alliée.
##
## Calcule un point accessible près de la base au lieu d'aller au centre.
func _retreat_to_base() -> void:
	var ally_base: Base = _find_ally_base()
	if not ally_base or not pathfinding:
		return
	
	# Calcule un point accessible près de la base
	var base_pos := ally_base.global_position
	var unit_pos := unit.global_position
	var direction := unit_pos.direction_to(base_pos)
	
	# Point à 200px de la base (en dehors de la zone d'obstacles)
	var target_offset := -direction * 200.0
	var accessible_target := base_pos + target_offset
	
	# Utilise A* vers ce point accessible
	if pathfinding.has_method("move_towards_target"):
		pathfinding.move_towards_target(accessible_target)
		

## Arrête tout mouvement.
func _idle() -> void:
	if unit and unit.movement_component:
		unit.movement_component.stop()

# ========================================
# UTILITAIRES
# ========================================

## Trouve la base ennemie.
##
## @return: Base ennemie ou null
func _find_enemy_base() -> Base:
	if not unit or not unit.is_inside_tree():
		return null
	
	var unit_side: bool = unit.get_side()
	
	for base in unit.get_tree().get_nodes_in_group("bases"):
		if is_instance_valid(base) and base is Base and base.get_side() != unit_side:
			return base
	
	return null


## Trouve la base alliée.
##
## @return: Base alliée ou null
func _find_ally_base() -> Base:
	if not unit or not unit.is_inside_tree():
		return null
	
	var unit_side: bool = unit.get_side()
	
	for base in unit.get_tree().get_nodes_in_group("bases"):
		if is_instance_valid(base) and base is Base and base.get_side() == unit_side:
			return base
	
	return null
