class_name UnitItemEffectComponent
extends Node

## Component gérant les effets d'items sur une unité.
##
## Responsabilités :
## - Stocker les modificateurs actifs
## - Gérer les charges spéciales (Michaël, Cupidon)
## - Appliquer/retirer des buffs/debuffs
##
## @tutorial: Utilisé par ItemEffectManager pour appliquer les effets

## Émis quand un effet est appliqué.
## @param effect_name: Nom de l'effet
signal effect_applied(effect_name: String)

## Émis quand un effet expire.
## @param effect_name: Nom de l'effet
signal effect_expired(effect_name: String)

## Multiplicateur de dégâts (1.0 = normal, 0.5 = -50%, 2.0 = +100%).
var damage_multiplier: float = 1.0

## Multiplicateur de vitesse (1.0 = normal, 0.5 = -50%, 2.0 = +100%).
var speed_multiplier: float = 1.0

## Modification du cooldown d'attaque (en secondes, peut être négatif).
var attack_cooldown_modifier: float = 0.0

## Charges de Glaive de Michaël restantes.
var michael_charges: int = 0

## Charges de Flèche de Cupidon restantes.
var cupidon_arrows: int = 0

## Liste des effets actifs (pour tracking).
var active_effects: Array[String] = []

## Références aux components liés.
var _combat_component: UnitCombatComponent = null
var _movement_component: UnitMovementComponent = null


func _ready() -> void:
	var parent: Node = get_parent()
	
	# Récupère les components frères
	for child in parent.get_children():
		if child is UnitCombatComponent:
			_combat_component = child
		elif child is UnitMovementComponent:
			_movement_component = child


## Applique un modificateur de dégâts.
##
## @param multiplier: Nouveau multiplicateur (cumulatif si plusieurs effets)
## @param effect_name: Nom de l'effet pour tracking
func apply_damage_modifier(multiplier: float, effect_name: String = "") -> void:
	damage_multiplier *= multiplier
	
	if _combat_component:
		_combat_component.damage_multiplier = damage_multiplier
	
	if effect_name:
		active_effects.append(effect_name)
		effect_applied.emit(effect_name)


## Applique un modificateur de vitesse.
##
## @param multiplier: Nouveau multiplicateur (cumulatif si plusieurs effets)
## @param effect_name: Nom de l'effet pour tracking
func apply_speed_modifier(multiplier: float, effect_name: String = "") -> void:
	speed_multiplier *= multiplier
	
	if _movement_component:
		_movement_component.speed_multiplier = speed_multiplier
	
	if effect_name:
		active_effects.append(effect_name)
		effect_applied.emit(effect_name)


## Applique un modificateur de cooldown.
##
## @param modifier: Valeur à ajouter au cooldown (peut être négative)
## @param effect_name: Nom de l'effet pour tracking
func apply_cooldown_modifier(modifier: float, effect_name: String = "") -> void:
	attack_cooldown_modifier += modifier
	
	if _combat_component:
		_combat_component.cooldown_modifier = attack_cooldown_modifier
	
	if effect_name:
		active_effects.append(effect_name)
		effect_applied.emit(effect_name)


## Ajoute des charges de Glaive de Michaël.
##
## @param charges: Nombre de charges à ajouter
func add_michael_charges(charges: int) -> void:
	michael_charges += charges
	
	if _combat_component:
		_combat_component.michael_charges = michael_charges


## Ajoute des charges de Flèche de Cupidon.
##
## @param charges: Nombre de charges à ajouter
func add_cupidon_arrows(charges: int) -> void:
	cupidon_arrows += charges
	
	if _combat_component:
		_combat_component.cupidon_arrows = cupidon_arrows


## Retire un effet par son nom.
##
## @param effect_name: Nom de l'effet à retirer
func remove_effect(effect_name: String) -> void:
	if effect_name in active_effects:
		active_effects.erase(effect_name)
		effect_expired.emit(effect_name)


## Réinitialise tous les modificateurs à leurs valeurs par défaut.
func reset_all_modifiers() -> void:
	damage_multiplier = 1.0
	speed_multiplier = 1.0
	attack_cooldown_modifier = 0.0
	
	if _combat_component:
		_combat_component.damage_multiplier = 1.0
		_combat_component.cooldown_modifier = 0.0
	
	if _movement_component:
		_movement_component.speed_multiplier = 1.0
	
	active_effects.clear()


## Retourne si un effet est actuellement actif.
##
## @param effect_name: Nom de l'effet à vérifier
## @return: true si actif
func has_active_effect(effect_name: String) -> bool:
	return effect_name in active_effects


## Retourne le nombre d'effets actifs.
##
## @return: Nombre d'effets
func get_active_effect_count() -> int:
	return active_effects.size()
