extends Base
class_name BaseParadis

func _ready() -> void:
	team = "paradis"
	super._ready()
	
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color.WHITE
	
	print("BaseParadis initialisée (team: %s)" % team)
