extends Unit

## Archange - Unité rapide du Paradis (S).
##
## SPECS :
## - Taille : S (petite, rapide)
## - PV : 500
## - Dégâts : 150
## - Vitesse : 30
## - Portée : 50 (courte, corps à corps)

var _spawn_move_time: float = 0.0
const INITIAL_MOVE_DURATION: float = 1.0
var _initial_move_done: bool = false


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
	
	can_attack = false
	
	super._ready()


##
##
## @param delta: Temps écoulé
func handle_movement(delta: float) -> void:
	if not movement_component:
		return
	
	# ⚠️ COMPORTEMENT TEMPORAIRE (template de base)
	if not _initial_move_done:
		_spawn_move_time += delta
		if _spawn_move_time >= INITIAL_MOVE_DURATION:
			_initial_move_done = true
			movement_component.stop()
			return
		
		if targeting_component and targeting_component.target:
			var target_pos: Vector2 = targeting_component.get_target_position()
			var direction: Vector2 = global_position.direction_to(target_pos)
			var avoidance: Vector2 = movement_component.calculate_avoidance()
			var final_direction: Vector2 = (direction + avoidance * 0.6).normalized()
			movement_component.apply_velocity(final_direction)
		return
	
	movement_component.stop()
