extends CharacterBody2D
class_name Unit

@export var speed = 100.0: set = set_speed
@export var enfer = false: set = set_side  
@export var health = 500: set = set_health  
@export var damage = 150: set = set_damage
@export var attack_speed = 1.0: set = set_attack_speed 
@export var attack_range = 50.0: set = set_attack_range  
@export var is_zone_attack = false: set = set_zone_attack  

var av = Vector2.ZERO
var avoid_weight = 0.1
var target_radius = 50
var selected = false: set = set_selected
var target = null: set = set_target
var cooldown = 0.0 

var arrow = preload("res://projectile.tscn"): set = set_arrow

func _ready() -> void:
	if has_node("Range"):
		$Range/CollisionShape2D.shape.radius = attack_range
	$Timer.wait_time = attack_speed
	print("Unit ready : side/enfer = ", enfer, " (true=Enfer rouge, false=Paradis blanc)")

func set_selected(value):
	selected = value
	if selected:
		$Sprite2D.self_modulate = Color.AQUA
	else:
		$Sprite2D.self_modulate = Color.WHITE

func set_target(value):
	target = value

func set_arrow(value):
	arrow = value

func set_side(value):
	enfer = value
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color.RED if enfer else Color.WHITE
	print("Unit side set to ", enfer, " – Couleur appliquée")

func avoid():
	var result = Vector2.ZERO
	var neighbors = $Detect.get_overlapping_bodies() if has_node("Detect") else []
	if neighbors:
		for i in neighbors:
			result += i.position.direction_to(position)
		result /= neighbors.size()
	return result.normalized()

func _physics_process(delta: float) -> void:
	cooldown -= delta
	velocity = Vector2.ZERO
	if target:
		velocity = position.direction_to(target)
		if position.distance_to(target) < target_radius:
			target = null
		if position.distance_to(target) < attack_range and cooldown <= 0:
			attack_target(target)
	av = avoid()
	velocity = (velocity + av * avoid_weight).normalized() * speed
	move_and_collide(velocity * delta)
	if velocity != Vector2.ZERO:
		if abs(velocity.x) > abs(velocity.y):
			if velocity.x > 0:
				$AnimationPlayer.play("running-right")
			else:
				$AnimationPlayer.play("running-left")
		else:
			if velocity.y > 0:
				$AnimationPlayer.play("running-down")
			else:
				$AnimationPlayer.play("running-up")
	else:
		$AnimationPlayer.stop()
	
	if Input.is_action_just_pressed("right_mouse") and selected:
		var ennemies = $Range.get_overlapping_bodies()
		if ennemies.size() > 1:
			if $Timer.is_stopped():
				for ennemy in ennemies:
					if ennemy == self or ennemy.get_side() == self.get_side():
						continue
					var ennemy_pos = ennemy.global_position
					$Marker2D.look_at(ennemy_pos)
					var arrow_instance = arrow.instantiate()
					if get_side() == true:
						arrow_instance.change_sprite("res://Fire_0_Preview.png", 4, 7, 12)
						arrow_instance.set_target(false)
					else:
						arrow_instance.change_sprite("res://Pure.png", 5, 5, 16)
						arrow_instance.set_target(true)
					arrow_instance.rotation = $Marker2D.rotation
					arrow_instance.global_position = $Marker2D.global_position
					add_child(arrow_instance)
				$Timer.start()

func attack_target(t: Node2D) -> void:
	if cooldown > 0:
		return
	cooldown = attack_speed
	$Timer.start()
	$Marker2D.look_at(t.global_position)
	var proj = arrow.instantiate()
	proj.damage = damage
	proj.global_position = $Marker2D.global_position
	proj.rotation = $Marker2D.rotation
	get_parent().add_child(proj) 
	print("Auto-attack ! Dmg: ", damage, " (zone: ", is_zone_attack, ")")
	if enfer:
		$AnimationPlayer.play("attack_fire")
	else:
		$AnimationPlayer.play("attack_light")

func set_speed(new_value):
	speed = new_value

func set_health(value):
	health = value
	if health <= 0:
		queue_free()
		set_selected(false)

func set_damage(value):
	damage = value

func set_attack_speed(value):
	attack_speed = value

func set_attack_range(value):
	attack_range = value
	if has_node("Range"):
		$Range/CollisionShape2D.shape.radius = value

func set_zone_attack(value):
	is_zone_attack = value  # Todo : Dmg multiple si true d'apres le GD

func get_side():
	return enfer

func get_health():
	return health
