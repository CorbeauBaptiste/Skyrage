extends Unit

# --- paramètres exportés pour réglage en éditeur ---
@export var base_pos: Vector2 = Vector2(1381.0, 299.0)
@export var detection_radius: float = 200.0
@export var attack_range: float = 22.0
@export var attack_damage: int = 150
@export var attack_cooldown: float = 0.5
@export var move_speed: float = 24.0

# --- état interne ---
var target_unit: Node2D = null
var _can_attack: bool = true
var _attack_timer: Timer = null
var _detection_area: Area2D = null

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

	# Si la cible n'est plus valide -> libérer et tenter d'en acquérir une autre
	if target_unit != null and not is_instance_valid(target_unit):
		_release_target(target_unit)
		_acquire_unique_target()

	# Si pas de cible, tenter d'en acquérir (utile si plusieurs unités sont présentes)
	if target_unit == null:
		_acquire_unique_target()

	# comportement de poursuite/attaque
	if is_instance_valid(target_unit):
		target = target_unit.global_position
		var dist = global_position.distance_to(target_unit.global_position)
		if dist <= attack_range:
			_try_attack(target_unit)
	else:
		if target == null:
			target = base_pos

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

	# monitoring activé pour get_overlapping_bodies
	_detection_area.monitoring = true
	_detection_area.monitorable = true

	# adapter layers si nécessaire ; ici on détecte la layer 2 comme dans ton projectile
	_detection_area.collision_layer = 0
	_detection_area.collision_mask = 2

	add_child(_detection_area)

	_detection_area.connect("body_entered", Callable(self, "_on_detection_body_entered"))
	_detection_area.connect("body_exited", Callable(self, "_on_detection_body_exited"))

func _on_detection_body_entered(body: Node) -> void:
	if not is_instance_valid(body):
		return
	# à chaque entrée on tente d'équilibrer / acquérir une cible
	_acquire_unique_target()

func _on_detection_body_exited(body: Node) -> void:
	if not is_instance_valid(body):
		return
	# si c'était notre cible, on la libère et on tente d'en chercher une autre
	if body == target_unit:
		_release_target(body)
		_acquire_unique_target()

# Essaie d'acquérir une cible en respectant la règle "le moins de claimers"
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

	# ✅ Correction ici
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

# Claim / release helpers (utilisent meta sur la cible pour garder une liste d'ids)
func _claim_target(enemy: Node) -> void:
	if not is_instance_valid(enemy):
		return
	# si on avait déjà une cible différente, la relâcher
	if target_unit and target_unit != enemy:
		_release_target(target_unit)

	var ids = []
	if enemy.has_meta("claimer_ids"):
		ids = enemy.get_meta("claimer_ids")
	# ajouter notre instance id si pas présent
	var myid = str(self.get_instance_id())
	if myid in ids:
		pass
	else:
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
