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

var current_phase_is_enfer: bool = false # true = phase enfer, false = phase paradis

func _ready() -> void:
	
	if match_timer:
		match_timer.wait_time = 300.0 
		match_timer.timeout.connect(_on_match_end)
		match_timer.start()
	
	if base_enfer:
		base_enfer.base_destroyed.connect(_on_victory)
	if base_paradis:
		base_paradis.base_destroyed.connect(_on_victory)
	
	if base_enfer and base_enfer.player:
		base_enfer.player.afficher_infos()
	if base_paradis and base_paradis.player:
		base_paradis.player.afficher_infos()

	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	
	# Setup HUD Enfer
	hud_enfer = preload("res://scripts/hudE.tscn").instantiate()
	ui_layer.add_child(hud_enfer)
	if hud_enfer:
		hud_enfer.btn2_pressed.connect(_on_btn2_pressed)
		hud_enfer.btn4_pressed.connect(_on_btn4_pressed)
		hud_enfer.btn6_pressed.connect(_on_btn6_pressed)
		hud_enfer.phase_changed.connect(func(is_active): 
			if is_active:
				_on_phase_changed(true)
		)

	# Setup HUD Paradis
	hud_paradis = preload("res://scripts/hud.tscn").instantiate()
	ui_layer.add_child(hud_paradis)
	if hud_paradis:
		hud_paradis.btn2_pressed.connect(_on_p_btn2_pressed)
		hud_paradis.btn4_pressed.connect(_on_p_btn4_pressed)
		hud_paradis.btn6_pressed.connect(_on_p_btn6_pressed)
		hud_paradis.phase_changed.connect(func(is_active): 
			if is_active:
				_on_phase_changed(false)
		)

func _on_phase_changed(is_enfer_phase: bool) -> void:
	current_phase_is_enfer = is_enfer_phase
	print("🔄 Phase changée : ", "ENFER" if is_enfer_phase else "PARADIS")
	
	# Déselectionner toutes les unités au changement de phase
	for item in selected:
		if item.has("collider"):
			var collider = item.collider
			if is_instance_valid(collider) and collider is Unit:
				collider.selected = false
	selected = []

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if selected.size() == 0:
				dragging = true
				drag_start = event.position
			else:
				for item in selected:
					if not item.has("collider"):
						continue
					var collider = item.collider
					if is_instance_valid(collider) and collider is Unit:
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
					else:
						print("❌ Cannot select enemy unit during ", "ENFER" if current_phase_is_enfer else "PARADIS", " phase")
				else:
					print("Ignore collider non-Unit ou invalide")
			selected = valid_selected
			
	if event is InputEventMouseMotion and dragging:
		queue_redraw()

func _draw():
	if dragging:
		draw_rect(Rect2(drag_start, get_global_mouse_position() - drag_start), Color.AQUA, false)

func _on_victory(winner: String) -> void:
	print(winner.capitalize() + " gagne ! (Base détruite)")
	if match_timer:
		match_timer.stop()

func _on_match_end() -> void:
	var pv_enfer = base_enfer.current_health if base_enfer else 0
	var pv_paradis = base_paradis.current_health if base_paradis else 0
	var winner = "enfer" if pv_enfer > pv_paradis else "paradis"
	print(winner.capitalize() + " gagne par PV restants ! (Enfer: ", pv_enfer, ", Paradis: ", pv_paradis, ")")

func _on_btn2_pressed() -> void:
	if base_enfer:
		base_enfer.spawn_unit(preload("res://unit/unit_enfer/diablotin/diablotin.tscn"), 11)
		await get_tree().create_timer(0.5).timeout
		base_enfer.spawn_unit(preload("res://unit/unit_enfer/diablotin/diablotin.tscn"), 11)
		await get_tree().create_timer(0.5).timeout
		base_enfer.spawn_unit(preload("res://unit/unit_enfer/diablotin/diablotin.tscn"), 11)
		print("DEBUG SPAWN ENFER : 3 unités diablotin créées (enfer = true)")

func _on_btn4_pressed() -> void:
	if base_enfer:
		base_enfer.spawn_unit(preload("res://unit/unit_enfer/ange_dechu/ange_dechu.tscn"), 11)
		await get_tree().create_timer(0.5).timeout
		base_enfer.spawn_unit(preload("res://unit/unit_enfer/ange_dechu/ange_dechu.tscn"), 11)
		print("DEBUG SPAWN ENFER : 2 unités ange déchu créées (enfer = true)")

func _on_btn6_pressed() -> void:
	if base_enfer:
		base_enfer.spawn_unit(preload("res://unit/unit_enfer/demon/demon.tscn"), 11)
		print("DEBUG SPAWN ENFER : 1 unité démon créée (enfer = true)")

func _on_p_btn2_pressed() -> void:
	if base_paradis:
		base_paradis.spawn_unit(preload("res://unit/unit_paradis/ange/ange.tscn"), 5)
		await get_tree().create_timer(0.5).timeout
		base_paradis.spawn_unit(preload("res://unit/unit_paradis/ange/ange.tscn"), 5)
		await get_tree().create_timer(0.5).timeout
		base_paradis.spawn_unit(preload("res://unit/unit_paradis/ange/ange.tscn"), 5)
		print("DEBUG SPAWN PARADIS : 3 unités ange créées (enfer = false)")

func _on_p_btn4_pressed() -> void:
	if base_paradis:
		base_paradis.spawn_unit(preload("res://unit/unit_paradis/seraphin/seraphin.tscn"), 5)
		await get_tree().create_timer(0.5).timeout
		base_paradis.spawn_unit(preload("res://unit/unit_paradis/seraphin/seraphin.tscn"), 5)
		print("DEBUG SPAWN PARADIS : 2 unités séraphin créées (enfer = false)")

func _on_p_btn6_pressed() -> void:
	if base_paradis:
		base_paradis.spawn_unit(preload("res://unit/unit_paradis/archange/archange.tscn"), 5)
		print("DEBUG SPAWN PARADIS : 1 unité archange créée (enfer = false)")
