extends Node
class_name Joueur  

var id: int
var nom: String = ""
var camp: String = ""
var base: Base 
var _or: int = 0

func _init(p_id: int, p_nom: String):
	id = p_id
	nom = p_nom
	# Camp random par défaut mais set_camp le fixera
	camp = ["enfer", "paradis"][randi() % 2]

# Nouvelle func : Fixe camp (appele par Base)
func set_camp(p_camp: String) -> void:
	camp = p_camp
	print("Joueur ", nom, " assigné au camp: ", camp)  # Debug

func modifier_or(quantite: int) -> void:
	_or += quantite
	if _or < 0:
		_or = 0
	if base and base.gold_manager:
		base.gold_manager.current_gold = float(_or)
		print("Or sync avec base: ", _or)  # Debug

func get_or() -> int:
	if base and base.gold_manager:
		return int(base.gold_manager.current_gold)
	return _or

func afficher_infos() -> void:
	print("ID: ", id, ", Nom: ", nom, ", Camp: ", camp, ", Or (base): ", get_or())
