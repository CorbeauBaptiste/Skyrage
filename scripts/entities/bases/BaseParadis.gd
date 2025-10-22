extends Base
class_name BaseParadis

## Base du paradis.
##
## Hérite de Base et définit simplement le camp.
## Toute la logique est gérée par les components de la classe parente.


func _ready() -> void:
	# Définit le camp AVANT d'appeler super._ready()
	team = "paradis"
	
	# Appel du _ready() parent qui configure tout
	super._ready()
	
	# Configuration visuelle spécifique
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color.WHITE
	
	print("🔥 BaseParadis prête (team: %s)" % team)
