extends Node2D

var dragging = false
var drag_start = Vector2.ZERO
var select_rect = RectangleShape2D.new()
var selected = []

# Systèmes d'items
var item_spawn_system: ItemSpawnSystem
var item_ui_system: ItemUISystem

# Pour le champ de sélection
var selection_overlay: Control

@onready var base_enfer: Base = $BaseEnfer
@onready var base_paradis: Base = $BaseParadis
@onready var match_timer: Timer = $MatchTimer

func _ready() -> void:
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 101
	add_child(canvas_layer)
	
	selection_overlay = Control.new()
	selection_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	selection_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas_layer.add_child(selection_overlay)
	selection_overlay.draw.connect(_draw_selection)
	
	# Setup systèmes de jeu
	if match_timer:
		match_timer.wait_time = 300.0 
		match_timer.timeout.connect(_on_match_end)
		match_timer.start()
	
	if base_enfer:
		base_enfer.base_destroyed.connect(_on_victory)
	if base_paradis:
		base_paradis.base_destroyed.connect(_on_victory)
	
	# Attends que les bases soient prêtes
	await get_tree().process_frame
	
	if base_enfer and base_enfer.player:
		base_enfer.player.afficher_infos()
	if base_paradis and base_paradis.player:
		base_paradis.player.afficher_infos()
	
	# Labels d'or
	var label_or_enfer = Label.new()
	label_or_enfer.position = Vector2(10, 10)
	label_or_enfer.text = "Enfer Or: 0"
	canvas_layer.add_child(label_or_enfer)
	if base_enfer and base_enfer.gold_manager:
		base_enfer.gold_manager.gold_changed.connect(func(c, m): label_or_enfer.text = "Enfer Or: " + str(int(c)))

	var label_or_paradis = Label.new()
	label_or_paradis.position = Vector2(10, 50)
	label_or_paradis.text = "Paradis Or: 0"
	canvas_layer.add_child(label_or_paradis)
	if base_paradis and base_paradis.gold_manager:
		base_paradis.gold_manager.gold_changed.connect(func(c, m): label_or_paradis.text = "Paradis Or: " + str(int(c)))
	
	var label_help_paradis = Label.new()
	label_help_paradis.position = Vector2(10, 80)
	label_help_paradis.text = "cliquer backspace pour spawn unite paradis"
	canvas_layer.add_child(label_help_paradis)
	
	var label_help_enfer = Label.new()
	label_help_enfer.position = Vector2(10, 100)
	label_help_enfer.text = "cliquer espace pour spawn unite enfer"
	canvas_layer.add_child(label_help_enfer)
	
	# Setup systèmes d'items
	_setup_item_systems()

func _setup_item_systems():
	# Système de spawn d'items
	item_spawn_system = ItemSpawnSystem.new()
	add_child(item_spawn_system)
	
	if has_node("TileMap/Sol") and has_node("TileMap/Decoration"):
		var texture = load("res://assets/sprite/items/light_item.png")
		item_spawn_system.setup($TileMap/Sol, $TileMap/Decoration, texture)
		item_spawn_system.item_collected.connect(_on_item_collected)
	
	# Système UI pour les items
	item_ui_system = ItemUISystem.new()
	add_child(item_ui_system)

func _physics_process(delta):
	# Nettoie les sélections invalides
	selected = selected.filter(func(item): 
		return is_instance_valid(item.collider)
	)
	
	if item_spawn_system:
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
				drag_start = get_viewport().get_mouse_position()
			else:
				for item in selected:
					var collider = item.collider
					if is_instance_valid(collider) and collider is Unit:
						collider.target = get_global_mouse_position()
						collider.selected = false
				selected = []
		elif dragging:
			dragging = false
			selection_overlay.queue_redraw()
			var drag_end = get_viewport().get_mouse_position()
			var drag_start_world = drag_start
			var drag_end_world = drag_end
			
			select_rect.extents = abs(drag_end_world - drag_start_world)/2
			var space = get_world_2d().direct_space_state
			var q = PhysicsShapeQueryParameters2D.new()
			q.shape = select_rect
			q.collision_mask = 2 
			q.transform = Transform2D(0, (drag_end_world + drag_start_world) / 2)
			var raw_selection = space.intersect_shape(q)
			selected = []
			for item in raw_selection:
				var collider = item.collider
				if is_instance_valid(collider) and collider is Unit:
					collider.selected = true
					selected.append(item)
	
	if event is InputEventMouseMotion and dragging:
		selection_overlay.queue_redraw()
	
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE: 
				print("Spawn déclenché : Espace – Enfer")
				if base_enfer:
					var unit = base_enfer.spawn_unit(preload("res://unit/unit_enfer/ange_dechu/ange_dechu.tscn"), 11)
					if unit:
						print("DEBUG SPAWN ENFER : unit.enfer = ", unit.enfer)
			KEY_BACKSPACE:
				print("Spawn déclenché : Backspace – Paradis")
				if base_paradis:
					var unit = base_paradis.spawn_unit(preload("res://unit/unit_paradis/ange/ange.tscn"), 5)
					if unit:
						print("DEBUG SPAWN PARADIS : unit.enfer = ", unit.enfer)

func _draw_selection():
	if dragging:
		var current_pos = get_viewport().get_mouse_position()
		var rect = Rect2(drag_start, current_pos - drag_start)
		selection_overlay.draw_rect(rect, Color.AQUA, false, 2.0)

func _on_victory(winner: String) -> void:
	print(winner.capitalize() + " gagne ! (Base détruite)")
	if match_timer:
		match_timer.stop()

func _on_match_end() -> void:
	var pv_enfer = base_enfer.current_health if base_enfer else 0
	var pv_paradis = base_paradis.current_health if base_paradis else 0
	var winner = "enfer" if pv_enfer > pv_paradis else "paradis"
	print(winner.capitalize() + " gagne par PV restants ! (Enfer: ", pv_enfer, ", Paradis: ", pv_paradis, ")")
