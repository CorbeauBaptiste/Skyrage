extends Node2D

var dragging = false
var drag_start = Vector2.ZERO
var select_rect = RectangleShape2D.new()
var selected = []

@onready var base_enfer: Base = $BaseEnfer
@onready var base_paradis: Base = $BaseParadis
@onready var match_timer: Timer = $MatchTimer

var ui_layer: CanvasLayer
var hud_enfer
var hud_paradis

var current_phase_is_enfer: bool = false

func _ready() -> void:
	# Timer de match
	if match_timer:
		match_timer.wait_time = Constants.MATCH_DURATION
		match_timer.timeout.connect(_on_match_end)
		match_timer.start()
	
	if base_enfer:
		base_enfer.base_destroyed.connect(_on_victory)
	if base_paradis:
		base_paradis.base_destroyed.connect(_on_victory)
	
	# Afficher infos joueurs
	if base_enfer and base_enfer.player:
		base_enfer.player.afficher_infos()
	if base_paradis and base_paradis.player:
		base_paradis.player.afficher_infos()

	_setup_ui()

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
	
	#print("Spawn de %d %s pour %s (coût: %d)" % [count, unit_type, camp.capitalize(), cost])
	
	# Spawner les unites avec un délai
	for i in range(count):
		await base.spawn_unit(unit_scene, cost)
		if i < count - 1:
			await get_tree().create_timer(0.5).timeout

func _on_phase_changed(is_enfer_phase: bool) -> void:
	current_phase_is_enfer = is_enfer_phase
	#print("Phase changée : %s" % ("ENFER" if is_enfer_phase else "PARADIS"))
	
	# TODO: faire arrêter les unites
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
			
			# Vérifier que l'unite appartient au camp de la phase actuelle
			if unit_is_enfer == current_phase_is_enfer:
				collider.selected = true
				valid_selected.append(item)
			else:
				print("Impossible de sélectionner une unité ennemie pendant la phase %s" % 
					("ENFER" if current_phase_is_enfer else "PARADIS"))
	
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
	
	# TODO: faire une scene en cas d'egalite
