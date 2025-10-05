extends Node

func _ready():
	test_item_manager()

func test_item_manager():
	var manager = ItemManager.new()
	var random_item = manager.get_random_item()
	print("random item: ", random_item.name)
	print(random_item.pct_drop)
	
	for item in manager.item_bonus:
		print("Nom: ", item.name)
		print("Type: ", item.type)
		print("Drop rate: ", item.pct_drop, "%")
		print("Effet: ", item.effect_description)
		print("Durée: ", item.duration)
		print("---")
