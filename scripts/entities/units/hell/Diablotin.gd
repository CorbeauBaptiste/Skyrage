extends Unit

## Diablotin - Unité rapide de l'Enfer (S).
##
## SPECS :
## - Taille : S (petite, rapide)
## - PV : 600
## - Dégâts : 150
## - Vitesse : 30
## - Portée : 50 (courte, corps à corps)
## - Style : Assaut rapide

@export var base_pos: Vector2 = Vector2(635.0, 766.0)

@export_group("Effet visuel de collision")
@export var lift_height: float = 5.0
@export var lift_smooth: float = 2.0

var target_enemy: Node2D = null
var _visual_node: Node2D = null
var _visual_base_pos: Vector2 = Vector2.ZERO
var _current_lift: float = 0.0
var _desired_lift: float = 0.0


func _ready() -> void:
	unit_name = "Diablotin"
	unit_size = "S"
	max_health = 600
	base_damage = 150
	base_speed = 30.0
	attack_range = 50.0
	attack_cooldown = 1.0
	detection_radius = 200.0
	is_hell_faction = true

	can_attack = true

	super._ready()

	await get_tree().process_frame

	_find_visual_node_for_lift()


## @param delta: Temps écoulé
func handle_movement(delta: float) -> void:
	if not movement_component:
		return

	target_enemy = null
	if targeting_component and targeting_component.current_enemy:
		target_enemy = targeting_component.current_enemy

	var desired_target_pos: Vector2 = base_pos
	if is_instance_valid(target_enemy):
		desired_target_pos = target_enemy.global_position
	elif targeting_component and targeting_component.target:
		desired_target_pos = targeting_component.get_target_position()

	var dir_to_goal := (desired_target_pos - global_position).normalized()
	if dir_to_goal == Vector2.ZERO:
		dir_to_goal = Vector2.RIGHT.rotated(rotation)

	# Effet visuel de lift basé sur l'état d'évitement du component
	var is_avoiding := movement_component.is_avoiding_obstacle()
	_update_visual_lift(delta, is_avoiding)

	# Utilise le système d'évitement commun du MovementComponent
	movement_component.apply_velocity_with_avoidance(dir_to_goal, delta)


## Met à jour l'effet visuel de "lift" quand l'unité évite un obstacle.
func _update_visual_lift(delta: float, is_avoiding: bool) -> void:
	_desired_lift = -abs(lift_height) if is_avoiding else 0.0
	var k: float = clamp(lift_smooth * delta, 0.0, 1.0)
	_current_lift = lerp(_current_lift, _desired_lift, k)

	if _visual_node != null:
		_visual_node.position = _visual_base_pos + Vector2(0, _current_lift)


func _find_visual_node_for_lift() -> void:
	var candidates: Array[String] = ["Visual", "Sprite", "Sprite2D", "AnimatedSprite", "AnimatedSprite2D"]
	for cand_name in candidates:
		if has_node(cand_name):
			var n: Node = get_node(cand_name)
			if n is Node2D:
				_visual_node = n as Node2D
				break

	if _visual_node == null:
		for c in get_children():
			if c is Node2D:
				_visual_node = c as Node2D
				break

	if _visual_node != null:
		_visual_base_pos = _visual_node.position
		_current_lift = 0.0
		_desired_lift = 0.0
