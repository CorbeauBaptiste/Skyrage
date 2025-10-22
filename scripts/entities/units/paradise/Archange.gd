extends Unit

## Archange - Unité rapide du Paradis (S).
##
## SPECS :
## - Taille : S (petite, rapide)
## - PV : 500
## - Dégâts : 150
## - Vitesse : 30
## - Portée : 50 (courte, corps à corps)

func _ready() -> void:
	unit_name = "Archange"
	unit_size = "S"
	max_health = 500
	base_damage = 150
	base_speed = 30.0
	attack_range = 50.0
	attack_cooldown = 1.0
	detection_radius = 200.0
	is_hell_faction = false
	
	super._ready()


func handle_movement(_delta: float) -> void:
	## Implémente le mouvement de l'Archange.
	##
	## Comportement : Avance en continu vers la cible avec évitement.
	if not movement_component or not targeting_component:
		return
	
	if not targeting_component.target:
		movement_component.stop()
		return
	
	var target_pos: Vector2 = targeting_component.get_target_position()
	
	if target_pos == Vector2.ZERO:
		movement_component.stop()
		return
	
	var distance: float = global_position.distance_to(target_pos)
	
	if distance <= attack_range:
		movement_component.stop()
		return
	
	var direction: Vector2 = global_position.direction_to(target_pos)
	var avoidance: Vector2 = movement_component.calculate_avoidance()
	
	var final_direction: Vector2 = (direction + avoidance * movement_component.avoidance_weight).normalized()
	
	movement_component.apply_velocity(final_direction)
