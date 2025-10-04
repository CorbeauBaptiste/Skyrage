class_name ItemUISystem
extends Node

func show_item_collected(item: Item, position: Vector2, parent: Node):
	"""Affiche un label animé quand un item est collecté"""
	var label = Label.new()
	label.text = item.name + " collecté!"
	label.modulate = _get_item_color(item)
	parent.add_child(label)
	
	await parent.get_tree().process_frame
	
	var label_size = label.get_theme_default_font().get_string_size(
		label.text, 
		HORIZONTAL_ALIGNMENT_LEFT, 
		-1, 
		label.get_theme_default_font_size()
	)
	
	var viewport_size = parent.get_viewport_rect().size
	var start_pos = _clamp_position(position + Vector2(-50, -30), label_size, viewport_size)
	var end_pos = _clamp_position(position + Vector2(-50, -80), label_size, viewport_size)
	
	label.position = start_pos
	
	var tween = parent.create_tween()
	tween.parallel().tween_property(label, "position", end_pos, 2.0)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 2.0)
	tween.tween_callback(label.queue_free)

func _get_item_color(item: Item) -> Color:
	match item.type:
		Item.ItemType.BONUS:
			return Color.YELLOW
		Item.ItemType.MALUS:
			return Color.RED
		_:
			return Color.WHITE

func _clamp_position(pos: Vector2, label_size: Vector2, viewport_size: Vector2) -> Vector2:
	return Vector2(
		clamp(pos.x, 0, viewport_size.x - label_size.x),
		clamp(pos.y, 0, viewport_size.y - label_size.y)
	)
