extends Node2D

## Gestionnaire principal du monde de jeu.
##
## Orchestre les différents systèmes (items, combat, sélection, phases).
## Compatible avec la nouvelle architecture à base de components.

# ========================================
# SYSTÈMES
# ========================================

var item_spawn_system: ItemSpawnSystem
var item_effect_manager: ItemEffectManager
var item_ui_system: ItemUISystem

# ========================================
# SÉLECTION
# ========================================

var dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO
var select_rect: RectangleShape2D = RectangleShape2D.new()
var selected: Array = []

# ========================================
# RÉFÉRENCES
# ========================================

@onready var base_enfer: Base = $BaseEnfer
@onready var base_paradis: Base = $BaseParadis
@onready var match_timer: Timer = Timer.new()

var ui_layer: CanvasLayer
var hud_enfer: Control
var hud_paradis: Control

var current_phase_is_enfer: bool = false

# ========================================
# INITIALISATION
# ========================================

func _ready() -> void:
	_setup_match_timer()
	_setup_bases()
	_setup_ui()
	_setup_item_systems()
	
	await get_tree().process_frame
	
	if base_enfer and base_enfer.player:
		base_enfer.player.afficher_infos()
	if base_paradis and base_paradis.player:
		base_paradis.player.afficher_infos()


func _setup_match_timer() -> void:
	add_child(match_timer)
	match_timer.wait_time = Constants.MATCH_DURATION
	match_timer.timeout.connect(_on_match_end)
	match_timer.start()


func _setup_bases() -> void:
	if base_enfer:
		base_enfer.base_destroyed.connect(_on_victory)
	if base_paradis:
		base_paradis.base_destroyed.connect(_on_victory)


func _setup_ui() -> void:
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	
	# HUD Enfer
	hud_enfer = preload("res://scenes/ui/hud/hud_hell.tscn").instantiate()
	ui_layer.add_child(hud_enfer)
	if hud_enfer:
		hud_enfer.btn_diablotin_pressed.connect(func(): _spawn_units("enfer", "diablotin"))
		hud_enfer.btn_ange_dechu_pressed.connect(func(): _spawn_units("enfer", "ange_dechu"))
		hud_enfer.btn_demon_pressed.connect(func(): _spawn_units("enfer", "demon"))
		hud_enfer.phase_changed.connect(func(is_active): 
			if is_active:
				_on_phase_changed(true)
		)
	
	# HUD Paradis
	hud_paradis = preload("res://scenes/ui/hud/hud_paradise.tscn").instantiate()
	ui_layer.add_child(hud_paradis)
	if hud_paradis:
		hud_paradis.btn_archange_pressed.connect(func(): _spawn_units("paradis", "archange"))
		hud_paradis.btn_ange_pressed.connect(func(): _spawn_units("paradis", "ange"))
		hud_paradis.btn_seraphin_pressed.connect(func(): _spawn_units("paradis", "seraphin"))
		hud_paradis.phase_changed.connect(func(is_active): 
			if is_active:
				_on_phase_changed(false)
		)


func _setup_item_systems() -> void:
	print("🔧 Configuration des systèmes d'items...")
	
	item_spawn_system = ItemSpawnSystem.new()
	add_child(item_spawn_system)
	
	# Vérification des TileMaps
	if has_node("TileMap/Sol") and has_node("TileMap/Decoration"):
		var texture: Texture2D = null
		if ResourceLoader.exists("res://assets/sprites/items/light_item.png"):
			texture = load("res://assets/sprites/items/light_item.png")
			print("✅ Texture item chargée")
		else:
			push_warning("⚠️ Texture d'item introuvable")
			var img: Image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
			img.fill(Color.YELLOW)
			texture = ImageTexture.create_from_image(img)
		
		var sol_layer: TileMapLayer = $TileMap/Sol as TileMapLayer
		var deco_layer: TileMapLayer = $TileMap/Decoration as TileMapLayer
		
		if sol_layer and deco_layer:
			item_spawn_system.setup(sol_layer, deco_layer, texture)
			item_spawn_system.item_collected.connect(_on_item_collected)
			print("✅ ItemSpawnSystem configuré")
		else:
			push_error("❌ Sol ou Decoration n'est pas un TileMapLayer")
			return
	else:
		push_error("❌ TileMap/Sol ou TileMap/Decoration introuvable")
		return
	
	# Système d'effets d'items
	item_effect_manager = ItemEffectManager.new()
	add_child(item_effect_manager)
	print("✅ ItemEffectManager configuré")
	
	# Système UI pour les items
	item_ui_system = ItemUISystem.new()
	add_child(item_ui_system)
	print("✅ ItemUISystem configuré")

# ========================================
# GESTION DES ITEMS
# ========================================

func _process(_delta: float) -> void:
	if item_spawn_system:
		var units: Array = get_tree().get_nodes_in_group("units")
		item_spawn_system.check_collection(units)


func _on_item_collected(item: Item, position: Vector2) -> void:
	print("📦 Item collecté: %s à %s" % [item.name, position])
	
	# Trouve l'unité la plus proche
	var collector: Unit = null
	var min_dist: float = INF
	
	for unit in get_tree().get_nodes_in_group("units"):
		if unit is Unit:
			var dist: float = unit.global_position.distance_to(position)
			if dist < min_dist:
				min_dist = dist
				collector = unit
	
	if not collector:
		push_warning("Aucune unité trouvée pour collecter l'item")
		return
	
	# Affiche le feedback UI
	if item_ui_system:
		item_ui_system.show_item_collected(item, position, self)
	
	# Applique l'effet de l'item
	if item_effect_manager:
		item_effect_manager.apply_item_effect(item, collector, self)

# ========================================
# SPAWN D'UNITÉS
# ========================================

func _spawn_units(camp: String, unit_type: String) -> void:
	var base: Base = base_enfer if camp == "enfer" else base_paradis
	
	if not base:
		push_error("Base non trouvée pour le camp: %s" % camp)
		return
	
	if not Constants.UNITS[camp].has(unit_type):
		push_error("Type d'unité inconnu: %s" % unit_type)
		return
	
	var unit_scene: PackedScene = Constants.UNITS[camp][unit_type]
	var count: int = Constants.SPAWN_COUNTS[unit_type]
	var cost: float = Constants.UNIT_COSTS[unit_type]
	
	# Spawner les unités avec délai
	for i in range(count):
		await base.spawn_unit(unit_scene, cost)
		if i < count - 1:
			await get_tree().create_timer(0.5).timeout

# ========================================
# GESTION DES PHASES
# ========================================

func _on_phase_changed(is_enfer_phase: bool) -> void:
	current_phase_is_enfer = is_enfer_phase
	_clear_selection()


func _clear_selection() -> void:
	for item in selected:
		if item.has("collider"):
			var collider: Node = item.collider
			if is_instance_valid(collider) and collider is Unit:
				if collider.selection_component:
					collider.selection_component.set_selected(false)
	selected.clear()

# ========================================
# SÉLECTION D'UNITÉS
# ========================================

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if selected.size() == 0:
				dragging = true
				drag_start = get_global_mouse_position()
			else:
				# Assigner cible aux unités sélectionnées
				for item in selected:
					if not item.has("collider"):
						continue
					var collider: Node = item.collider
					if is_instance_valid(collider) and collider is Unit:
						if collider.targeting_component:
							collider.targeting_component.target = get_global_mouse_position()
						if collider.selection_component:
							collider.selection_component.set_selected(false)
				selected.clear()
		elif dragging:
			dragging = false
			queue_redraw()
			_perform_selection(event.position)
	
	if event is InputEventMouseMotion and dragging:
		queue_redraw()


func _perform_selection(drag_end: Vector2) -> void:
	select_rect.extents = abs(drag_end - drag_start) / 2
	
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = select_rect
	query.collision_mask = 2
	query.transform = Transform2D(0, (drag_end + drag_start) / 2)
	
	selected = space.intersect_shape(query)
	
	# Filtrer les unités valides
	var valid_selected: Array = []
	for item in selected:
		if not item.has("collider"):
			continue
		
		var collider: Node = item.collider
		if is_instance_valid(collider) and collider is Unit:
			var unit_is_enfer: bool = collider.get_side()
			
			if unit_is_enfer == current_phase_is_enfer:
				if collider.selection_component:
					collider.selection_component.set_selected(true)
				valid_selected.append(item)
	
	selected = valid_selected


func _draw() -> void:
	if dragging:
		var start_local: Vector2 = to_local(drag_start)
		var end_local: Vector2 = get_local_mouse_position()
		draw_rect(
			Rect2(start_local, end_local - start_local), 
			Color.AQUA, 
			false,
			2.0
		)

# ========================================
# FIN DE PARTIE
# ========================================

func _on_victory(winner: String) -> void:
	print("%s gagne ! (Base détruite)" % winner.capitalize())
	
	if match_timer:
		match_timer.stop()
	
	if winner == "enfer":
		get_tree().change_scene_to_file("res://scenes/ui/victory/hell_wins.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/ui/victory/heaven_wins.tscn")


func _on_match_end() -> void:
	var pv_enfer: int = base_enfer.get_health() if base_enfer else 0
	var pv_paradis: int = base_paradis.get_health() if base_paradis else 0
	
	var winner: String = "enfer" if pv_enfer > pv_paradis else "paradis"
	
	print("Temps écoulé ! %s gagne par PV (Enfer: %d, Paradis: %d)" % 
		[winner.capitalize(), pv_enfer, pv_paradis])
	
	_on_victory(winner)
