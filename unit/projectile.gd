extends Area2D
class_name Projectile

@export var speed = 100: set = set_speed
@export var damage = 1: set = set_damage

func _ready():
	set_as_top_level(true)

func _process(delta):
	position += (Vector2.RIGHT*speed).rotated(rotation) * delta

func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	queue_free()

func set_speed(value):
	speed = value

func set_damage(value):
	damage = value
