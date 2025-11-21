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

# Le code commenté est le debug visuel

@export var base_pos: Vector2 = Vector2(635.0, 766.0)
@export var ray_count: int = 9
@export var ray_spread_deg: float = 60.0
@export var front_check_distance: float = 50.0
@export var front_collision_mask: int = 1
@export var avoid_instant_strength: float = 1.35
@export var avoid_angle_deg: float = 35.0
@export var steer_burst_time: float = 0.18

# @export var debug_ray_width: float = 3.0
# @export var debug_free_color: Color = Color(0, 1, 0)
# @export var debug_hit_color: Color = Color(1, 0, 0)

@export var lift_height: float = 5.0
@export var lift_smooth: float = 2.0

var target_enemy: Node2D = null
var _visual_node: Node2D = null
var _visual_base_pos: Vector2 = Vector2.ZERO
var _current_lift: float = 0.0
var _desired_lift: float = 0.0
var _steer_timer: float = 0.0
var _steer_velocity: Vector2 = Vector2.ZERO

# var _ray_lines: Array[Line2D] = []


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
	# _create_ray_lines()


##
##
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
	
	var hit_info := _check_rays(dir_to_goal)
	var hit_obstacle: bool = hit_info.any_hit
	
	_desired_lift = -abs(lift_height) if hit_obstacle else 0.0
	var k: float = clamp(lift_smooth * delta, 0.0, 1.0)
	_current_lift = lerp(_current_lift, _desired_lift, k)
	
	if _visual_node != null:
		_visual_node.position = _visual_base_pos + hit_info.diagonal_offset + Vector2(0, _current_lift)
	
	if hit_obstacle:
		var sign := 0
		if hit_info.left_hit and not hit_info.right_hit:
			sign = 1
		elif hit_info.right_hit and not hit_info.left_hit:
			sign = -1
		else:
			if hit_info.nearest_left_t < hit_info.nearest_right_t - 0.02:
				sign = 1
			elif hit_info.nearest_right_t < hit_info.nearest_left_t - 0.02:
				sign = -1
			elif hit_info.left_hits_count != hit_info.right_hits_count:
				sign = 1 if hit_info.left_hits_count > hit_info.right_hits_count else -1
			else:
				sign = -1 if dir_to_goal.x >= 0.0 else 1
		
		var desired_dir := dir_to_goal.rotated(deg_to_rad(sign * avoid_angle_deg)).normalized()
		_steer_velocity = desired_dir * base_speed * avoid_instant_strength
		_steer_timer = steer_burst_time
	
	if _steer_timer > 0.0:
		_steer_timer -= delta
		movement_component.apply_velocity(_steer_velocity.normalized())
		return
	
	movement_component.apply_velocity(dir_to_goal)

func _check_rays(dir_ref: Vector2) -> Dictionary:
	var space_state := get_world_2d().direct_space_state
	var any_hit := false
	var left_hit := false
	var right_hit := false
	var left_hits_count := 0
	var right_hits_count := 0
	var nearest_left_t := INF
	var nearest_right_t := INF
	var half_spread: float = deg_to_rad(ray_spread_deg) * 0.5
	
	for i in range(ray_count):
		var ti: float = 0.5 if ray_count == 1 else float(i) / float(ray_count - 1)
		var angle: float = lerp(-half_spread, half_spread, ti)
		var rdir: Vector2 = dir_ref.rotated(angle)
		var to_global: Vector2 = global_position + rdir * front_check_distance
		
		var q := PhysicsRayQueryParameters2D.new()
		q.from = global_position
		q.to = to_global
		q.exclude = [self]
		q.collision_mask = front_collision_mask
		
		var res: Dictionary = space_state.intersect_ray(q)
		var hit: bool = (res.size() > 0)
		
		if hit:
			any_hit = true
			var hit_pos: Vector2 = (res.get("position", global_position) as Vector2)
			var hit_dist: float = (hit_pos - global_position).length()
			var hit_t: float = clamp(hit_dist / max(front_check_distance, 0.001), 0.0, 1.0)
			
			if angle < 0.0:
				left_hit = true
				left_hits_count += 1
				if hit_t < nearest_left_t:
					nearest_left_t = hit_t
			else:
				right_hit = true
				right_hits_count += 1
				if hit_t < nearest_right_t:
					nearest_right_t = hit_t
		
		# if i < _ray_lines.size():
		# 	var line: Line2D = _ray_lines[i]
		# 	line.set_point_position(0, Vector2.ZERO)
		# 	line.set_point_position(1, rdir * front_check_distance)
		# 	line.default_color = debug_hit_color if hit else debug_free_color
	
	var diagonal_offset := Vector2.ZERO
	if left_hit:
		diagonal_offset = Vector2(-abs(lift_height), -abs(lift_height))
	elif right_hit:
		diagonal_offset = Vector2(abs(lift_height), -abs(lift_height))
	
	return {
		"any_hit": any_hit,
		"left_hit": left_hit,
		"right_hit": right_hit,
		"left_hits_count": left_hits_count,
		"right_hits_count": right_hits_count,
		"nearest_left_t": nearest_left_t,
		"nearest_right_t": nearest_right_t,
		"diagonal_offset": diagonal_offset
	}

func _find_visual_node_for_lift() -> void:
	var candidates: Array[String] = ["Visual", "Sprite", "Sprite2D", "AnimatedSprite", "AnimatedSprite2D"]
	for name in candidates:
		if has_node(name):
			var n: Node = get_node(name)
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

# func _create_ray_lines() -> void:
# 	for l in _ray_lines:
# 		if is_instance_valid(l):
# 			l.queue_free()
# 	_ray_lines.clear()
# 	
# 	if ray_count < 1:
# 		ray_count = 1
# 	
# 	for i in range(ray_count):
# 		var line: Line2D = Line2D.new()
# 		line.name = "RayLine_%d" % i
# 		line.width = debug_ray_width
# 		line.add_point(Vector2.ZERO)
# 		line.add_point(Vector2.ZERO)
# 		line.default_color = debug_free_color
# 		add_child(line)
# 		_ray_lines.append(line)
