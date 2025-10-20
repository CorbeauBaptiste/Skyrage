extends Node2D

var dragging = false
var drag_start = Vector2.ZERO
var select_rect = RectangleShape2D.new()
var selected = []

# Systèmes d'items
var item_spawn_system: ItemSpawnSystem
var item_effect_manager: ItemEffectManager
var item_ui_system: ItemUISystem

@onready var base_enfer: Base = $BaseEnfer
@onready var base_paradis: Base = $BaseParadis
@onready var match_timer: Timer = Timer.new()

var ui_layer: CanvasLayer
var hud_enfer
var hud_paradis

var current_phase_is_enfer: bool = false

func _ready() -> void:
	# Add timer to scene
	add_child(match_timer)
	match_timer.wait_time = Constants.MATCH_DURATION
	match_timer.timeout.connect(_on_match_end)
	match_timer.start()
	
	if base_enfer:
		base_enfer.base_destroyed.connect(_on_victory)
	if base_paradis:
		base_paradis.base_destroyed.connect(_on_victory)
	
	# Attendre que les bases soient prêtes
	await get_tree().process_frame
	
	if base_enfer and base_enfer.player:
		base_enfer.player.afficher_infos()
	if base_paradis and base_paradis.player:
		base_paradis.player.afficher_infos()

	_setup_ui()
	_setup_item_systems()

func _setup_item_systems() -> void:
	"""Configure le système d'items complet"""
	print("🔧 Configuration des systèmes d'items...")
	
	# Système de spawn d'items
	item_spawn_system = ItemSpawnSystem.new()
	add_child(item_spawn_system)
	
	# Vérifie que les TileMapLayer existent
	if has_node("TileMap/Sol") and has_node("TileMap/Decoration"):
		# Charge la texture (avec fallback si introuvable)
		var texture: Texture2D = null
		if ResourceLoader.exists("res://assets/sprites/items/light_item.png"):
			texture = load("res://assets/sprites/items/light_item.png")
			print("✅ Texture item chargée")
		else:
			push_warning("⚠️ Texture d'item introuvable, utilisation d'une texture par défaut")
			# Créer une texture simple de fallback
			var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
			img.fill(Color.YELLOW)
			texture = ImageTexture.create_from_image(img)
		
		# Récupère les layers (pas la TileMap parente !)
		var sol_layer = $TileMap/Sol as TileMapLayer
		var deco_layer = $TileMap/Decoration as TileMapLayer
		
		if sol_layer and deco_layer:
			item_spawn_system.setup(sol_layer, deco_layer, texture)
			item_spawn_system.item_collected.connect(_on_item_collected)
			print("✅ ItemSpawnSystem configuré avec Sol + Decoration")
		else:
			push_error("❌ Sol ou Decoration n'est pas un TileMapLayer !")
			return
	else:
		push_error("❌ TileMap/Sol ou TileMap/Decoration introuvable !")
		if has_node("TileMap"):
			print("TileMap trouvée, enfants disponibles :")
			for child in $TileMap.get_children():
				print("  - %s (%s)" % [child.name, child.get_class()])
		return
	
	# Système d'effets d'items
	item_effect_manager = ItemEffectManager.new()
	add_child(item_effect_manager)
	print("✅ ItemEffectManager configuré")
	
	# Système UI pour les items
	item_ui_system = ItemUISystem.new()
	add_child(item_ui_system)
	print("✅ ItemUISystem configuré")

func _process(_delta: float) -> void:
	# Vérifier la collecte d'items
	if item_spawn_system:
		var units = get_tree().get_nodes_in_group("units")
		item_spawn_system.check_collection(units)

func _on_item_collected(item: Item, position: Vector2) -> void:
	"""Callback quand un item est collecté"""
	print("📦 Item collecté: %s à %s" % [item.name, position])
	
	# Trouve l'unité la plus proche qui a collecté
	var collector: Unit = null
	var min_dist = INF
	
	for unit in get_tree().get_nodes_in_group("units"):
		if unit is Unit:
			var dist = unit.global_position.distance_to(position)
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

func _setup_ui() -> void:
	"""Configure les HUDs des deux camps"""
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

func _spawn_units(camp: String, unit_type: String) -> void:
	"""Spawn plusieurs unités selon leur type"""
	var base = base_enfer if camp == "enfer" else base_paradis
	
	if not base:
		push_error("Base non trouvée pour le camp: %s" % camp)
		return
	
	if not Constants.UNITS[camp].has(unit_type):
		push_error("Type d'unité inconnu: %s" % unit_type)
		return
	
	var unit_scene = Constants.UNITS[camp][unit_type]
	var count = Constants.SPAWN_COUNTS[unit_type]
	var cost = Constants.UNIT_COSTS[unit_type]
	
	# Spawner les unites avec un délai
	for i in range(count):
		await base.spawn_unit(unit_scene, cost)
		if i < count - 1:
			await get_tree().create_timer(0.5).timeout

func _on_phase_changed(is_enfer_phase: bool) -> void:
	current_phase_is_enfer = is_enfer_phase
	_clear_selection()

func _clear_selection() -> void:
	"""Déselectionne toutes les unités"""
	for item in selected:
		if item.has("collider"):
			var collider = item.collider
			if is_instance_valid(collider) and collider is Unit:
				collider.selected = false
	selected.clear()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if selected.size() == 0:
				dragging = true
				drag_start = get_global_mouse_position()
			else:
				for item in selected:
					if not item.has("collider"):
						continue
					var collider = item.collider
					if is_instance_valid(collider) and collider is Unit:
						collider.target = get_global_mouse_position()
						collider.selected = false
				selected.clear()
		elif dragging:
			dragging = false
			queue_redraw()
			_perform_selection(event.position)
	
	if event is InputEventMouseMotion and dragging:
		queue_redraw()

func _perform_selection(drag_end: Vector2) -> void:
	"""Effectue la sélection des unités dans le rectangle"""
	select_rect.extents = abs(drag_end - drag_start) / 2
	
	var space = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = select_rect
	query.collision_mask = 2
	query.transform = Transform2D(0, (drag_end + drag_start) / 2)
	
	selected = space.intersect_shape(query)
	
	# Filtrer les unites valides
	var valid_selected = []
	for item in selected:
		if not item.has("collider"):
			continue
		
		var collider = item.collider
		if is_instance_valid(collider) and collider is Unit:
			var unit_is_enfer = collider.get_side()
			
			if unit_is_enfer == current_phase_is_enfer:
				collider.selected = true
				valid_selected.append(item)
	
	selected = valid_selected

func _draw() -> void:
	"""Dessine le rectangle de sélection"""
	if dragging:
		var start_local = to_local(drag_start)
		var end_local = get_local_mouse_position()
		draw_rect(
			Rect2(start_local, end_local - start_local), 
			Color.AQUA, 
			false,
			2.0
		)

func _on_victory(winner: String) -> void:
	"""Appelé quand une base est détruite"""
	print("%s gagne ! (Base détruite)" % winner.capitalize())
	
	if match_timer:
		match_timer.stop()
	
	if winner == "enfer":
		get_tree().change_scene_to_file("res://scenes/ui/victory/hell_wins.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/ui/victory/heaven_wins.tscn")

func _on_match_end() -> void:
	"""Appelé quand le timer de 5 minutes expire"""
	var pv_enfer = base_enfer.current_health if base_enfer else 0
	var pv_paradis = base_paradis.current_health if base_paradis else 0
	
	var winner = "enfer" if pv_enfer > pv_paradis else "paradis"
	
	print("Temps écoulé ! %s gagne par PV restants (Enfer: %d, Paradis: %d)" % 
		[winner.capitalize(), pv_enfer, pv_paradis])
