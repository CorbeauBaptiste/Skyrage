class_name ItemEffectManager
extends Node


signal effect_applied(item_name: String, team: bool)
signal effect_expired(item_name: String, team: bool)

var world_ref: Node

func _init() -> void:
	name = "ItemEffectManager"

func setup(world: Node) -> void:
	"""Configure la référence au monde"""
	world_ref = world
	print("ItemEffectManager setup complete")

func apply_item_effect(item: Item, collector_unit: Unit, world: Node) -> void:
	"""
	Point d'entrée principal pour appliquer un effet d'item
	Args:
		item: L'item collecté
		collector_unit: L'unité qui a ramassé l'item
		world: Référence au monde pour accéder aux autres nodes
	"""
	if not item or not collector_unit:
		push_error("ItemEffectManager: Item ou unité null")
		return
	
	world_ref = world
	var team: bool = collector_unit.get_side() # true = enfer, false = paradis
	
	print("=== APPLICATION EFFET ITEM ===")
	print("Item: ", item.name)
	print("Type: ", "BONUS" if item.type == Item.ItemType.BONUS else "MALUS")
	print("Camp collecteur: ", "Enfer" if team else "Paradis")
	print("Effect Type: ", _get_effect_type_name(item.effect_type))
	print("Duration: ", item.duration)
	
	match item.name:
		# BONUS
		"Le glaive de michaël":
			_apply_glaive_michael(collector_unit)
		"La bénédiction de Ploutos":
			_apply_benediction_ploutos(team, world)
		"La flèche de cupidon":
			_apply_fleche_cupidon(collector_unit)
		"Le remède divin":
			_apply_remede_divin(team, world)
		"La rage d'ares":
			_apply_rage_ares(team, world, item.duration)
		
		# MALUS
		"La pomme d'adam":
			_apply_pomme_adam(team, world, item.duration)
		"La rage fourbe":
			_apply_rage_fourbe(team, world, item.duration)
		"La fourberie de scapin":
			_apply_fourberie_scapin(team, world)
		"L'intervention de Chronos":
			_apply_intervention_chronos(team, world, item.duration)
		"La révolte sombre":
			_apply_revolte_sombre(collector_unit, item.duration)
		
		_:
			push_warning("Effet non implémenté pour: ", item.name)
	
	effect_applied.emit(item.name, team)
	print("================================\n")


func _get_base_for_team(team: bool, world: Node) -> Base:
	"""
	Trouve la base pour un camp donné
	Args:
		team: true pour Enfer, false pour Paradis
		world: Node monde
	Returns: Base correspondante ou null
	"""
	for base in world.get_tree().get_nodes_in_group("bases"):
		if base is Base and base.get_side() == team:
			return base
	push_error("Base non trouvée pour camp: ", "Enfer" if team else "Paradis")
	return null

func _get_units_for_team(team: bool, world: Node) -> Array:
	"""
	Trouve toutes les unités d'un camp
	Args:
		team: true pour Enfer, false pour Paradis
		world: Node monde
	Returns: Array des unités du camp
	"""
	var units: Array = []
	for unit in world.get_tree().get_nodes_in_group("units"):
		if unit is Unit and unit.get_side() == team:
			units.append(unit)
	return units

func _get_effect_type_name(effect_type: Item.EffectType) -> String:
	"""Helper pour debug"""
	match effect_type:
		Item.EffectType.IMMEDIATE: return "IMMEDIATE"
		Item.EffectType.DURATION: return "DURATION"
		Item.EffectType.COUNT: return "COUNT"
		_: return "UNKNOWN"


func _apply_glaive_michael(collector_unit: Unit) -> void:
	"""
	Le glaive de michaël (5% drop)
	Dégât de zone : one shot les S, 3/4 les M, midlife les L
	2 utilisations
	"""


func _apply_benediction_ploutos(team: bool, world: Node) -> void:
	"""
	La bénédiction de Ploutos (40% drop)
	Multiplie l'or actuel par 1.5
	Effet immédiat
	"""


func _apply_fleche_cupidon(collector_unit: Unit) -> void:
	"""
	La flèche de cupidon (15% drop)
	3 flèches avec dégâts de zone (-35 PV)
	"""


func _apply_remede_divin(team: bool, world: Node) -> void:
	"""
	Le remède divin (50% drop)
	Soigne 200 PV au total sur les unités alliées
	Effet immédiat
	"""

func _apply_rage_ares(team: bool, world: Node, duration: int) -> void:
	"""
	La rage d'ares (10% drop)
	Réduit le temps d'attaque de moitié
	Durée: 5 secondes
	"""


func _apply_pomme_adam(team: bool, world: Node, duration: int) -> void:
	"""
	La pomme d'adam (60% drop)
	Ralentit les unités de 50%
	Durée: 4 secondes
	"""

func _apply_rage_fourbe(team: bool, world: Node, duration: int) -> void:
	"""
	La rage fourbe (40% drop)
	Réduit les dégâts de 10%
	Durée: 5 secondes
	"""

func _apply_fourberie_scapin(team: bool, world: Node) -> void:
	"""
	La fourberie de scapin (10% drop)
	La base perd 100 PV
	Effet immédiat
	"""

func _apply_intervention_chronos(team: bool, world: Node, duration: int) -> void:
	"""
	L'intervention de Chronos (30% drop)
	Augmente le cooldown d'attaque de 1 seconde
	Durée: 6 secondes
	"""

func _apply_revolte_sombre(collector_unit: Unit, duration: int) -> void:
	"""
	La révolte sombre (5% drop)
	Les attaques font 0 dégâts
	Durée: 4 secondes
	Target: SINGLE (unité qui ramasse)
	"""
