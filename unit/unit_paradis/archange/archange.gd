extends Unit

@export var posi: Vector2 = Vector2(635.0, 766.0)
@export var speed_arch: float = 35
@export var attack_cooldown: float = 2.5
@export var avoid_radius: float = 25.0      # réduit pour éviter blocage
@export var wall_detect_distance: float = 30.0  # réduit pour moins de fausses détections
@export var debug_rays: bool = true

var can_attack: bool = true
var avoiding: bool = false
var debug_rays_data: Array = []
var current_enemy: Node2D = null

func _ready():
	set_health(800)
	set_speed(speed_arch)
	target = posi
	$Timer.timeout.connect(_on_Timer_timeout)

func _physics_process(delta: float) -> void:
	debug_rays_data.clear()
	var direction_to_base = (posi - global_position).normalized()
	var move_dir: Vector2 = direction_to_base
	var space_state = get_world_2d().direct_space_state

	# --- Priorité ennemis ---
	var ennemies = $Range.get_overlapping_bodies()
	var valid_enemies = []
	for e in ennemies:
		if is_instance_valid(e) and e != self and e.has_method("get_side") and e.get_side() != self.get_side():
			valid_enemies.append(e)

	if valid_enemies.size() > 0:
		valid_enemies.sort_custom(func(a, b): return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position))
		current_enemy = valid_enemies[0]
		move_dir = (current_enemy.global_position - global_position).normalized()
	else:
		current_enemy = null
		move_dir = direction_to_base

	# --- Détection obstacles ---
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = avoid_radius
	var shape_params = PhysicsShapeQueryParameters2D.new()
	shape_params.shape = circle_shape
	shape_params.transform = Transform2D(0, global_position)
	shape_params.exclude = [self]
	var collision_bodies = space_state.intersect_shape(shape_params)

	if collision_bodies.size() > 0:
		# Obstacles détectés → esquive temporaire
		avoiding = true
		move_dir = _find_best_free_direction(move_dir)
	else:
		avoiding = false
		# move_dir reste basé sur ennemis/base

	# --- Évitement autres unités ---
	var av = avoid()
	var velocity = (move_dir + av * avoid_weight).normalized() * speed
	move_and_collide(velocity * delta)

	update_animation(velocity)
	handle_attack()
	queue_redraw()

# --- Trouve la meilleure direction libre autour de move_dir ---
func _find_best_free_direction(base_dir: Vector2) -> Vector2:
	var space_state = get_world_2d().direct_space_state
	var angles = [-60, -30, 0, 30, 60]  # balayage autour de la direction actuelle
	var best_dir = base_dir
	var max_distance = 0.0
	var ray_length = avoid_radius * 1.5  # juste un peu plus long que avoid_radius

	for angle in angles:
		var dir = base_dir.rotated(deg_to_rad(angle))
		var ray = PhysicsRayQueryParameters2D.create(global_position, global_position + dir * ray_length)
		ray.exclude = [self]
		var result = space_state.intersect_ray(ray)

		var distance = ray_length
		if result:
			distance = global_position.distance_to(result.position)

		_add_debug_ray(global_position, dir * ray_length, result)

		if distance > max_distance:
			max_distance = distance
			best_dir = dir

	return best_dir.normalized()

func _check_ray(dir: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	var ray = PhysicsRayQueryParameters2D.create(global_position, global_position + dir * avoid_radius)
	ray.exclude = [self]
	var hit = space_state.intersect_ray(ray)
	_add_debug_ray(global_position, dir * avoid_radius, hit)
	return hit != null

func _add_debug_ray(start: Vector2, direction: Vector2, hit: Dictionary):
	if not debug_rays:
		return
	var color = Color.RED if hit else Color.GREEN
	debug_rays_data.append({"start": start, "end": start + direction, "color": color})

func _draw():
	if not debug_rays:
		return
	for ray in debug_rays_data:
		draw_line(to_local(ray.start), to_local(ray.end), ray.color, 2)

func update_animation(vel: Vector2):
	if vel != Vector2.ZERO:
		if abs(vel.x) > abs(vel.y):
			$AnimationPlayer.play("running-right" if vel.x > 0 else "running-left")
		else:
			$AnimationPlayer.play("running-down" if vel.y > 0 else "running-up")
	else:
		$AnimationPlayer.stop()

func handle_attack():
	var ennemies = $Range.get_overlapping_bodies()
	var valid_enemies = []
	for e in ennemies:
		if is_instance_valid(e) and e != self and e.has_method("get_side") and e.get_side() != self.get_side():
			valid_enemies.append(e)
	if valid_enemies.size() > 0 and can_attack:
		valid_enemies.sort_custom(func(a, b): return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position))
		attack_closest_enemy(valid_enemies[0])

func attack_closest_enemy(closest: Node2D):
	var ennemy_pos = closest.global_position
	$Marker2D.look_at(ennemy_pos)
	var arrow_instance = arrow.instantiate()
	arrow_instance.change_sprite("res://unit/vent.png")
	arrow_instance.set_target(true)
	arrow_instance.rotation = $Marker2D.rotation
	arrow_instance.global_position = $Marker2D.global_position
	add_child(arrow_instance)
	can_attack = false
	$Timer.start(attack_cooldown)

func _on_Timer_timeout():
	can_attack = true
