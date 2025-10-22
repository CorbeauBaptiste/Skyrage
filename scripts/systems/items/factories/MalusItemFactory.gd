class_name MalusItemFactory
extends RefCounted

## Factory pour créer les items malus avec le système Target.


static func create_pomme_adam() -> Item:
	var item := Item.new(
		Item.ItemType.MALUS,
		60.0,
		"La pomme d'adam",
		"Ralentit les unités du camp (-50% vitesse pendant 4 secondes)",
		Item.EffectType.DURATION,
		4,  # 4 secondes
		Target.all_allies()  # Cible tous les alliés
	)
	item.speed_multiplier = 0.5
	return item


static func create_rage_fourbe() -> Item:
	var item := Item.new(
		Item.ItemType.MALUS,
		40.0,
		"La rage fourbe",
		"Diminution des dégâts de l'équipe de 10%",
		Item.EffectType.DURATION,
		5,  # 5 secondes
		Target.all_allies()  # Cible tous les alliés
	)
	item.damage_multiplier = 0.9
	return item


static func create_fourberie_scapin() -> Item:
	var item := Item.new(
		Item.ItemType.MALUS,
		10.0,
		"La fourberie de scapin",
		"Votre base perd 100 PV",
		Item.EffectType.IMMEDIATE,
		1,
		Target.ally_base()  # Cible la base alliée
	)
	item.damage_value = 100
	return item


static func create_intervention_chronos() -> Item:
	var item := Item.new(
		Item.ItemType.MALUS,
		30.0,
		"L'intervention de Chronos",
		"Augmentation du cooldown de +1 seconde pendant 6 secondes",
		Item.EffectType.DURATION,
		6,  # 6 secondes
		Target.all_allies()  # Cible tous les alliés
	)
	item.cooldown_modifier = 1.0
	return item


static func create_revolte_sombre() -> Item:
	var item := Item.new(
		Item.ItemType.MALUS,
		5.0,
		"La révolte sombre",
		"L'unité concernée fait 0 dégâts pendant 4 secondes",
		Item.EffectType.DURATION,
		4,  # 4 secondes
		Target.self_target()  # Cible soi-même uniquement
	)
	item.damage_multiplier = 0.0
	return item
