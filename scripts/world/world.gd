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
var active_items_display: ActiveItemsDisplay

# ========================================
# SÉLECTION
# ========================================

var dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO
var select_rect: RectangleShape2D = RectangleShape2D.new()
var selected: Array = []

# NOUVEAU : Layer dédié pour le rectangle de sélection
var selection_canvas: CanvasLayer
var selection_rect_node: Control

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
# IA DE BASE
# ========================================

var ai_enfer: BaseAIController = null
var ai_paradis: BaseAIController = null

# ========================================
# INITIALISATION
# ========================================

func _ready() -> void:
	_setup_selection_canvas()  # NOUVEAU
	_setup_match_timer()
	_setup_bases()
	_setup_ui()
	_setup_item_systems()
	
	await get_tree().process_frame
	
	if base_enfer and base_enfer.player:
		base_enfer.player.afficher_infos()
	if base_paradis and base_paradis.player:
		base_paradis.player.afficher_infos()


# NOUVEAU : Crée un CanvasLayer dédié pour le rectangle de sélection
func _setup_selection_canvas() -> void:
	selection_canvas = CanvasLayer.new()
	selection_canvas.layer = 100  # Au-dessus de tout
	add_child(selection_canvas)
	
	# Control qui dessinera le rectangle
	selection_rect_node = Control.new()
	selection_rect_node.set_anchors_preset(Control.PRESET_FULL_RECT)  # Prend tout l'écran
	selection_rect_node.mouse_filter = Control.MOUSE_FILTER_IGNORE  # N'intercepte pas les clics
	selection_rect_node.draw.connect(_draw_selection_rect)  # Connecte à notre fonction de dessin
	selection_canvas.add_child(selection_rect_node)


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

	# Désactiver les HUDs des équipes IA
	_apply_game_mode()


## Applique les restrictions du mode de jeu actuel.
func _apply_game_mode() -> void:
	print("[World] Mode de jeu: %s" % GameMode.Mode.keys()[GameMode.current_mode])

	# Désactiver le HUD de l'équipe IA (Enfer) et activer l'IA
	if GameMode.enfer_is_ai:
		if hud_enfer:
			hud_enfer.disable_for_ai()
		_setup_ai("enfer")

	# Désactiver le HUD de l'équipe IA (Paradis) et activer l'IA
	if GameMode.paradis_is_ai:
		if hud_paradis:
			hud_paradis.disable_for_ai()
		_setup_ai("paradis")


## Configure l'IA pour une équipe.
func _setup_ai(team: String) -> void:
	var base: Base = base_enfer if team == "enfer" else base_paradis

	if not base:
		push_error("[World] Base %s introuvable pour l'IA" % team)
		return

	var ai_controller: BaseAIController = BaseAIController.new()
	ai_controller.name = "AI_" + team.capitalize()
	add_child(ai_controller)
	ai_controller.setup(base, self)

	if team == "enfer":
		ai_enfer = ai_controller
	else:
		ai_paradis = ai_controller

	print("[World] IA %s configurée" % team.capitalize())



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

	# Système d'affichage des items actifs
	active_items_display = ActiveItemsDisplay.new()
	add_child(active_items_display)
	print("✅ ActiveItemsDisplay configuré")

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

	# Affiche l'item dans l'interface (tous les types, même instantanés)
	if active_items_display:
		var camp: String = "enfer" if collector.get_side() else "paradis"
		active_items_display.add_active_item(camp, item, float(item.duration))

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

	# Spawner les unités avec délai (le coût est déjà payé par le HUD)
	for i in range(count):
		await base.spawn_unit_no_cost(unit_scene)
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
	# Contrôle de vitesse du jeu (touches 1-5)
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: Engine.time_scale = 1.0
			KEY_2: Engine.time_scale = 2.0
			KEY_3: Engine.time_scale = 3.0
			KEY_4: Engine.time_scale = 5.0
			KEY_5: Engine.time_scale = 10.0

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Début du clic
			if selected.size() == 0:
				dragging = true
				drag_start = get_global_mouse_position()
				selection_rect_node.queue_redraw()  # MODIFIÉ : redraw sur le Control
		else:
			# Relâchement du clic
			if dragging:
				# Fin du drag : sélection par zone
				dragging = false
				selection_rect_node.queue_redraw()  # MODIFIÉ
				_perform_selection(get_global_mouse_position())
			else:
				# Clic simple : ordre de déplacement
				var click_pos := get_global_mouse_position()
				
				for item in selected:
					if not item.has("collider"):
						continue
					var collider: Node = item.collider
					if is_instance_valid(collider) and collider is Unit:
						if collider.targeting_component:
							collider.targeting_component.set_target(click_pos)  # ✅ NOUVEAU
							collider.targeting_component.current_enemy = null
							collider.targeting_component.is_attacking_base = false
							print("CLICK: déplacement vers %s" % click_pos)
						if collider.selection_component:
							collider.selection_component.set_selected(false)
				selected.clear()
	
	if event is InputEventMouseMotion and dragging:
		selection_rect_node.queue_redraw()  # MODIFIÉ


func _perform_selection(drag_end: Vector2) -> void:
	select_rect.extents = abs(drag_end - drag_start) / 2

	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = select_rect
	query.collision_mask = 2
	query.transform = Transform2D(0, (drag_end + drag_start) / 2)

	selected = space.intersect_shape(query)

	# Filtrer les unités valides (et appartenant à une équipe contrôlée par un joueur)
	var valid_selected: Array = []
	for item in selected:
		if not item.has("collider"):
			continue

		var collider: Node = item.collider
		if is_instance_valid(collider) and collider is Unit:
			# Vérifier si l'unité appartient à une équipe contrôlée par un joueur
			if not _can_select_unit(collider):
				continue

			if collider.selection_component:
				collider.selection_component.set_selected(true)
			valid_selected.append(item)

	selected = valid_selected


## Vérifie si une unité peut être sélectionnée par le joueur.
##
## @param unit: L'unité à vérifier
## @return: true si l'unité peut être sélectionnée
func _can_select_unit(unit: Unit) -> bool:
	# Déterminer l'équipe de l'unité
	var unit_team: String = "enfer" if unit.is_hell_faction else "paradis"

	# L'unité ne peut être sélectionnée que si son équipe est contrôlée par un joueur
	return GameMode.is_team_player(unit_team)


# MODIFIÉ : Fonction de dessin appelée par le Control dans le CanvasLayer
func _draw_selection_rect() -> void:
	if dragging:
		# Convertit les positions monde en positions écran
		var start_screen := get_viewport().canvas_transform * drag_start
		var end_screen := get_viewport().canvas_transform * get_global_mouse_position()
		
		var rect := Rect2(start_screen, end_screen - start_screen)
		
		# Dessine le rectangle
		selection_rect_node.draw_rect(rect, Color(0, 1, 1, 0.2), true)  # Fond cyan transparent
		selection_rect_node.draw_rect(rect, Color(0, 1, 1, 1.0), false, 2.0)  # Bordure cyan

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
