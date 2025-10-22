class_name ItemEffectManager
extends Node

## Gestionnaire des effets d'items.
##
## Orchestre l'application et la gestion des effets d'items.
## Les effets eux-mêmes sont définis dans des fichiers séparés.

# ========================================
# SIGNAUX
# ========================================

## Émis quand un effet est appliqué.
signal effect_applied(item_name: String, team: bool)

## Émis quand un effet expire.
signal effect_expired(item_name: String, team: bool)

# ========================================
# VARIABLES
# ========================================

## Liste des effets actuellement actifs.
var active_effects: Array = []

## Registre mappant les noms d'items aux classes d'effets.
var effect_registry: Dictionary = {}

# ========================================
# INITIALISATION
# ========================================

func _init() -> void:
	name = "ItemEffectManager"
	_register_all_effects()


## Enregistre tous les effets d'items disponibles.
func _register_all_effects() -> void:
	# Charge les scripts d'effets
	var bonus_script: Script = load("res://scripts/managers/item_effects/BonusEffects.gd")
	var malus_script: Script = load("res://scripts/managers/item_effects/MalusEffects.gd")
	
	# Enregistre les effets bonus
	effect_registry["Le glaive de michaël"] = bonus_script.GlaiveMichaelEffect
	effect_registry["La bénédiction de Ploutos"] = bonus_script.BenedictionPloutosEffect
	effect_registry["La flèche de cupidon"] = bonus_script.FlecheCupidonEffect
	effect_registry["Le remède divin"] = bonus_script.RemedeDivinEffect
	effect_registry["La rage d'ares"] = bonus_script.RageAresEffect
	
	# Enregistre les effets malus
	effect_registry["La pomme d'adam"] = malus_script.PommeAdamEffect
	effect_registry["La rage fourbe"] = malus_script.RageFourbeEffect
	effect_registry["La fourberie de scapin"] = malus_script.FourberieScapinEffect
	effect_registry["L'intervention de Chronos"] = malus_script.InterventionChronosEffect
	effect_registry["La révolte sombre"] = malus_script.RevolteSombreEffect
	
	print("✅ %d effets d'items enregistrés" % effect_registry.size())

# ========================================
# APPLICATION DES EFFETS
# ========================================

## Applique un effet d'item à une unité collectrice.
##
## @param item: Item à appliquer
## @param collector_unit: Unité qui a collecté l'item
## @param world: Node racine du monde
func apply_item_effect(item: Item, collector_unit: Unit, world: Node) -> void:
	if not item or not collector_unit:
		push_error("ItemEffectManager: Item ou unité null")
		return
	
	if not effect_registry.has(item.name):
		push_warning("Effet non enregistré: %s" % item.name)
		return
	
	var effect_class: Variant = effect_registry[item.name]
	var effect: ItemEffect = effect_class.new(item)
	
	# Résout les cibles via le système Target
	var targets: Array = item.target.resolve(collector_unit, world)
	
	if targets.is_empty():
		print("⚠️ Aucune cible pour: %s" % item.name)
		return
	
	effect.apply(targets)
	
	# Gère les effets temporaires
	match item.effect_type:
		Item.EffectType.DURATION, Item.EffectType.COUNT:
			active_effects.append(effect)
			effect.effect_expired.connect(_on_effect_expired.bind(effect, item.name, collector_unit.get_side()))
	
	effect_applied.emit(item.name, collector_unit.get_side())
	print("✨ Effet appliqué: %s (type: %s)" % [item.name, Item.ItemType.keys()[item.type]])

# ========================================
# UPDATE
# ========================================

## Met à jour tous les effets actifs chaque frame.
##
## @param delta: Temps écoulé
func _process(delta: float) -> void:
	var to_remove: Array = []
	
	for effect in active_effects:
		if effect.update(delta):
			to_remove.append(effect)
	
	for effect in to_remove:
		active_effects.erase(effect)


## Callback appelé quand un effet expire.
##
## @param effect: Effet qui expire
## @param item_name: Nom de l'item
## @param team: Camp concerné
func _on_effect_expired(effect: ItemEffect, item_name: String, team: bool) -> void:
	effect_expired.emit(item_name, team)
	print("⏰ Effet expiré: %s" % item_name)
