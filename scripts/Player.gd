class_name Player
extends Node

enum Faction {PARADIS, ENFER}

var faction: Faction
var player_name: String

# Référence vers la base de ce joueur
var base: Base

# Timer pour la génération d'or
var gold_timer: Timer

func _init(player_faction: Faction, name: String = ""):
	faction = player_faction

func _ready():
	setup_units_group()

func get_faction_name() -> String:
	match faction:
		Faction.PARADIS:
			return "Paradis"
		Faction.ENFER:
			return "Enfer"
	return "Inconnu"

func setup_units_group():
	var group_name = get_units_group_name()

func get_units_group_name() -> String:
	"""Retourne le nom du groupe pour les unités de ce joueur"""
	match faction:
		Faction.PARADIS:
			return "units_paradis"
		Faction.ENFER:
			return "units_enfer"
	return "units"

func set_base(player_base: Base):
	"""Associe une base à ce joueur"""
	base = player_base
	if base:
		base.owner_player = self

func get_all_units() -> Array[Unit]:
	"""Retourne toutes les unités de ce joueur"""
	var units: Array[Unit] = []
	var group_name = get_units_group_name()
	
	for node in get_tree().get_nodes_in_group(group_name):
		if node is Unit:
			units.append(node)
	
	return units

func get_enemy_faction() -> Faction:
	"""Retourne la faction ennemie"""
	match faction:
		Faction.PARADIS:
			return Faction.ENFER
		Faction.ENFER:
			return Faction.PARADIS
	return faction

func apply_item_effect(item: Item, collector_unit: Unit):
	""" Applique l'effet d'un item selon sa cible """
	if not item.target:
		return
	
	var affected_entities = get_affected_entities(item.target, collector_unit)
	
	for entity in affected_entities:
		if entity is Unit:
			apply_effect_to_unit(item, entity)
		elif entity is Base:
			apply_effect_to_base(item)

func get_affected_entities(target: Target, collector: Unit) -> Array:
	""" Retourne les entités affectées selon le Target """
	match target.scope:
		Target.TargetScope.SELF:
			return [collector]
		Target.TargetScope.ALL_ALLIES:
			return get_all_units()
		Target.TargetScope.RANDOM_ALLIES:
			return get_random_units(target.random_count)
		Target.TargetScope.BASE_ALLY:
			return [base] if base else []
		Target.TargetScope.ALL_ENEMIES:
			return get_enemy_player().get_all_units()
		Target.TargetScope.BASE_ENEMY:
			return [get_enemy_player().base] if get_enemy_player().base else []
	
	return []
func apply_effect_to_unit(item: Item, unit: Unit):
	"""Applique l'effet d'un item à une unité spécifique"""
	# TODO
	print("Effet ", item.name, " appliqué à l'unité ", unit.name)

func apply_effect_to_base(item: Item, target_base: Base):
	# TODO
	print("Effet ", item.name, " appliqué à la base")
