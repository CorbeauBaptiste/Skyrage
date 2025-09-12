class_name ItemFactory
extends RefCounted

# === BONUS ===

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

# === MALUS ===

static func create_pomme_adam() -> Item:
	var item = Item.new(
		Item.ItemType.MALUS,
		60.0, 
		"la pomme d'adam",
		"Ralenti les unitées du camp qui l'obtient",
		Item.EffectType.DURATION,
		4,  # secondes
		Item.Target.ALLY
	)
	item.speed_multiplier = 0.5  # -50% de vitesse
	return item

static func create_rage_fourbe() -> Item:
	var item = Item.new(
		Item.ItemType.MALUS,
		40.0, 
		"la rage fourbe",
		"Diminution des dégâts de l'équipe de 10%",
		Item.EffectType.DURATION,
		5,  # secondes
		Item.Target.ALLY
	)
	item.damage_multiplier = 0.9  # -10% de dégâts
	return item

static func create_fourberie_scapin() -> Item:
	var item = Item.new(
		Item.ItemType.MALUS,
		10.0, 
		"la fourberie de scapin",
		"Votre tour perd 100 PV",
		Item.EffectType.IMMEDIATE,
		1, 
		Item.Target.ALLY
	)
	item.damage_value = 100  # Dégâts à la base
	return item

static func create_intervention_chronos() -> Item:
	var item = Item.new(
		Item.ItemType.MALUS,
		30.0, 
		"L'intervention de Chronos",
		"Augmentation du temps de rechargement de l'équipe de 1 seconde",
		Item.EffectType.DURATION,
		6,  # secondes
		Item.Target.ALLY
	)
	item.cooldown_modifier = 1.0  # +1 seconde de cooldown
	return item

static func create_revolte_sombre() -> Item:
	var item = Item.new(
		Item.ItemType.MALUS,
		5.0, 
		"la révolte sombre",
		"Les attaques des unités concernées font 0 dégâts",
		Item.EffectType.DURATION,
		4, # secondes
		Item.Target.SINGLE
	)
	item.damage_multiplier = 0.0
	return item
