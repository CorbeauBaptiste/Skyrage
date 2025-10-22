extends Unit

## Ange Déchu - Unité équilibrée de l'Enfer (M).
##
## SPECS :
## - Taille : M (moyenne, équilibrée)
## - PV : 900
## - Dégâts : 250
## - Vitesse : 24
## - Portée : 150 (moyenne)

var _spawn_move_time: float = 0.0
const INITIAL_MOVE_DURATION: float = 1.0
var _initial_move_done: bool = false


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
	
	super._ready()


## Implémente le mouvement de l'Ange Déchu
##
## Comportement : Avance en continu vers la cible avec évitement
##
## @param delta: Temps écoulé
func handle_movement(_delta: float) -> void:
	if not movement_component or not targeting_component:
		return
	
	# Pas de cible = on s'arrête
	if not targeting_component.target:
		movement_component.stop()
		return
	
	# Récupère la position de la cible
	var target_pos: Vector2 = targeting_component.get_target_position()
	
	if target_pos == Vector2.ZERO:
		movement_component.stop()
		return
	
	# Calcule la distance
	var distance: float = global_position.distance_to(target_pos)
	
	# Si à portée, on s'arrête pour attaquer
	if distance <= attack_range:
		movement_component.stop()
		return
	
	# Sinon, on avance avec évitement
	var direction: Vector2 = global_position.direction_to(target_pos)
	var avoidance: Vector2 = movement_component.calculate_avoidance()
	
	# Combinaison direction + évitement
	var final_direction: Vector2 = (direction + avoidance * movement_component.avoidance_weight).normalized()
	
	# Applique le mouvement
	movement_component.apply_velocity(final_direction)
