extends Unit

## Démon - Unité lourde de l'Enfer avec AoE (L).
##
## SPECS :
## - Taille : L (grosse, lente, AoE)
## - PV : 1800
## - Dégâts : 500 (zone)
## - Vitesse : 20
## - Portée : 300 (longue)

@export var pos_base: Vector2 = Vector2(635.0, 766.0)
@export var att_cooldown: float = 5.0

var current_target: Node = null


func _ready() -> void:
	unit_name = "Démon"
	unit_size = "L"
	max_health = 1800
	base_damage = 500
	base_speed = 20.0
	attack_range = 300.0
	attack_cooldown = 4.0
	detection_radius = 350.0
	is_hell_faction = true
	
	can_attack = true
	
	super._ready()

	# Trouve la base ennemie dynamiquement
	var enemy_base := _find_enemy_base()
	if enemy_base:
		pos_base = enemy_base.global_position


## @param delta: Temps écoulé
func handle_movement(delta: float) -> void:
	if not movement_component:
		return

	# Récupère la cible depuis targeting_component
	current_target = null
	if targeting_component and targeting_component.current_enemy:
		current_target = targeting_component.current_enemy

	# Si on a une cible valide, on s'arrête (le système d'attaque automatique prend le relais)
	if current_target and is_instance_valid(current_target):
		movement_component.stop()
		return

	# Sinon on va vers la base ennemie avec évitement complet (obstacles + unités)
	var direction := global_position.direction_to(pos_base)
	movement_component.apply_velocity_with_avoidance(direction, delta, true)

func _find_enemy_base() -> Node2D:
	for base in get_tree().get_nodes_in_group("bases"):
		if base.has_method("get_side") and base.get_side() != is_hell_faction:
			return base
	return null
	
