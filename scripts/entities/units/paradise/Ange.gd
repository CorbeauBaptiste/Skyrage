extends Unit

## Ange (Chérubin) - Unité équilibrée du Paradis (M).
##
## SPECS :
## - Taille : M (moyenne, équilibrée)
## - PV : 800
## - Dégâts : 300
## - Vitesse : 24
## - Portée : 150 (moyenne)

var _spawn_move_time: float = 0.0
const INITIAL_MOVE_DURATION: float = 1.0
var _initial_move_done: bool = false

@export var avoid_radius: float = 25.0
@export var wall_detect_distance: float = 30.0
@export var debug_rays: bool = false

var avoiding: bool = false
var debug_rays_data: Array = []


func _ready() -> void:
	unit_name = "Chérubin"
	unit_size = "M"
	max_health = 800
	base_damage = 300
	base_speed = 24.0
	attack_range = 150.0
	attack_cooldown = 2.5
	detection_radius = 200.0
	is_hell_faction = false

	can_attack = true
	
	super._ready()


##
##
## @param delta: Temps écoulé
func handle_movement(delta: float) -> void:
	if not movement_component:
		return
	
	debug_rays_data.clear()
	
	var target_pos: Vector2 = Vector2.ZERO
	if targeting_component and targeting_component.target:
		target_pos = targeting_component.get_target_position()
	
	if target_pos == Vector2.ZERO:
		movement_component.stop()
		return
	
	var direction_to_target := (target_pos - global_position).normalized()
	var move_dir: Vector2 = direction_to_target
	var space_state := get_world_2d().direct_space_state
	
	var circle_shape := CircleShape2D.new()
	circle_shape.radius = avoid_radius
	var shape_params := PhysicsShapeQueryParameters2D.new()
	shape_params.shape = circle_shape
	shape_params.transform = Transform2D(0, global_position)
	shape_params.exclude = [self]
	shape_params.collision_mask = 1
	var collision_bodies := space_state.intersect_shape(shape_params)
	
	if collision_bodies.size() > 0:
		avoiding = true
		move_dir = _find_best_free_direction(move_dir, space_state)
	else:
		avoiding = false
	
	var avoidance := movement_component.calculate_avoidance()
	var final_direction := (move_dir + avoidance * 0.3).normalized()
	movement_component.apply_velocity(final_direction)
	
	if debug_rays:
		queue_redraw()

func _find_best_free_direction(base_dir: Vector2, space_state: PhysicsDirectSpaceState2D) -> Vector2:
	var angles := [-60, -30, 0, 30, 60]
	var best_dir := base_dir
	var max_distance := 0.0
	var ray_length := avoid_radius * 1.5
	
	for angle in angles:
		var dir := base_dir.rotated(deg_to_rad(angle))
		var ray := PhysicsRayQueryParameters2D.create(global_position, global_position + dir * ray_length)
		ray.exclude = [self]
		ray.collision_mask = 1
		var result := space_state.intersect_ray(ray)
		
		var distance := ray_length
		if result:
			distance = global_position.distance_to(result.position)
		
		_add_debug_ray(global_position, dir * ray_length, result)
		
		if distance > max_distance:
			max_distance = distance
			best_dir = dir
	
	return best_dir.normalized()

func _add_debug_ray(start: Vector2, direction: Vector2, hit: Dictionary) -> void:
	if not debug_rays:
		return
	var color := Color.RED if hit else Color.GREEN
	debug_rays_data.append({"start": start, "end": start + direction, "color": color})

func _draw() -> void:
	if not debug_rays:
		return
	for ray in debug_rays_data:
		draw_line(to_local(ray.start), to_local(ray.end), ray.color, 2)
