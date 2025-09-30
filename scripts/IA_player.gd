
class_name IA_player
extends Joueur

func _init(p_id: int):
	super(p_id, "IA_Temp")
	nom = ["Ordinateur", "Bot", "Skynet", "CPU"][randi() % 4] 
