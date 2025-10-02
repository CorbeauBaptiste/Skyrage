extends Base
class_name BaseEnfer

func _ready() -> void:
	super._ready()
	$Sprite2D.modulate = Color.RED
	print("BaseEnfer visuels appliqués")
