extends Unit

## Archange - Unité rapide du Paradis (S).
##
## SPECS :
## - Taille : S (petite, rapide)
## - PV : 500
## - Dégâts : 150
## - Vitesse : 30
## - Portée : 50 (courte, corps à corps)
## - IA : Navigation avec détection de murs et virage à droite


enum Direction { UP, RIGHT, DOWN, LEFT }

const SPEED: float = 30.0
const TURN_COOLDOWN: float = 0.2


var current_direction: Direction = Direction.UP
var turn_timer: float = 0.0
var old_position: Vector2 = Vector2.ZERO
var target_movement: Node = null


@onready var droite_area: Area2D = null


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
	
	can_attack = true
	
	super._ready()
	
	await get_tree().process_frame
	
	_setup_archange()


func _setup_archange() -> void:
	droite_area = get_node_or_null("Droite")
	
	if not droite_area:
		droite_area = Area2D.new()
		droite_area.name = "Droite"
		droite_area.collision_mask = 1 
		
		var collision_shape := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(40, 10) 
		collision_shape.shape = shape
		collision_shape.position = Vector2(20, 0)
		
		droite_area.add_child(collision_shape)
		add_child(droite_area)
	
	target_movement = _find_enemy_base()
	if target_movement:
		print("Archange cible la base: %s" % target_movement.name)


func handle_movement(delta: float) -> void:
	if not movement_component:
		return
	
	if target_movement and is_instance_valid(target_movement):
		_navigate_to_target(delta)
	else:
		_navigate_by_walls(delta)


func _navigate_to_target(delta: float) -> void:
	var direction := global_position.direction_to(target_movement.global_position)
	
	var avoidance := movement_component.calculate_avoidance()
	var final_direction := (direction + avoidance * 0.3).normalized()
	
	movement_component.apply_velocity(final_direction)


func _navigate_by_walls(delta: float) -> void:
	turn_timer -= delta
	if turn_timer < 0:
		turn_timer = 0
	
	if turn_timer == 0:
		var droite_bodies: Array = []
		if droite_area:
			droite_bodies = droite_area.get_overlapping_bodies()
		
		if droite_bodies.is_empty():
			current_direction = (current_direction + 1) % 4
			turn_timer = TURN_COOLDOWN
	
	_update_droite_rotation(current_direction)
	
	var dir := _match_current_direction(current_direction)
	
	old_position = global_position
	var avoidance := movement_component.calculate_avoidance()
	var final_direction := (dir + avoidance * 0.2).normalized()
	
	movement_component.apply_velocity(final_direction)
	
	await get_tree().process_frame
	var actual_speed := (global_position - old_position).length() / delta
	
	if actual_speed < 1.0:
		current_direction = (current_direction + 3) % 4


func _match_current_direction(direction: Direction) -> Vector2:
	match direction:
		Direction.UP:
			return Vector2(0, -1)
		Direction.RIGHT:
			return Vector2(1, 0)
		Direction.DOWN:
			return Vector2(0, 1)
		Direction.LEFT:
			return Vector2(-1, 0)
	return Vector2.ZERO


func _update_droite_rotation(direction: Direction) -> void:
	if not droite_area:
		return
	
	var rotation_deg := 0.0
	match direction:
		Direction.UP:
			rotation_deg = -90
		Direction.RIGHT:
			rotation_deg = 0
		Direction.DOWN:
			rotation_deg = 90
		Direction.LEFT:
			rotation_deg = 180
	
	droite_area.rotation_degrees = rotation_deg


func _find_enemy_base() -> Base:
	for base in get_tree().get_nodes_in_group("bases"):
		if is_instance_valid(base) and base is Base:
			if base.get_side() != is_hell_faction:
				return base
	return null
