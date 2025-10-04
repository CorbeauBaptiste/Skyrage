extends Node2D

var dragging = false
var drag_start = Vector2.ZERO
var select_rect = RectangleShape2D.new()
var selected = []

@onready var base_enfer: Base = $BaseEnfer
@onready var base_paradis: Base = $BaseParadis
@onready var match_timer: Timer = $MatchTimer

func _ready() -> void:
	# Code existant pour drag/select (inchangé)
	
	# Intégration bases et match (GDD : 5 min, victoire par PV ou destruction)
	if match_timer:
		match_timer.wait_time = 300.0  # 5 min
		match_timer.timeout.connect(_on_match_end)
		match_timer.start()
	
	# Liens signaux victoire
	if base_enfer:
		base_enfer.base_destroyed.connect(_on_victory)
	if base_paradis:
		base_paradis.base_destroyed.connect(_on_victory)
	
	# Test liens joueurs/bases (console)
	if base_enfer and base_enfer.player:
		base_enfer.player.afficher_infos()
	if base_paradis and base_paradis.player:
		base_paradis.player.afficher_infos()

func _unhandled_input(event: InputEvent) -> void:
	# Code existant pour drag/select (inchangé)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if selected.size() == 0:
				dragging = true
				drag_start = event.position
			else:
				for item in selected:
					if item.collider is Base:  # Ignore bases pour sélection unités
						continue
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
				if item.collider is Base:  # Ignore bases
					continue
				item.collider.selected = true
	if event is InputEventMouseMotion and dragging:
		queue_redraw()
	
	# Test spawn unités (appuie Espace pour Enfer, Échap pour Paradis – assume unit.tscn)
	if event.is_action_pressed("ui_accept"):  # Espace : Spawn Enfer
		if base_enfer:
			base_enfer.spawn_unit(preload("res://unit/unit_enfer/ange_dechu/ange_dechu.tscn"), 5)  # Coût exemple GDD
	if event.is_action_pressed("ui_cancel"):  # Échap : Spawn Paradis
		if base_paradis:
			base_paradis.spawn_unit(preload("res://unit/unit_paradis/ange/ange.tscn"), 5)

func _draw():
	# Code existant (inchangé)
	if dragging:
		draw_rect(Rect2(drag_start, get_global_mouse_position() - drag_start), Color.AQUA, false)

func _on_victory(winner: String) -> void:
	print(winner.capitalize() + " gagne ! (Base détruite)")
	if match_timer:
		match_timer.stop()
	# TODO : Écran fin de match (GDD)

func _on_match_end() -> void:
	var pv_enfer = base_enfer.current_health if base_enfer else 0
	var pv_paradis = base_paradis.current_health if base_paradis else 0
	var winner = "enfer" if pv_enfer > pv_paradis else "paradis"
	print(winner.capitalize() + " gagne par PV restants ! (Enfer: ", pv_enfer, ", Paradis: ", pv_paradis, ")")
	# TODO : Écran fin
