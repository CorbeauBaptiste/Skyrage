extends Node2D

# Système de sélection d'unités
var dragging = false
var drag_start = Vector2.ZERO
var select_rect = RectangleShape2D.new()
var selected = []

# Systèmes
var item_spawn_system: ItemSpawnSystem
var item_ui_system: ItemUISystem

func _ready():
	_setup_systems()

func _setup_systems():
	# Système de spawn d'items
	item_spawn_system = ItemSpawnSystem.new()
	add_child(item_spawn_system)
	
	var texture = load("res://assets/sprite/items/light_item.png")
	item_spawn_system.setup($TileMap/Sol, $TileMap/Decoration, texture)
	item_spawn_system.item_collected.connect(_on_item_collected)
	
	# Système UI pour les items
	item_ui_system = ItemUISystem.new()
	add_child(item_ui_system)

func _physics_process(delta):
	var units = get_tree().get_nodes_in_group("units")
	item_spawn_system.check_collection(units)

func _on_item_collected(item: Item, position: Vector2):
	"""Callback quand un item est collecté"""
	item_ui_system.show_item_collected(item, position, self)
	# TODO: Appliquer les effets de l'item

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if selected.size() == 0:
				dragging = true
				drag_start = event.position
			else:
				for item in selected:
					if item.collider.has_method("set_selected"):
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
				if item.collider.has_method("set_selected"):
					item.collider.selected = true
	
	if event is InputEventMouseMotion and dragging:
		queue_redraw()

func _draw():
	if dragging:
		draw_rect(Rect2(drag_start, get_global_mouse_position() - drag_start), Color.NAVY_BLUE, false)
