extends CharacterBody2D

# Vitesse du personnage
@export var speed: float = 200.0

func _physics_process(delta: float) -> void:
	var direction := Vector2.ZERO
	
	# Récupération des touches
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1
	
	# Normalisation pour garder une vitesse constante en diagonale
	if direction != Vector2.ZERO:
		direction = direction.normalized()
	
	velocity = direction * speed
	move_and_slide()
