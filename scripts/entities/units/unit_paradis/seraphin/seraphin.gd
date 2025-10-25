extends Unit

@export var pos_base: Vector2 = Vector2(612.0, 727.0) # Position de la base approxi
@export var speed_sera: float = 20.0 # Rapidité de l'unité
@export var att_cooldown: float = 0.5 # Temps de rechargement entre chaque attaques 
@export var avoid_time: float = 1.0 # durée d'esquives
@export var avoid_distance: float = 100.0 # distance de l'esquive

var can_attack := true # entrain d'attaquer
var avoiding := false  # entrain d'esquiver
var avoid_timer := 0.0


func _ready():
	set_health(1600)
	set_speed(speed_sera)
	target = pos_base
	$Timer.timeout.connect(_if_attcooldown_end)

func _physics_process(delta):
	if avoiding:
		avoid_timer -= delta
		if avoid_timer <= 0.0:
			avoiding = false
			target = global_position.lerp(pos_base,0.2)
			await get_tree().create_timer(0.1)
	else:
		_move_to()
		
	var last_pos = global_position
	super._physics_process(delta)

	if global_position.distance_to(last_pos) < 0.1 and not avoiding:
		_start_avoidance()
	
	if global_position.distance_to(pos_base) < 10.0:
		target = null
		velocity = Vector2.ZERO

	if can_attack and _check_and_attack():
		set_speed(speed_sera * 0.5)
		_check_and_attack()
	else : 
		set_speed(speed_sera)

# fonction pour calculer une cible intermédiaire
func _move_to():
	if target == null:
		target = pos_base
		
	var direction = (pos_base - global_position).normalized()
	target = global_position + direction * 60.0

# fonction qui calcule la distance face à un obstacle
func _start_avoidance():
	avoiding = true
	avoid_timer = avoid_time

	var to_base = (pos_base - global_position).normalized()

	# Directions latérales gauche/droite 
	var left_dir = Vector2(-to_base.y, to_base.x)
	var right_dir = Vector2(to_base.y, -to_base.x)

	# On évalue laquelle rapproche le plus de la base
	var left_pos = global_position + left_dir * avoid_distance
	var right_pos = global_position + right_dir * avoid_distance

	var left_dist = left_pos.distance_to(pos_base)
	var right_dist = right_pos.distance_to(pos_base)

	# Comparaison entre les deux distances
	var best_dir = right_dir if right_dist < left_dist else left_dir
	target = global_position + best_dir * avoid_distance


# fonction pour vérifie la présence d'un ennemis autour de l'unité
func _check_and_attack():
	var enemies = $Range.get_overlapping_bodies()
	for body in enemies:
		if is_instance_valid(body) and body != self and body.has_method("get_side") and body.get_side() != self.get_side():
			attack(body)
			can_attack = false
			$Timer.start(att_cooldown)
			break

# fonction qui permets à l'unité d'attaquer lorsque le cooldown est fini
func _if_attcooldown_end():
	can_attack = true

# permets de gérer les attaque sur les ennemies
func attack(target_body):
	var target_pos = target_body.global_position
	$Marker2D.look_at(target_pos)

	var arrow_instance = arrow.instantiate()
	arrow_instance.change_sprite("res://assets/sprites/projectiles/vent.png")
	arrow_instance.is_cupidon_arrow = true
	arrow_instance.area_damage = 600
	arrow_instance.area_radius = 20
	arrow_instance.set_target(not self.get_side())

	arrow_instance.rotation = $Marker2D.rotation
	arrow_instance.global_position = $Marker2D.global_position
	add_child(arrow_instance)
