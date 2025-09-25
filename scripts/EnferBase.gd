# res://scripts/EnferBase.gd
extends Base

func _ready():
	enemy_group = "paradis_units"  # Ennemis: Paradis
	sprite.texture = load("res://assets/b_enfer.png")
	unit_types = {
		#"S": {"cost": 6, "charge": 1, "damage": 150, "scene": preload("res://scenes/units/Diablotin.tscn")},
		#"M": {"cost": 11, "charge": 2, "damage": 250, "scene": preload("res://scenes/units/AngeDechu.tscn")},
		#"L": {"cost": 16, "charge": 4, "damage": 500, "scene": preload("res://scenes/units/Demon.tscn")}
	}
	super._ready()
	print("Enfer activé")

func take_damage(damage_amount: int):
	super.take_damage(damage_amount)
