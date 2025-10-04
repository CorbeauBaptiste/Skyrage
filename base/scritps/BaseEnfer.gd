extends Base
class_name BaseEnfer

func _ready() -> void:
	team = "enfer"
	super._ready() 
	$Sprite2D.modulate = Color.RED
	print("BaseEnfer team: ", team)
