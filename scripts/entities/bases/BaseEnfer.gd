extends Base
class_name BaseEnfer

func _ready() -> void:
	team = "enfer"
	super._ready() 
	
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color.RED
	
	print("BaseEnfer initialisée (team: %s)" % team)
