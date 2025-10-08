class_name ItemFactory
extends RefCounted

static func create_item_by_name(item_name: String) -> Item:
	match item_name:
		"glaive_michael":
			return BonusItemFactory.create_glaive_michael()
		"benediction_ploutos":
			return BonusItemFactory.create_benediction_ploutos()
		"fleche_cupidon":
			return BonusItemFactory.create_fleche_cupidon()
		"remede_divin":
			return BonusItemFactory.create_remede_divin()
		"rage_ares":
			return BonusItemFactory.create_rage_ares()
		"pomme_adam":
			return MalusItemFactory.create_pomme_adam()
		"rage_fourbe":
			return MalusItemFactory.create_rage_fourbe()
		"fourberie_scapin":
			return MalusItemFactory.create_fourberie_scapin()
		"intervention_chronos":
			return MalusItemFactory.create_intervention_chronos()
		"revolte_sombre":
			return MalusItemFactory.create_revolte_sombre()
		_:
			push_error("Item inconnu: " + item_name)
			return null
