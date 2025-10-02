extends Base  # Hérite de Base.gd
class_name BaseEnfer

@export var texture_path: String = "res://textures/base_enfer.png"

func _ready() -> void:
	super._ready()  # Exécute Base
	team = "enfer"  # Force team
	$Sprite2D.texture = load(texture_path)
	$Sprite2D.modulate = Color.RED  # Rouge infernal (GDD)
	# Effet visuel : Ajoute GPUParticles2D enfant si tu veux (lave)
	# player.nom = "Joueur Enfer"  # Déjà dans Base

# Override si besoin (ex: sons démoniaques)
