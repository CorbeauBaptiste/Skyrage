extends Unit

# --- paramètres exportés ---
@export var base_pos: Vector2 = Vector2(1381.0, 299.0)
@export var detection_radius: float = 200.0
@export var attack_range: float = 30.0
@export var attack_damage: int = 150
@export var attack_cooldown: float = 0.5
@export var move_speed: float = 24.0

# --- rayons + affichage pour obstacle devant ---
@export var ray_count: int = 9
@export var ray_spread_deg: float = 60.0
@export var front_check_distance: float = 50.0
@export var front_collision_mask: int = 1
@export var debug_ray_width: float = 3.0
@export var debug_free_color: Color = Color(0, 1, 0)
@export var debug_hit_color: Color = Color(1, 0, 0)

# --- lévitation visuelle ---
@export var lift_height: float = 5.0
@export var lift_smooth: float = 2.0

# --- évitement instantané (mouvement) ---
@export var avoid_instant_strength: float = 1.35
@export var avoid_angle_deg: float = 35.0
@export var steer_burst_time: float = 0.18  # durée pendant laquelle on pilote nous-mêmes

# --- état interne ---
var target_unit: Node2D = null
var _can_attack: bool = true
var _attack_timer: Timer
var _detection_area: Area2D

# visuel pour lévitation
var _visual_node: Node2D = null
var _visual_base_pos: Vector2 = Vector2.ZERO
var _current_lift: float = 0.0
var _desired_lift: float = 0.0

# lignes pour debug (Line2D)
var _ray_lines: Array[Line2D] = []

# steering burst
var _steer_timer: float = 0.0
var _steer_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	set_health(1200)
	set_speed(move_speed)
	target = base_pos

	_create_detection_area(detection_radius)

	_attack_timer = Timer.new()
	_attack_timer.one_shot = true
	_attack_timer.wait_time = attack_cooldown
	add_child(_attack_timer)
	_attack_timer.connect("timeout", Callable(self, "_on_attack_timer_timeout"))

	_find_visual_node_for_lift()
	_create_ray_lines()

func _physics_process(delta: float) -> void:
	# -------- Gestion cible/attaque (ne bouge pas encore) --------
	if target_unit != null and not is_instance_valid(target_unit):
		_release_target(target_unit)
		_acquire_unique_target()

	if target_unit == null:
		_acquire_unique_target()

	var desired_target_pos: Vector2 = base_pos
	if is_instance_valid(target_unit):
		desired_target_pos = target_unit.global_position
		var dist: float = global_position.distance_to(desired_target_pos)
		if dist <= attack_range:
			_try_attack(target_unit)
	else:
		if target != null:
			desired_target_pos = target

	# -------- Rayons alignés vers la destination --------
	var dir_to_goal := (desired_target_pos - global_position).normalized()
	if dir_to_goal == Vector2.ZERO:
		dir_to_goal = Vector2.RIGHT.rotated(rotation)

	var hit_info := _check_rays_and_update_lines(dir_to_goal)
	var hit_obstacle: bool = hit_info.any_hit
	_desired_lift = -abs(lift_height) if hit_obstacle else 0.0
	var k: float = clamp(lift_smooth * delta, 0.0, 1.0)
	_current_lift = lerp(_current_lift, _desired_lift, k)
	if _visual_node != null:
		_visual_node.position = _visual_base_pos + hit_info.diagonal_offset + Vector2(0, _current_lift)

	# -------- Steering burst AVANT le super --------
	if hit_obstacle:
		# Choisit le côté opposé au contact le plus proche/chargé
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
		_steer_velocity = desired_dir * move_speed * avoid_instant_strength
		_steer_timer = steer_burst_time
	else:
		# si pas d’obstacle on laisse finir le burst puis mouvement normal
		pass

	# Si on a un burst actif, on dirige nous-mêmes et on sort
	if _steer_timer > 0.0:
		_steer_timer -= delta
		velocity = _steer_velocity
		move_and_slide()
		return

	# -------- Mouvement normal piloté par Unit --------
	# On met à jour la target puis on délègue à Unit
	target = desired_target_pos
	super._physics_process(delta)

# -----------------------
# Création Area2D pour cibles
# -----------------------
func _create_detection_area(radius: float) -> void:
	_detection_area = Area2D.new()
	_detection_area.name = "DetectionArea"
	var coll: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = radius
	coll.shape = circle
	_detection_area.add_child(coll)
	_detection_area.position = Vector2.ZERO
	_detection_area.monitoring = true
	_detection_area.monitorable = true
	_detection_area.collision_layer = 0
	_detection_area.collision_mask = 2
	add_child(_detection_area)

	_detection_area.connect("body_entered", Callable(self, "_on_detection_body_entered"))
	_detection_area.connect("body_exited", Callable(self, "_on_detection_body_exited"))

func _on_detection_body_entered(body: Node) -> void:
	if not is_instance_valid(body):
		return
	_acquire_unique_target()

func _on_detection_body_exited(body: Node) -> void:
	if not is_instance_valid(body):
		return
	if body == target_unit:
		_release_target(body)
		_acquire_unique_target()

# -----------------------
# Création Line2D pour rayons
# -----------------------
func _create_ray_lines() -> void:
	for l in _ray_lines:
		if is_instance_valid(l):
			l.queue_free()
	_ray_lines.clear()

	if ray_count < 1:
		ray_count = 1

	for i in range(ray_count):
		var line: Line2D = Line2D.new()
		line.name = "RayLine_%d" % i
		line.width = debug_ray_width
		line.add_point(Vector2.ZERO)
		line.add_point(Vector2.ZERO)
		line.default_color = debug_free_color
		add_child(line)
		_ray_lines.append(line)

# -----------------------
# Check rayons alignés sur dir_ref + MAJ Line2D
# Renvoie un petit "struct" Dictionary avec les infos utiles
# -----------------------
func _check_rays_and_update_lines(dir_ref: Vector2) -> Dictionary:
	var space_state := get_world_2d().direct_space_state
	var any_hit := false

	var left_hit := false
	var right_hit := false
	var left_hits_count := 0
	var right_hits_count := 0
	var nearest_left_t := INF
	var nearest_right_t := INF

	var half_spread: float = deg_to_rad(ray_spread_deg) * 0.5

	for i in range(_ray_lines.size()):
		var ti: float = 0.5 if _ray_lines.size() == 1 else float(i) / float(_ray_lines.size() - 1)
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

		var line: Line2D = _ray_lines[i]
		line.set_point_position(0, Vector2.ZERO)
		line.set_point_position(1, rdir * front_check_distance)
		line.default_color = debug_hit_color if hit else debug_free_color

	# Décalage visuel (esthétique diagonale)
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

# -----------------------
# Recherche visuel pour lévitation
# -----------------------
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

# -----------------------
# Gestion cibles / attaque
# -----------------------
func _acquire_unique_target() -> bool:
	if _detection_area == null:
		return false

	var bodies: Array = _detection_area.get_overlapping_bodies()
	var candidates: Array[Node2D] = []
	for b in bodies:
		if not is_instance_valid(b):
			continue
		if b is Unit and b.has_method("get_side") and b.get_side() != self.get_side():
			candidates.append(b as Node2D)
	if candidates.is_empty():
		return false

	var best: Node2D = null
	var best_len: int = 999999
	var best_dist: float = 1e9

	for c in candidates:
		var claimers: Array = []
		if c.has_meta("claimer_ids"):
			var meta_val: Variant = c.get_meta("claimer_ids")
			if meta_val is Array:
				claimers = (meta_val as Array)
		var l: int = claimers.size()
		var d: float = global_position.distance_to(c.global_position)
		if l < best_len or (l == best_len and d < best_dist):
			best = c
			best_dist = d
			best_len = l

	if best != null:
		_claim_target(best)
		return true
	return false

func _claim_target(enemy: Node) -> void:
	if not is_instance_valid(enemy):
		return
	if target_unit != null and target_unit != enemy:
		_release_target(target_unit)

	var ids: Array[String] = []
	if enemy.has_meta("claimer_ids"):
		var meta_val: Variant = enemy.get_meta("claimer_ids")
		if meta_val is Array:
			ids = ((meta_val as Array).duplicate() as Array)
	var myid: String = str(self.get_instance_id())
	if not ids.has(myid):
		ids.append(myid)
		enemy.set_meta("claimer_ids", ids)

	target_unit = enemy as Node2D
	target = enemy.global_position

func _release_target(enemy: Node) -> void:
	if not is_instance_valid(enemy):
		if target_unit == enemy:
			target_unit = null
			target = base_pos
		return

	if enemy.has_meta("claimer_ids"):
		var ids: Array[String] = []
		var meta_val: Variant = enemy.get_meta("claimer_ids")
		if meta_val is Array:
			ids = ((meta_val as Array).duplicate() as Array)
		var myid: String = str(self.get_instance_id())
		if ids.has(myid):
			ids.erase(myid)
			enemy.set_meta("claimer_ids", ids)

	if target_unit == enemy:
		target_unit = null
		target = base_pos

func _try_attack(enemy: Node) -> void:
	if not is_instance_valid(enemy):
		return
	if not _can_attack:
		return
	if enemy is Unit and enemy.has_method("get_side") and enemy.get_side() != self.get_side():
		if enemy.has_method("get_health") and enemy.has_method("set_health"):
			var old_hp: int = (enemy.get_health() as int)
			enemy.set_health(old_hp - attack_damage)
		elif enemy.has_method("take_damage"):
			enemy.take_damage(attack_damage)
		_can_attack = false
		_attack_timer.start()

func _on_attack_timer_timeout() -> void:
	_can_attack = true
