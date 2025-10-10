extends Node
class_name Player  

var id: int
var nom: String = ""
var camp: String = "" 
var base: Base  
var _or: int = 0 

func _init(p_id: int, p_nom: String, p_camp: String = ""): 
	id = p_id
	nom = p_nom
	if p_camp != "":
		camp = p_camp
	else:
		camp = ["enfer", "paradis"][randi() % 2] 

func set_camp(p_camp: String) -> void:
	camp = p_camp
	print("Joueur ", nom, " assigné au camp: ", camp)

func modifier_or(quantite: int) -> void:
	_or += quantite
	if _or < 0:
		_or = 0
	if base and base.gold_manager:
		base.gold_manager.current_gold = float(_or)  # sync auto
		print("Or joueur ", nom, " sync avec base ", camp, " (", _or, ")")

func get_or() -> int:
	if base and base.gold_manager:
		return int(base.gold_manager.current_gold)
	return _or

func get_side() -> bool:
	return camp == "enfer"

func afficher_infos() -> void:
	var or_val = get_or()
	print("ID: ", id, ", Nom: ", nom, ", Camp: ", camp, ", Or (base): ", or_val, ", Side unités: ", get_side())
