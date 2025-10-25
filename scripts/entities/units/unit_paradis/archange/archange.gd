extends Unit

enum Direction { UP, RIGHT, DOWN, LEFT }
var current_direction : Direction = Direction.UP
const SPEED : float = 200.0
var dir = Vector2.ZERO
var rota = 0

var old_position : Vector2 = Vector2.ZERO

var turn_cooldown : float = 0.2
var turn_timer : float = 0.0

var target_movement: Node

func _ready() -> void:
	set_health(4)
	target_movement = get_parent().get_node_or_null("BaseEnfer")

func _physics_process(delta):
	if target_movement:
		velocity = position.direction_to(target_movement.global_position) * speed
		move_and_slide()
		var ennemies = $Range.get_overlapping_bodies()
		if ennemies.size() > 0:
			var valid_enemies = [] 
			for ennemy in ennemies:
				if is_instance_valid(ennemy) and ennemy != self and ennemy.has_method("get_side") and ennemy.get_side() != self.get_side():
					valid_enemies.append(ennemy)
			if valid_enemies:
				velocity = Vector2.ZERO
				shoot()
	else:
		turn_timer -= delta
		if turn_timer < 0:
			turn_timer = 0
		
		if turn_timer == 0:
			var droite_bodies = $Droite.get_overlapping_bodies()
			if not droite_bodies:
				current_direction = (current_direction + 1) % 4
				turn_timer = turn_cooldown 
		
		update_droite_rotation(current_direction)
		dir = match_current_direction(current_direction)
		
		old_position = global_position
		
		velocity = dir * SPEED
		move_and_slide()
		
		var actual_speed = (global_position - old_position).length() / delta
		
		if actual_speed < 1:
			current_direction = (current_direction + 3) % 4

func match_current_direction(direction):
	match current_direction:
		Direction.UP:
			dir = Vector2(0, -1)
		Direction.RIGHT:
			dir = Vector2(1, 0)
		Direction.DOWN:
			dir = Vector2(0, 1)
		Direction.LEFT:
			dir = Vector2(-1, 0)
	
	return dir

func update_droite_rotation(direction: int):
	# Chaque direction correspond à un angle en degrés
	match current_direction:
		Direction.UP:
			rota = -90
		Direction.RIGHT:
			rota = 0
		Direction.DOWN:
			rota = 90
		Direction.LEFT:
			rota = 180

	$Droite.rotation_degrees = rota
