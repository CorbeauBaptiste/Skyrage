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
	hud_enfer = preload("res://scripts/hudE.tscn").instantiate()
	ui_layer.add_child(hud_enfer)
	if hud_enfer and hud_enfer.has_signal("btn4_pressed"):
		hud_enfer.btn4_pressed.connect(_on_btn4_pressed)
	if hud_enfer and hud_enfer.has_signal("btn2_pressed"):
		hud_enfer.btn2_pressed.connect(_on_btn2_pressed)
	if hud_enfer and hud_enfer.has_signal("btn6_pressed"):
		hud_enfer.btn6_pressed.connect(_on_btn6_pressed)

	hud_paradis = preload("res://scripts/hud.tscn").instantiate()
	ui_layer.add_child(hud_paradis)
	if hud_paradis and hud_paradis.has_signal("btn2_pressed"):
		hud_paradis.btn2_pressed.connect(_on_p_btn2_pressed)
	if hud_paradis and hud_paradis.has_signal("btn4_pressed"):
		hud_paradis.btn4_pressed.connect(_on_p_btn4_pressed)
	if hud_paradis and hud_paradis.has_signal("btn6_pressed"):
		hud_paradis.btn6_pressed.connect(_on_p_btn6_pressed)

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

func _on_btn4_pressed() -> void:
	if base_enfer:
		var unit1 = base_enfer.spawn_unit(preload("res://unit/unit_enfer/ange_dechu/ange_dechu.tscn"), 11)
		if unit1:
			print("DEBUG SPAWN ENFER : 2 unités ange déchu créées (enfer = true)")
		else:
			print("Spawn Enfer échoué (or <11 ?)")

func _on_btn2_pressed() -> void:
	if base_enfer:
		var unit1 = base_enfer.spawn_unit(preload("res://unit/unit_enfer/diablotin/diablotin.tscn"), 11)
		if unit1:
			print("DEBUG SPAWN ENFER : 3 unités ange déchu créées (enfer = true)")
		else:
			print("Spawn Enfer échoué (or <11 ?)")

func _on_btn6_pressed() -> void:
	if base_enfer:
		var unit1 = base_enfer.spawn_unit(preload("res://unit/unit_enfer/demon/demon.tscn"), 11)
		if unit1:
			print("DEBUG SPAWN ENFER : 1 unité ange déchu créée (enfer = true)")
		else:
			print("Spawn Enfer échoué (or <11 ?)")

func _on_p_btn2_pressed() -> void:
	if base_paradis:
		var unit1 = base_paradis.spawn_unit(preload("res://unit/unit_paradis/ange/ange.tscn"), 5)
		if unit1:
			print("DEBUG SPAWN PARADIS : 3 unités ange créées (enfer = false)")
		else:
			print("Spawn Paradis échoué (or <5 ?)")

func _on_p_btn4_pressed() -> void:
	if base_paradis:
		var unit1 = base_paradis.spawn_unit(preload("res://unit/unit_paradis/archange/archange.tscn"), 5)
		if unit1:
			print("DEBUG SPAWN PARADIS : 2 unités ange créées (enfer = false)")
		else:
			print("Spawn Paradis échoué (or <5 ?)")

func _on_p_btn6_pressed() -> void:
	if base_paradis:
		var unit1 = base_paradis.spawn_unit(preload("res://unit/unit_paradis/seraphin/seraphin.tscn"), 5)
		if unit1:
			print("DEBUG SPAWN PARADIS : 1 unité ange créée (enfer = false)")
		else:
			print("Spawn Paradis échoué (or <5 ?)")
