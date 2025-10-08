extends Base
class_name BaseParadis

func _ready() -> void:
	team = "paradis"
	super._ready()
	$Sprite2D.modulate = Color.WHITE
	print("BaseParadis team: ", team)
