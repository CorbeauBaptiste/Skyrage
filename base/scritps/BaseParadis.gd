extends Base
class_name BaseParadis

func _ready() -> void:
	super._ready()
	$Sprite2D.modulate = Color.WHITE 
	print("BaseParadis visuels appliqués")
