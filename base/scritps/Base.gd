extends StaticBody2D
class_name Base

@export var team: String = "neutral"  # Édite dans inspecteur : "enfer" ou "paradis"
@export var max_health: int = 2500    # PV du GDD
var current_health: int

var gold_manager: goldManager         # Ton script existant
var player: Joueur                    # Joueur lié

signal health_changed(current: int, max: int)
signal base_destroyed(winning_team: String)
signal unit_spawned(unit: Unit)

func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)
	
	# Créer goldManager si pas déjà (ajoute comme enfant)
	gold_manager = get_node_or_null("GoldManager")  # Si tu l'ajoutes manuellement
	if not gold_manager:
		gold_manager = preload("res://scripts/goldManager.gd").new()  # Assure-toi que c'est un PackedScene ou direct new()
		var gm_node = Node.new()
		gm_node.set_script(gold_manager)
		add_child(gm_node)
		gold_manager = gm_node
		gold_manager.max_gold = 20.0
		gold_manager.regen_per_sec = 1.0  # 1 or/sec GDD
		gold_manager.use_overtime_curve = true
	
	# Créer & lier Joueur
	player = Joueur.new(1 if team == "enfer" else 2, "Joueur " + team.capitalize(), team)
	add_child(player)
	player.base = self  # Lier ref (modif Joueur plus bas)
	
	# Détection ennemis pour attaque auto (GDD)
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

func spawn_unit(unit_scene: PackedScene, cost: int) -> Unit:  # Pour spawn unités (GDD)
	if gold_manager.can_spend(cost):
		gold_manager.spend(cost)
		var unit = unit_scene.instantiate() as Unit
		unit.global_position = $SpawnPoint.global_position
		unit.enfer = (team == "enfer")  # Côté basé sur team
		unit.target = get_enemy_base()  # Auto cible base adverse
		get_parent().add_child(unit)  # Ajoute au World
		unit_spawned.emit(unit)
		return unit
	return null

func _on_enemy_nearby(body: Node2D) -> void:
	if body is Unit and body.get_side() != (team == "enfer"):  # Ennemi
		body.target = self  # Attaque la base !
