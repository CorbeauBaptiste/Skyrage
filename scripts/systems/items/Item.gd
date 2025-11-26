class_name Item
extends Resource

## Resource représentant un item du jeu.
##
## Refactorisé pour utiliser le système Target au lieu d'un enum simple.
## Plus flexible et réutilisable.

# ========================================
# ÉNUMÉRATIONS
# ========================================

enum ItemType {BONUS, MALUS}
enum EffectType {IMMEDIATE, COUNT, DURATION}

# ========================================
# PROPRIÉTÉS DE BASE
# ========================================

## Type d'item (bonus ou malus).
var type: ItemType

## Chance de drop (0.0 - 100.0).
var pct_drop: float

## Nom de l'item.
var name: String

## Description de l'effet.
var effect_description: String

## Type d'effet (immédiat, compteur, durée).
var effect_type: EffectType

## Durée ou nombre d'utilisations.
var duration: int

## Système de ciblage (nouveau !).
var target: Target

# ========================================
# VALEURS D'EFFET
# ========================================

## Dégâts directs.
var damage_value: int = 0

## Soins.
var heal_value: int = 0

## Multiplicateur d'or.
var gold_multiplier: float = 1.0

## Multiplicateur de dégâts.
var damage_multiplier: float = 1.0

## Multiplicateur de vitesse.
var speed_multiplier: float = 1.0

## Modification du cooldown (en secondes).
var cooldown_modifier: float = 0.0

# ========================================
# CONSTRUCTEUR
# ========================================

func _init(
	item_type: ItemType,
	drop_chance: float,
	item_name: String,
	item_effect_description: String,
	item_effect_type: EffectType,
	item_duration: int,
	item_target: Target
) -> void:
	type = item_type
	pct_drop = drop_chance
	name = item_name
	effect_description = item_effect_description
	effect_type = item_effect_type
	duration = item_duration
	target = item_target
