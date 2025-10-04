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
					var collider = item.collider
					if collider is Unit:  # Fix : Seulement si Unit
						collider.target = event.position
						collider.selected = false
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
				var collider = item.collider
				if collider is Unit:
					collider.selected = true
				else:
					print("Ignore collider non-Unit : ", collider.get_class()) 
	if event is InputEventMouseMotion and dragging:
		queue_redraw()
	
	if event is InputEventKey and event.pressed:
		print("Touche pressée : keycode = ", event.keycode)
		match event.keycode:
			KEY_SPACE: 
				print("Spawn déclenché : Espace – Enfer")
				if base_enfer:
					var unit = base_enfer.spawn_unit(preload("res://unit/unit_enfer/ange_dechu/ange_dechu.tscn"), 11)
					if unit:
						print("DEBUG SPAWN ENFER : unit.enfer = ", unit.enfer, " (doit être true)")
					else:
						print("Spawn Enfer échoué (or <11 ?)")
			KEY_BACKSPACE:
				print("Spawn déclenché : Échap – Paradis")
				if base_paradis:
					var unit = base_paradis.spawn_unit(preload("res://unit/unit_paradis/ange/ange.tscn"), 5)
					if unit:
						print("DEBUG SPAWN PARADIS : unit.enfer = ", unit.enfer, " (doit être false)")
					else:
						print("Spawn Paradis échoué (or <5 ?)")
			_:
				print("Touche non mappée : keycode = ", event.keycode, " (Espace=KEY_SPACE, Échap=KEY_ESCAPE)")
						

func _draw():
	if dragging:
		draw_rect(Rect2(drag_start, get_global_mouse_position() - drag_start), Color.AQUA, false)

func _on_victory(winner: String) -> void:
	print(winner.capitalize() + " gagne ! (Base détruite)")
	if match_timer:
		match_timer.stop()
	# TODO : fin de match 

func _on_match_end() -> void:
	var pv_enfer = base_enfer.current_health if base_enfer else 0
	var pv_paradis = base_paradis.current_health if base_paradis else 0
	var winner = "enfer" if pv_enfer > pv_paradis else "paradis"
	print(winner.capitalize() + " gagne par PV restants ! (Enfer: ", pv_enfer, ", Paradis: ", pv_paradis, ")")
	# TODO : Écran fin
