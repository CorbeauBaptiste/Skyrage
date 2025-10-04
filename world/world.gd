extends Node2D

var dragging = false
var drag_start = Vector2.ZERO
var select_rect = RectangleShape2D.new()
var selected = []
var tour_enfer = false

@onready var base_enfer: Base = $BaseEnfer
@onready var base_paradis: Base = $BaseParadis
@onready var match_timer: Timer = $MatchTimer

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
		
		
	var label_or_enfer = Label.new()
	label_or_enfer.position = Vector2(10, 10)
	label_or_enfer.text = "Enfer Or: 0"
	add_child(label_or_enfer)
	base_enfer.gold_manager.gold_changed.connect(func(c, m): label_or_enfer.text = "Enfer Or: " + str(int(c)))

	var label_or_paradis = Label.new()
	label_or_paradis.position = Vector2(10, 50)
	label_or_paradis.text = "Paradis Or: 0"
	add_child(label_or_paradis)
	base_paradis.gold_manager.gold_changed.connect(func(c, m): label_or_paradis.text = "Paradis Or: " + str(int(c)))
	
	
	var label_help_paradis = Label.new()
	label_help_paradis.position = Vector2(10, 80)
	label_help_paradis.text = "cliquer esc pour spawn unite paradis"
	add_child(label_help_paradis)
	
	
	var label_help_enfer = Label.new()
	label_help_enfer.position = Vector2(10, 100)
	label_help_enfer.text = "cliquer espace pour spawn unite enfer"
	add_child(label_help_enfer)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if selected.size() == 0:
				dragging = true
				drag_start = event.position
			else:
				for item in selected:
					var collider = item.collider
					if collider is Unit:
						# Système de tours : ne déplace que si c'est ton tour
						if collider.get_side() == tour_enfer:
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
					# Système de tours : ne sélectionne que si c'est ton tour
					if collider.get_side() == tour_enfer:
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
				print("Spawn déclenché : Backspace – Paradis")
				if base_paradis:
					var unit = base_paradis.spawn_unit(preload("res://unit/unit_paradis/ange/ange.tscn"), 5)
					if unit:
						print("DEBUG SPAWN PARADIS : unit.enfer = ", unit.enfer, " (doit être false)")
					else:
						print("Spawn Paradis échoué (or <5 ?)")
			_:
				print("Touche non mappée : keycode = ", event.keycode, " (Espace=KEY_SPACE, Backspace=KEY_BACKSPACE)")
						

func _draw():
	if dragging:
		draw_rect(Rect2(drag_start, get_global_mouse_position() - drag_start), Color.NAVY_BLUE, false)

func _on_timer_tour_timer_started() -> void:
	if tour_enfer:
		tour_enfer = false
		$Label.text = "Tour : Paradis"
	else:
		tour_enfer = true
		$Label.text = "Tour : Enfer"

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