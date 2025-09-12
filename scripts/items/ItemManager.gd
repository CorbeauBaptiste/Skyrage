class_name ItemManager
extends Resource

var item_bonus: Array[Item] = []
var item_malus: Array[Item] = []

func _init() -> void:
	setup_items()

func setup_items():
	"""
		Créer tous les items
	"""
	# BONUS
	item_bonus.append(ItemFactory.create_glaive_michael())
	item_bonus.append(ItemFactory.create_benediction_ploutos())
	item_bonus.append(ItemFactory.create_fleche_cupidon())
	item_bonus.append(ItemFactory.create_remede_divin())
	item_bonus.append(ItemFactory.create_rage_ares())
	
	# MALUS
	item_malus.append(ItemFactory.create_pomme_adam())
	item_malus.append(ItemFactory.create_rage_fourbe())
	item_malus.append(ItemFactory.create_fourberie_scapin())
	item_malus.append(ItemFactory.create_intervention_chronos())
	item_malus.append(ItemFactory.create_revolte_sombre())

func get_random_item() -> Item:
	"""
		Retourne un item aléatoire de tous les items
	"""
	var all_items = item_bonus + item_malus
	if all_items.is_empty():
		return null
	
	var total: int = 0
	for item in all_items:
		total += item.pct_drop
	
	var rd_value = randf() * total
	var n = 0.0
	
	# Recherche l'item correspondant a la probabilité trouvé aléatoirement
	for item in all_items:
		n += item.pct_drop
		if rd_value <= n:
			return item

	return all_items[-1]	
