extends Unit

## Séraphin - Unité lourde du Paradis avec AoE (L).
##
## SPECS :
## - Taille : L (grosse, lente, AoE)
## - PV : 1600
## - Dégâts : 600 (zone)
## - Vitesse : 20
## - Portée : 300 (longue)

var _spawn_move_time: float = 0.0
const INITIAL_MOVE_DURATION: float = 1.0
var _initial_move_done: bool = false


func _ready() -> void:
	unit_name = "Séraphin"
	unit_size = "L"
	max_health = 1600
	base_damage = 600
	base_speed = 20.0
	attack_range = 300.0
	attack_cooldown = 5.0
	detection_radius = 350.0
	is_hell_faction = false
	
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
