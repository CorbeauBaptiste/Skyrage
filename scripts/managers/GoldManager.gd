class_name GoldManager
extends Node

## Gestionnaire de l'or pour une base.
##
## Gère la régénération, les dépenses et le système de bonus overtime.
## Utilisé par BaseGoldComponent.

# ========================================
# SIGNAUX
# ========================================

## Émis quand l'or change.
signal gold_changed(current: float, max_value: float)

## Émis quand de l'or est dépensé.
signal gold_spent(cost: float)

## Émis quand pas assez d'or.
signal gold_not_enough(cost: float)

# ========================================
# PROPRIÉTÉS
# ========================================

## Or maximum.
var max_gold: float = Constants.GOLD_CONFIG["max_gold"]

## Or actuel.
var current_gold: float = 0.0

## Régénération par seconde.
var regen_per_sec: float = Constants.GOLD_CONFIG["regen_per_sec"]

## Si utilise la courbe overtime.
var use_overtime_curve: bool = true

## Temps écoulé depuis le début.
var t_elapsed: float = 0.0

## Multiplicateur de régénération actuel.
var regen_mult: float = 1.0

# ========================================
# INITIALISATION
# ========================================

func _ready() -> void:
	set_process(true)

# ========================================
# UPDATE
# ========================================

func _process(delta: float) -> void:
	t_elapsed += delta
	
	# Active le boost overtime
	if use_overtime_curve:
		var threshold: float = Constants.GOLD_CONFIG["overtime_threshold"]
		var multiplier: float = Constants.GOLD_CONFIG["overtime_multiplier"]
		regen_mult = multiplier if t_elapsed >= threshold else 1.0
	
	# Régénération de l'or
	if current_gold < max_gold:
		current_gold = min(max_gold, current_gold + regen_per_sec * regen_mult * delta)
		gold_changed.emit(current_gold, max_gold)

# ========================================
# GESTION DE L'OR
# ========================================

## Vérifie si peut dépenser un montant.
##
## @param cost: Coût à vérifier
## @return: true si assez d'or
func can_spend(cost: float) -> bool:
	return current_gold >= cost


## Dépense de l'or.
##
## @param cost: Montant à dépenser
## @return: true si dépensé avec succès
func spend(cost: float) -> bool:
	if can_spend(cost):
		current_gold -= cost
		gold_changed.emit(current_gold, max_gold)
		gold_spent.emit(cost)
		return true
	gold_not_enough.emit(cost)
	return false


## Remplit l'or au maximum.
func fill_full() -> void:
	current_gold = max_gold
	gold_changed.emit(current_gold, max_gold)


## Réinitialise pour un nouveau match.
func reset_match() -> void:
	t_elapsed = 0.0
	regen_mult = 1.0
	current_gold = 0.0
	gold_changed.emit(current_gold, max_gold)
