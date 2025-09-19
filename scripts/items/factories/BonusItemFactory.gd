class_name BonusItemFactory
extends RefCounted

static func create_glaive_michael() -> Item:
	var item = Item.new(
		Item.ItemType.BONUS,
		5.0, 
		"le glaive de michaël",
		"dégât de zone (one shot les S, 3/4 les M, midlife les L)",
		Item.EffectType.COUNT,
		2,
		Item.Target.SINGLE
	)
	return item

static func create_benediction_ploutos() -> Item:
	var item = Item.new(
		Item.ItemType.BONUS,
		40.0,  # 40% de drop
		"la bénédiction de Ploutos",
		"sort qui permet de faire x 1.5 de son or",
		Item.EffectType.IMMEDIATE,
		1,  # 1 utilisation
		Item.Target.ALLY
	)
	item.gold_multiplier = 1.5
	return item

static func create_fleche_cupidon() -> Item:
	var item = Item.new(
		Item.ItemType.BONUS,
		15.0,  # 15% de drop
		"la flèche de cupidon",
		"Ajoute une flèche qui fait des dégâts de zone à l'unité (-35 pv)",
		Item.EffectType.COUNT,
		3,  # 3 flèches
		Item.Target.SINGLE
	)
	item.damage_value = 35
	return item

static func create_remede_divin() -> Item:
	var item = Item.new(
		Item.ItemType.BONUS,
		50.0,  # 50% de drop
		"le remède divin",
		"Soigne de 200 pv au total les unités",
		Item.EffectType.IMMEDIATE,
		1,  # 1 utilisation
		Item.Target.ALLY
	)
	item.heal_value = 200
	return item

static func create_rage_ares() -> Item:
	var item = Item.new(
		Item.ItemType.BONUS,
		10.0, 
		"la rage d'ares",
		"boost les unités alliés (temps d'attaque réduit de moitié)",
		Item.EffectType.DURATION,
		5,  # secondes
		Item.Target.ALLY
	)
	item.cooldown_modifier = -0.5  # -50% de cooldown
	return item
