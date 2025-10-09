class_name MalusItemFactory
extends RefCounted

static func create_pomme_adam() -> Item:
	var item = Item.new(
		Item.ItemType.MALUS,
		60.0, 
		"La pomme d'adam",
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
		"La rage fourbe",
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
		"La fourberie de scapin",
		"Votre tour perd 100 PV",
		Item.EffectType.IMMEDIATE,
		1, # one time
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
		"La révolte sombre",
		"Les attaques des unités concernées font 0 dégâts",
		Item.EffectType.DURATION,
		4, # secondes
		Item.Target.SINGLE
	)
	item.damage_multiplier = 0.0
	return item
