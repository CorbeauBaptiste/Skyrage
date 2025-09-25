extends Base

func _ready():
	enemy_group = "enfer_units"  # Ennemis: Enfer
	sprite.texture = load("res://assets/b_paradis.png")
	unit_types = {
		#"S": {"cost": 5, "charge": 1, "damage": 150, "scene": preload("res://scenes/units/Archange.tscn")},
		#"M": {"cost": 10, "charge": 2.5, "damage": 300, "scene": preload("res://scenes/units/Cherubins.tscn")},
		#"L": {"cost": 15, "charge": 5, "damage": 600, "scene": preload("res://scenes/units/Seraphins.tscn")}
	}
	super._ready()  # Appel parent
	print("Paradis activé")

# VFX spécifique (page 9: étoiles pour attaques)
func take_damage(damage_amount: int):
	super.take_damage(damage_amount)
