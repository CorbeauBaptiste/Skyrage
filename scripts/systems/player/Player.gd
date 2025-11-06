extends Node
class_name Player

## Représente un joueur du jeu.
##
## Gère les informations de base d'un joueur :
## - Identifiant et nom
## - Camp (enfer/paradis)
## - Référence à sa base

# ========================================
# PROPRIÉTÉS
# ========================================

## Identifiant du joueur.
var id: int

## Nom du joueur.
var nom: String = ""

## Camp du joueur ("enfer" ou "paradis").
var camp: String = ""

## Référence à la base du joueur.
var base: Base

## Or du joueur (synchronisé avec la base).
var _or: int = 0

# ========================================
# INITIALISATION
# ========================================

func _init(p_id: int, p_nom: String, p_camp: String = ""):
	id = p_id
	nom = p_nom
	if p_camp != "":
		camp = p_camp
	else:
		camp = ["enfer", "paradis"][randi() % 2]

# ========================================
# GESTION DU CAMP
# ========================================

## Définit le camp du joueur.
##
## @param p_camp: Camp à assigner ("enfer" ou "paradis")
func set_camp(p_camp: String) -> void:
	camp = p_camp
	print("Joueur %s assigné au camp: %s" % [nom, camp])

# ========================================
# GESTION DE L'OR
# ========================================

## Modifie l'or du joueur et synchronise avec la base.
##
## @param quantite: Montant à ajouter (peut être négatif)
func modifier_or(quantite: int) -> void:
	_or += quantite
	if _or < 0:
		_or = 0
	
	# Synchronisation avec le gold_component de la base
	if base and base.gold_component and base.gold_component.gold_manager:
		base.gold_component.gold_manager.current_gold = float(_or)
		print("Or joueur %s sync avec base %s (%d)" % [nom, camp, _or])


## Retourne l'or actuel du joueur (depuis la base).
##
## @return: Montant d'or actuel
func get_or() -> int:
	if base and base.gold_component and base.gold_component.gold_manager:
		return int(base.gold_component.gold_manager.current_gold)
	return _or

# ========================================
# UTILITAIRES
# ========================================

## Retourne le camp sous forme booléenne.
##
## @return: true si Enfer, false si Paradis
func get_side() -> bool:
	return camp == "enfer"


## Affiche les informations du joueur dans la console.
func afficher_infos() -> void:
	var or_val: int = get_or()
	print("ID: %d, Nom: %s, Camp: %s, Or: %d, Side: %s" % [id, nom, camp, or_val, get_side()])
