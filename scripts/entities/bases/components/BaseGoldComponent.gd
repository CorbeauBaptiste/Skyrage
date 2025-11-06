class_name BaseGoldComponent
extends Node

## Component gérant l'or d'une base (wrapper pour GoldManager).
##
## Responsabilités :
## - Interface simplifiée vers GoldManager
## - Configuration initiale
## - Synchronisation avec le Player
##
## @tutorial: Utilisé par Base pour gérer l'économie

## Émis quand l'or change.
## @param current: Or actuel
## @param max_gold: Or maximum
signal gold_changed(current: float, max_gold: float)

## Émis quand de l'or est dépensé.
## @param cost: Coût dépensé
signal gold_spent(cost: float)

## Émis quand pas assez d'or.
## @param cost: Coût requis
signal gold_not_enough(cost: float)

## Or maximum.
@export var max_gold: float = 50.0

## Régénération par seconde.
@export var regen_per_sec: float = 10.0

## Si utilise courbe overtime (x2 après 4 min).
@export var use_overtime_curve: bool = true

## Référence au GoldManager (créé dynamiquement).
var gold_manager: Node = null


func _ready() -> void:
	_create_gold_manager()


## Crée et configure le GoldManager.
func _create_gold_manager() -> void:
	var gm_script = load("res://scripts/managers/GoldManager.gd")
	
	if not gm_script:
		push_error("BaseGoldComponent: Cannot load GoldManager.gd")
		return
	
	var gm_node := Node.new()
	gm_node.name = "GoldManager"
	gm_node.set_script(gm_script)
	
	add_child(gm_node)
	gold_manager = gm_node
	
	# Configuration
	gold_manager.max_gold = max_gold
	gold_manager.regen_per_sec = regen_per_sec
	gold_manager.use_overtime_curve = use_overtime_curve
	gold_manager.set_process(true)
	
	# Connexion signaux
	gold_manager.gold_changed.connect(_on_gold_changed)
	gold_manager.gold_spent.connect(_on_gold_spent)
	gold_manager.gold_not_enough.connect(_on_gold_not_enough)


## Vérifie si peut dépenser un montant.
##
## @param cost: Coût à vérifier
## @return: true si assez d'or
func can_spend(cost: float) -> bool:
	if not gold_manager:
		return false
	return gold_manager.can_spend(cost)


## Dépense de l'or.
##
## @param cost: Montant à dépenser
## @return: true si dépensé avec succès
func spend(cost: float) -> bool:
	if not gold_manager:
		return false
	return gold_manager.spend(cost)


## Remplit l'or au maximum.
func fill_full() -> void:
	if gold_manager:
		gold_manager.fill_full()


## Réinitialise pour un nouveau match.
func reset_match() -> void:
	if gold_manager:
		gold_manager.reset_match()


## Retourne l'or actuel.
##
## @return: Montant d'or
func get_current_gold() -> float:
	if gold_manager:
		return gold_manager.current_gold
	return 0.0


## Callbacks des signaux du GoldManager.
func _on_gold_changed(current: float, max_value: float) -> void:
	gold_changed.emit(current, max_value)


func _on_gold_spent(cost: float) -> void:
	gold_spent.emit(cost)


func _on_gold_not_enough(cost: float) -> void:
	gold_not_enough.emit(cost)
