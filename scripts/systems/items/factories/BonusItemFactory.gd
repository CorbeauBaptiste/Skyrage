class_name BonusItemFactory
extends RefCounted

## Factory pour créer les items bonus avec le système Target.

static func create_glaive_michael() -> Item:
	var item := Item.new(
		Item.ItemType.BONUS,
		5.0,
		"Le glaive de michaël",
		"Dégâts de zone (one shot S, 3/4 M, midlife L)",
		Item.EffectType.COUNT,
		2,  # 2 charges
		Target.self_target()  # Cible soi-même
	)
	return item


static func create_benediction_ploutos() -> Item:
	var item := Item.new(
		Item.ItemType.BONUS,
		40.0,
		"La bénédiction de Ploutos",
		"Multiplie l'or par 1.5",
		Item.EffectType.IMMEDIATE,
		1,
		Target.player_target()  # Cible le joueur
	)
	item.gold_multiplier = 1.5
	return item


static func create_fleche_cupidon() -> Item:
	var item := Item.new(
		Item.ItemType.BONUS,
		15.0,
		"La flèche de cupidon",
		"Ajoute 3 flèches AoE (-35 PV chacune)",
		Item.EffectType.COUNT,
		3,  # 3 flèches
		Target.self_target()  # Cible soi-même
	)
	item.damage_value = 35
	return item


static func create_remede_divin() -> Item:
	var item := Item.new(
		Item.ItemType.BONUS,
		50.0,
		"Le remède divin",
		"Soigne 200 PV répartis sur les alliés blessés",
		Item.EffectType.IMMEDIATE,
		1,
		Target.wounded_allies(5)  # Cible jusqu'à 5 alliés blessés
	)
	item.heal_value = 200
	return item


static func create_rage_ares() -> Item:
	var item := Item.new(
		Item.ItemType.BONUS,
		10.0,
		"La rage d'ares",
		"Réduit le cooldown de -0.5s pendant 5 secondes",
		Item.EffectType.DURATION,
		5,  # 5 secondes
		Target.all_allies()  # Cible tous les alliés
	)
	item.cooldown_modifier = -0.5
	return item
