extends Unit

@export var posi: Vector2 = Vector2(635.0, 766.0)
@export var speed_arch: float = 30
@export var attack_cooldown: float = 2.5
var can_attack: bool = true

func _ready():
	set_health(800)
	set_speed(speed_arch)
	target = posi
	$Timer.timeout.connect(_on_Timer_timeout)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if target == null:
		target = posi
	var target_pos = target if target is Vector2 else target.global_position if target else Vector2.ZERO
	velocity = position.direction_to(target_pos) * speed
	move_and_collide(velocity * delta)

	var ennemies = $Range.get_overlapping_bodies()
	if ennemies.size() > 0:
		var valid_enemies = []
		for ennemy in ennemies:
			if is_instance_valid(ennemy) and ennemy != self and ennemy.has_method("get_side") and ennemy.get_side() != self.get_side():
				valid_enemies.append(ennemy)

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
