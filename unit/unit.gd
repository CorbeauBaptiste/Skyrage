extends CharacterBody2D
class_name Unit

@export var speed = 100: set = set_speed
@export var enfer = true: set = set_side
@export var health = 20: set = set_health
@export var attack_speed = 1: set = set_attack_speed
var av = Vector2.ZERO
var avoid_weight = 0.1
var target_radius = 5
var selected = false:
	set = set_selected
var target = null:
	set = set_target

var arrow = preload("res://unit/projectile.tscn"):
	set = set_arrow

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

func avoid():
	var result = Vector2.ZERO
	var neighbors = $Detect.get_overlapping_bodies()
	if neighbors:
		for i in neighbors:
			result += i.position.direction_to(position)
		result /= neighbors.size()
	return result.normalized()

func _physics_process(delta: float) -> void:
	velocity = Vector2.ZERO
	if target:
		velocity = position.direction_to(target)
		if position.distance_to(target) < target_radius:
			target = null
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
			print("detect")
			if $Timer.is_stopped():
				print("timer stopped")
				for ennemy in ennemies:
					if ennemy.has_method("is_base"):
						print(ennemy.is_base())
					if ennemy == self or ennemy.has_method("get_side"):
						if ennemy.get_side() == self.get_side():
							continue
					if ennemy.has_method("set_health"):
						print("set_health")
						var ennemy_pos = ennemy.global_position
						$Marker2D.look_at(ennemy_pos)
						var arrow_instance = arrow.instantiate()
						if self.get_side() == true:
							arrow_instance.change_sprite("res://unit/unit_enfer/Fire_0_Preview.png", 4, 7, 12)
							arrow_instance.set_target(false)
						else:
							arrow_instance.change_sprite("res://unit/unit_paradis/Pure.png", 5, 5, 16)
							arrow_instance.set_target(true)
						arrow_instance.rotation = $Marker2D.rotation
						arrow_instance.global_position = $Marker2D.global_position
						add_child(arrow_instance)
				$Timer.start()

func set_speed(new_value):
	speed = new_value

func set_health(value):
	health = value
	
	if health == 0:
		set_selected(false)
		queue_free()

func set_attack_speed(value):
	attack_speed = value

func get_side():
	return enfer

func get_health():
	return health
