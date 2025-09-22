extends Node2D

var dragging = false
var drag_start = Vector2.ZERO
var select_rect = RectangleShape2D.new()
var selected = []

var item_manager: ItemManager
var spawned_items: Dictionary = {}
var item_spawn_timer: Timer
var item_texture: Texture2D

func _ready():
	setup_item_system()

func _physics_process(delta):
	check_item_collection()

func setup_item_system():
	item_manager = ItemManager.new()
	item_texture = load("res://assets/sprite/items/light_item.png")
	
	item_spawn_timer = Timer.new()
	item_spawn_timer.wait_time = 5.0
	item_spawn_timer.timeout.connect(spawn_random_item)
	item_spawn_timer.autostart = true
	add_child(item_spawn_timer)

func check_item_collection():
	var units = get_tree().get_nodes_in_group("units")
	
	for unit in units:
		if unit == null:
			continue
			
		for item_pos in spawned_items.keys():
			if unit.global_position.distance_to(item_pos) < 25:
				collect_item_at_position(item_pos)
				return

func collect_item_at_position(item_pos: Vector2):
	if not spawned_items.has(item_pos):
		return
	
	var item = spawned_items[item_pos]
	spawned_items.erase(item_pos)
	
	# Supprime le sprite
	for child in get_children():
		if child.has_meta("spawn_position") and child.get_meta("spawn_position") == item_pos:
			child.queue_free()
			break
	
	show_item_collected_info(item, item_pos)

func spawn_random_item():
	var item = item_manager.get_random_item()
	if not item:
		return
	
	var spawn_position = get_random_spawn_position()
	spawn_item_at_position(item, spawn_position)

func get_random_spawn_position() -> Vector2:
	var viewport_size = get_viewport_rect().size
	var margin = 50
	
	for i in range(100):
		var pos = Vector2(
			randf_range(margin, viewport_size.x - margin),
			randf_range(margin, viewport_size.y - margin)
		)
		
		# Vérifier la distance minimale avec les autres items
		var valid = true
		for existing_pos in spawned_items.keys():
			if pos.distance_to(existing_pos) < 80:
				valid = false
				break
		
		if valid:
			return pos
	
	# Position aléatoire si aucune trouvée
	return Vector2(
		randf_range(margin, viewport_size.x - margin),
		randf_range(margin, viewport_size.y - margin)
	)

func spawn_item_at_position(item: Item, position: Vector2):
	spawned_items[position] = item
	
	var sprite = Sprite2D.new()
	sprite.texture = item_texture
	sprite.position = position
	sprite.scale = Vector2(0.15, 0.15)
	sprite.set_meta("item", item)
	sprite.set_meta("spawn_position", position)
	
	# Animation d'apparition
	sprite.modulate.a = 0.0
	add_child(sprite)
	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 1.0, 0.5)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if selected.size() == 0:
				dragging = true
				drag_start = event.position
			else:
				for item in selected:
					item.collider.target = event.position
					item.collider.selected = false
				selected = []
		elif dragging:
			dragging = false
			queue_redraw()
			var drag_end = event.position
			select_rect.extents = abs(drag_end - drag_start)/2
			var space = get_world_2d().direct_space_state
			var q = PhysicsShapeQueryParameters2D.new()
			q.shape = select_rect
			q.collision_mask = 2
			q.transform = Transform2D(0, (drag_end + drag_start) / 2)
			selected = space.intersect_shape(q)
			for item in selected:
				item.collider.selected = true
	
	if event is InputEventMouseMotion and dragging:
		queue_redraw()
	
	if event.is_action_pressed("ui_accept"):
		spawn_random_item()

func show_item_collected_info(item: Item, position: Vector2):
	var label = Label.new()
	label.text = item.name + " collecté!"
	label.modulate = Color.YELLOW if item.type == Item.ItemType.BONUS else Color.RED
	add_child(label)
	
	# Calculer la taille du label pour le positionnement
	await get_tree().process_frame
	var label_size = label.get_theme_default_font().get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_default_font_size())
	
	# Position de départ avec contraintes d'écran
	var viewport_size = get_viewport_rect().size
	var start_pos = position + Vector2(-50, -30)
	start_pos.x = clamp(start_pos.x, 0, viewport_size.x - label_size.x)
	start_pos.y = clamp(start_pos.y, 0, viewport_size.y - label_size.y)
	
	# Position finale avec contraintes d'écran
	var end_pos = position + Vector2(-50, -80)
	end_pos.x = clamp(end_pos.x, 0, viewport_size.x - label_size.x)
	end_pos.y = clamp(end_pos.y, 0, viewport_size.y - label_size.y)
	
	label.position = start_pos
	
	var tween = create_tween()
	tween.parallel().tween_property(label, "position", end_pos, 2.0)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 2.0)
	tween.tween_callback(label.queue_free)

func _draw():
	if dragging:
		draw_rect(Rect2(drag_start, get_global_mouse_position() - drag_start), Color.AQUA, false)
