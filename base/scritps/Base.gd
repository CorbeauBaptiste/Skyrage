extends StaticBody2D
class_name Base

@export var team: String = "neutral"  
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
	
	gold_manager = get_node_or_null("GoldManager")  
	if not gold_manager:
		gold_manager = preload("res://scripts/goldManager.gd").new() 
		var gm_node = Node.new()
		gm_node.set_script(gold_manager)
		add_child(gm_node)
		gold_manager = gm_node
		gold_manager.max_gold = 20.0
		gold_manager.regen_per_sec = 1.0 
		gold_manager.use_overtime_curve = true
	
	player = Joueur.new(1 if team == "enfer" else 2, "Joueur " + team.capitalize())
	add_child(player)
	player.set_camp(team) 
	player.base = self
	
	$DetectionArea.body_entered.connect(_on_enemy_nearby)
	
	add_to_group("bases")  # Pour trouver l'autre base

func take_damage(amount: int) -> bool:
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		var winner = "paradis" if team == "enfer" else "enfer"
		base_destroyed.emit(winner)
		queue_free()
		return true  # Détruite
	return false

func get_enemy_base() -> Base:
	for base in get_tree().get_nodes_in_group("bases"):
		if base.team != team:
			return base
	return null

func spawn_unit(unit_scene: PackedScene, cost: int) -> Unit:  # Pour spawn unités
	if gold_manager.can_spend(cost):
		gold_manager.spend(cost)
		var unit = unit_scene.instantiate() as Unit
		unit.global_position = $SpawnPoint.global_position
		unit.enfer = (team == "enfer")  # Cote basé sur team
		unit.target = get_enemy_base()  # Auto cible base adverse
		get_parent().add_child(unit)  # Ajoute au World
		unit_spawned.emit(unit)
		return unit
	return null

func _on_enemy_nearby(body: Node2D) -> void:
	if body is Unit and body.get_side() != (team == "enfer"):  # Ennemi
		body.target = self  # Attaque la base
