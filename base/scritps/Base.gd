extends StaticBody2D
class_name Base

@export var team: String = "neutral"  # "enfer" ou "paradis"
@export var max_health: int = 2500
var current_health: int

var gold_manager: goldManager
var player: Joueur

signal health_changed(current: int, max: int)
signal base_destroyed(winning_team: String)
signal unit_spawned(unit: Unit)

func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)
	
	if not gold_manager:
		var gm_node = Node.new()
		gm_node.set_script(load("res://scripts/goldManager.gd"))  
		add_child(gm_node)
		gold_manager = gm_node as goldManager  
		gold_manager.max_gold = 20.0
		gold_manager.regen_per_sec = 1.0  # GDD
		gold_manager.use_overtime_curve = true
		gold_manager.set_process(true)  
	
	# Joueur lié
	player = Joueur.new(1 if team == "enfer" else 2, "Joueur " + team.capitalize())
	add_child(player)
	player.set_camp(team)
	player.base = self
	
	if has_node("DetectionArea"):
		$DetectionArea.body_entered.connect(_on_enemy_nearby)
	
	add_to_group("bases")
	print("Base ", team, " ready (PV: ", current_health, ", Or: ", gold_manager.current_gold, ")")

func take_damage(amount: int) -> bool:
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		var winner = "paradis" if team == "enfer" else "enfer"
		base_destroyed.emit(winner)
		queue_free()
		return true
	return false

func get_enemy_base() -> Base:
	for b in get_tree().get_nodes_in_group("bases"):
		if b.team != team:
			return b
	return null

func spawn_unit(unit_scene: PackedScene, cost: int) -> Unit:
	if gold_manager.can_spend(cost):
		gold_manager.spend(cost)
		var unit = unit_scene.instantiate() as Unit
		unit.global_position = $SpawnPoint.global_position if has_node("SpawnPoint") else global_position + Vector2(50, 0)
		unit.enfer = (team == "enfer")
		if get_enemy_base():
			unit.target = get_enemy_base().global_position
		get_parent().add_child(unit)
		unit_spawned.emit(unit)
		print("Unité spawnée pour ", team, " (coût: ", cost, ")")
		return unit
	print("Or insuffisant (besoin: ", cost, ")")
	return null

func _on_enemy_nearby(body: Node2D) -> void:
	if body is Unit and body.get_side() != (team == "enfer"):
		body.target = self
		print("Attaque auto sur base ", team, " !")
