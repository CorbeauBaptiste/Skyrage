extends Unit

# --- paramètres exportés pour réglage en éditeur ---
@export var base_pos: Vector2 = Vector2(1381.0, 299.0)
@export var detection_radius: float = 200.0
@export var attack_range: float = 30.0
@export var attack_damage: int = 150
@export var attack_cooldown: float = 0.5
@export var move_speed: float = 24.0
@export var stuck_offset: float = 10.0
@export var stuck_threshold: int = 10 # frames pour considérer bloqué

# --- état interne ---
var target_unit: Node2D = null
var _can_attack: bool = true
var _attack_timer: Timer = null
var _detection_area: Area2D = null

# Pour le débloquage
var _last_positions: Array = []
var _is_unstucking: bool = false
var _unstuck_target: Vector2
var _unstuck_timer: float = 0.0
var _previous_target: Vector2 = Vector2.ZERO
var _last_unstuck_position: Vector2 = Vector2.ZERO # jamais null

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

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	# Gestion cible
	if target_unit != null and not is_instance_valid(target_unit):
		_release_target(target_unit)
		_acquire_unique_target()

	if target_unit == null:
		_acquire_unique_target()

	if is_instance_valid(target_unit):
		if not _is_unstucking:
			target = target_unit.global_position
		var dist = global_position.distance_to(target_unit.global_position)
		if dist <= attack_range:
			_try_attack(target_unit)
	else:
		if target == null:
			target = base_pos

	# -----------------------
	# Détection blocage et débloquage
	# -----------------------
	_record_position(global_position)

	if _is_unstucking:
		_unstuck_timer -= delta
		target = _unstuck_target
		await get_tree().create_timer(1.0).timeout
		# si débloquage terminé ou l'unité a bougé
		if _unstuck_timer <= 0.0 or not _is_stuck():
			_reset_after_unstuck()
	else:
		# Vérifier stuck seulement si l'unité a bougé depuis le dernier débloquage
		if _is_stuck() and (_last_unstuck_position == Vector2.ZERO or global_position.distance_to(_last_unstuck_position) > 1.0):
			_previous_target = target
			_unstuck_target = global_position + Vector2(-stuck_offset, 0) # toujours à gauche
			_unstuck_timer = 3.0
			_is_unstucking = true
			_last_unstuck_position = global_position

func _reset_after_unstuck() -> void:
	_is_unstucking = false
	target = _previous_target
	_last_unstuck_position = Vector2.ZERO

# -----------------------
# Détection / allocation
# -----------------------
func _create_detection_area(radius: float) -> void:
	_detection_area = Area2D.new()
	_detection_area.name = "DetectionArea"
	var coll = CollisionShape2D.new()
	var circle = CircleShape2D.new()
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

func _acquire_unique_target() -> bool:
	if not _detection_area:
		return false
	var bodies = _detection_area.get_overlapping_bodies()
	var candidates := []
	for b in bodies:
		if not is_instance_valid(b):
			continue
		if b is Unit and b.has_method("get_side"):
			if b.get_side() != self.get_side():
				candidates.append(b)

	if candidates.is_empty():
		return false

	var best = null
	var best_len = 999999
	var best_dist = 1e9
	for c in candidates:
		var claimers = []
		if c.has_meta("claimer_ids"):
			claimers = c.get_meta("claimer_ids")
		var l = claimers.size()
		var d = global_position.distance_to(c.global_position)
		if l < best_len or (l == best_len and d < best_dist):
			best = c
			best_len = l
			best_dist = d

	if best:
		_claim_target(best)
		return true

	return false

func _claim_target(enemy: Node) -> void:
	if not is_instance_valid(enemy):
		return
	if target_unit and target_unit != enemy:
		_release_target(target_unit)

	var ids = []
	if enemy.has_meta("claimer_ids"):
		ids = enemy.get_meta("claimer_ids")
	var myid = str(self.get_instance_id())
	if myid not in ids:
		ids.append(myid)
		enemy.set_meta("claimer_ids", ids)

	target_unit = enemy
	target = enemy.global_position

func _release_target(enemy: Node) -> void:
	if not is_instance_valid(enemy):
		if target_unit == enemy:
			target_unit = null
			target = base_pos
		return

	if enemy.has_meta("claimer_ids"):
		var ids = enemy.get_meta("claimer_ids")
		var myid = str(self.get_instance_id())
		if myid in ids:
			ids.erase(myid)
			enemy.set_meta("claimer_ids", ids)

	if target_unit == enemy:
		target_unit = null
		target = base_pos

# -----------------------
# Gestion du stuck
# -----------------------
func _record_position(pos: Vector2) -> void:
	if _last_positions == null:
		_last_positions = []
	_last_positions.append(pos)
	if _last_positions.size() > stuck_threshold:
		_last_positions.pop_front()

func _is_stuck() -> bool:
	if _last_positions.size() < stuck_threshold:
		return false
	var first_pos = _last_positions[0]
	for p in _last_positions:
		if p.distance_to(first_pos) > 0.2:
			return false
	return true

# -----------------------
# Attaque
# -----------------------
func _try_attack(enemy: Node) -> void:
	if not is_instance_valid(enemy):
		return
	if not _can_attack:
		return
	if enemy is Unit and enemy.has_method("get_side") and enemy.get_side() != self.get_side():
		if enemy.has_method("get_health") and enemy.has_method("set_health"):
			var old_hp = enemy.get_health()
			enemy.set_health(old_hp - attack_damage)
		elif enemy.has_method("take_damage"):
			enemy.take_damage(attack_damage)

		_can_attack = false
		_attack_timer.start()

func _on_attack_timer_timeout() -> void:
	_can_attack = true
