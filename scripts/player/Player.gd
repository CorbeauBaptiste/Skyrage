extends Node
class_name Player  

var id: int
var nom: String = ""
var camp: String = ""
var _or: int = 0

func _init(p_id: int, p_nom: String):
	id = p_id
	nom = p_nom
	camp = ["enfer", "paradis"][randi() % 2] 

func modifier_or(quantite: int) -> void:
	_or += quantite
	if _or < 0:
		_or = 0

func afficher_infos() -> void:
	print("ID: ", id, ", Nom: ", nom, ", Camp: ", camp, ", Or: ", _or)
