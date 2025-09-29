extends Node2D
class_name Base

@export var texture = preload("res://base/Sujet 2.png"): set = set_sprite
@export var enfer = true: set = set_enfer
@export var health = 20: set = set_health

func set_sprite(value):
	texture = value

func _physics_process(delta: float) -> void:
	$Sprite2D.texture = texture

func set_enfer(value):
	enfer = value

func set_health(value):
	health = value

func get_side():
	return enfer
