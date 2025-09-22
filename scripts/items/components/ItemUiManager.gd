class_name ItemUIManager
extends Node

var screen_size: Vector2
var active_labels: Array[Label] = []
var label_display_time: float = 5.0

func _init(screen: Vector2):
	screen_size = screen

func show_item_info(item: Item, world_pos: Vector2):
	var info_text = build_item_info_text(item)
	create_temporary_label(info_text, world_pos)

func build_item_info_text(item: Item) -> String:
	var info_text = ""
	info_text += "Type: " + ("BONUS" if item.type == Item.ItemType.BONUS else "MALUS") + "\n"
	info_text += "Effet: " + item.effect_description + "\n"
	info_text += "Durée: " + str(item.duration) + "\n"
	
	if item.damage_value > 0:
		info_text += "Dégâts: " + str(item.damage_value) + "\n"
	if item.heal_value > 0:
		info_text += "Soins: " + str(item.heal_value) + "\n"
	if item.gold_multiplier != 1.0:
		info_text += "Multiplicateur d'or: x" + str(item.gold_multiplier) + "\n"
	if item.damage_multiplier != 1.0:
		info_text += "Multiplicateur de dégâts: x" + str(item.damage_multiplier) + "\n"
	if item.speed_multiplier != 1.0:
		info_text += "Multiplicateur de vitesse: x" + str(item.speed_multiplier) + "\n"
	if item.cooldown_modifier != 0.0:
		info_text += "Modification cooldown: " + str(item.cooldown_modifier) + "s\n"
	
	return info_text

func create_temporary_label(text: String, world_pos: Vector2):
	var label = Label.new()
	label.text = text
	label.position = Vector2(world_pos.x - 100, world_pos.y + 20)
	
	get_parent().add_child(label)
	keep_label_in_screen(label)
	active_labels.append(label)
	
	# Timer pour supprimer le label
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = label_display_time
	timer.timeout.connect(func():
		if is_instance_valid(label):
			label.queue_free()
			active_labels.erase(label)
	)
	get_parent().add_child(timer)
	timer.start()

func keep_label_in_screen(label: Label):
	var label_size = label.get_minimum_size()
	var pos = label.position
	
	pos.x = clamp(pos.x, 0, screen_size.x - label_size.x)
	pos.y = clamp(pos.y, 0, screen_size.y - label_size.y)
	
	label.position = pos

func clear_all_labels():
	for label in active_labels:
		if is_instance_valid(label):
			label.queue_free()
	active_labels.clear()
