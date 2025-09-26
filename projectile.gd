extends Area2D
class_name Projectile

@export var speed = 100: set = set_speed
@export var damage = 1: set = set_damage
@export var targets_enfer = true: set = set_target

func _ready():
	set_as_top_level(true)

func _process(delta):
	position += (Vector2.RIGHT*speed).rotated(rotation) * delta

func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	queue_free()

func change_sprite(sprite_route, hframes, vframes, frame = 0):
	var texture = load(sprite_route)
	$Sprite2D.texture = texture
	$Sprite2D.hframes = hframes
	$Sprite2D.vframes = vframes
	$Sprite2D.frame = frame

func set_speed(value):
	speed = value

func set_damage(value):
	damage = value

func set_target(value):
	targets_enfer = value

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("set_health"):
		if targets_enfer and body.get_side() == true:
			body.set_health(body.get_health() - 1)
			queue_free()
		elif not targets_enfer and not body.get_side():
			body.set_health(body.get_health() - 1)
			queue_free()
