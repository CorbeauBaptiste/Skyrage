extends Unit

## Ange Déchu - Unité équilibrée de l'Enfer (M).
##
## SPECS :
## - Taille : M (moyenne, équilibrée)
## - PV : 900
## - Dégâts : 250
## - Vitesse : 24
## - Portée : 150 (moyenne)

# ========================================
# COMPONENTS IA
# ========================================

var ai_controller: AIController = null


func _ready() -> void:
	# Définir les propriétés AVANT super._ready()
	unit_name = "Ange Déchu"
	unit_size = "M"
	max_health = 900
	base_damage = 250
	base_speed = 24.0
	attack_range = 150.0
	attack_cooldown = 2.0
	detection_radius = 200.0
	is_hell_faction = true
	
	can_attack = true
	
	super._ready()
	
	await get_tree().process_frame
	
	_setup_ai()


func _setup_ai() -> void:
	ai_controller = _get_or_create_component("AIController", AIController)
	var _ai_decision_tree = _get_or_create_component("AIDecisionTree", AIDecisionTree)
	var _ai_state_evaluator = _get_or_create_component("AIStateEvaluator", AIStateEvaluator)
	var _ai_pathfinding = _get_or_create_component("AIPathfinding", AIPathfinding)
	
	await get_tree().process_frame


func _get_or_create_component(component_name: String, component_type) -> Node:
	var existing := get_node_or_null(component_name)
	if existing:
		return existing
	
	var component = component_type.new()
	component.name = component_name
	add_child(component)
	return component


## ⚠️ MÉTHODE OBLIGATOIRE : Définit le comportement de mouvement.
##
## Cette méthode est appelée par Unit._physics_process() UNIQUEMENT si :
## - Pas d'ennemi à portée
## - Pas d'ordre manuel du joueur
##
## @param delta: Temps écoulé depuis la dernière frame
func handle_movement(delta: float) -> void:
	if not ai_controller:
		if movement_component:
			movement_component.stop()
		return
	
	ai_controller.process_ai(delta)
