extends StaticBody2D
class_name Base

@export var team: String = "neutral"
@export var max_health: int = 2500
var current_health: int = 2500
var gold_manager: GoldManagerParadise
var player: Player
var attacking_units: Array[Node2D] = []
var max_simultaneous_attackers: int = 3  # Maximum number of units that can attack the base at once

signal health_changed(current: int, max: int)
signal base_destroyed(winning_team: String)
signal unit_spawned(unit: Unit)
signal base_under_attack(attacker: Node2D)
signal attack_ended(attacker: Node2D)

func _ready() -> void:
	max_health = 2500
	current_health = max_health
	health_changed.emit(current_health, max_health)
	
	if not gold_manager:
		var gm_node = Node.new()
		gm_node.set_script(load("res://scripts/managers/GoldManagerParadise.gd"))  
		add_child(gm_node)
		gold_manager = gm_node as GoldManagerParadise  
		gold_manager.max_gold = 50.0
		gold_manager.regen_per_sec = 10.0 
		gold_manager.use_overtime_curve = true
		gold_manager.set_process(true)  
	
	player = Player.new(1 if team == "enfer" else 2, "Joueur " + team.capitalize(), team)
	add_child(player)
	player.set_camp(team)
	player.base = self
	player.modifier_or(0)
	
	if has_node("DetectionArea"):
		$DetectionArea.body_entered.connect(_on_enemy_nearby)
	
	add_to_group("bases")
	print("Base ", team, " ready (PV: ", current_health, ", Or: ", gold_manager.current_gold, ")")

func take_damage(amount: int, attacker: Node2D = null) -> bool:
	if attacker and not attacking_units.has(attacker):
		attacking_units.append(attacker)
		base_under_attack.emit(attacker)
	
	print("Base ", team, " prend ", amount, " dégâts ! PV: ", current_health, " → ", current_health - amount)
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		print("BASE ", team, " détruite !")
		var winner = "paradis" if team == "enfer" else "enfer"
		base_destroyed.emit(winner)
		
		call_deferred("queue_free")
		return true
	return false

func can_attack_base(unit: Node2D) -> bool:
	# Check if the unit is already attacking or if there's room for more attackers
	return attacking_has_room() or attacking_units.has(unit)

func attacking_has_room() -> bool:
	# Check if the base can accept more attackers
	return attacking_units.size() < max_simultaneous_attackers

func stop_attacking(unit: Node2D) -> void:
	if attacking_units.has(unit):
		attacking_units.erase(unit)
		attack_ended.emit(unit)

func get_enemy_base() -> Base:
	for b in get_tree().get_nodes_in_group("bases"):
		if b.team != team:
			return b
	return null

func spawn_unit(unit_scene: PackedScene, cost: int) -> Unit:
	"""Spawne une unité avec le nouveau système"""
	print("Tentative spawn pour ", team, " (or actuel: ", gold_manager.current_gold, ", besoin: ", cost, ")")
	
	if gold_manager.can_spend(cost):
		gold_manager.spend(cost)
		
		# Trouver la position de spawn
		var spawn_pos: Vector2
		var spawn_node_name = "SpawnPoint"
		if team == "enfer":
			spawn_node_name = "SpawnPointEnfer"
		elif team == "paradis":
			spawn_node_name = "SpawnPointParadis"
		
		if has_node(spawn_node_name):
			spawn_pos = get_node(spawn_node_name).global_position
			print("Spawn via ", spawn_node_name, " : Position = ", spawn_pos)
		else:
			spawn_pos = global_position + Vector2(50 if team == "enfer" else -50, 0)
			print("Fallback spawn pour ", team, " à ", spawn_pos)
		
		# Instancier l'unité
		var unit = unit_scene.instantiate() as Unit
		var random_offset = Vector2(randf_range(-20, 20), randf_range(-20, 20))
		unit.global_position = spawn_pos + random_offset
		
		var is_hell = (team == "enfer")
		unit.is_hell_faction = is_hell
		
		# Définir la cible vers la base ennemie
		var enemy_base = get_enemy_base()
		if enemy_base:
			unit.target = enemy_base.global_position
		
		# Ajouter l'unité au monde
		get_parent().add_child(unit)
		unit.add_to_group("units")
		unit_spawned.emit(unit)
		
		# Petit délai pour éviter les chevauchements
		await get_tree().create_timer(0.1).timeout
		
		print("Unité spawnée: %s à %s pour %s (is_hell_faction: %s) – Or restant: %.1f" % 
			[unit.unit_name, unit.global_position, team.capitalize(), is_hell, gold_manager.current_gold])
		
		return unit
	
	print("Or insuffisant pour ", team, " (besoin: ", cost, ", actuel: ", gold_manager.current_gold, ")")
	return null


func _on_enemy_nearby(body: Node2D) -> void:
	"""Appelé quand un ennemi entre dans la zone de détection de la base"""
	if body is Unit:
		var unit_is_hell = body.is_hell_faction
		var base_is_hell = (team == "enfer")
		
		# Si l'unité est du camp ennemi
		if unit_is_hell != base_is_hell:
			body.target = self.global_position
			print("🎯 Attaque auto sur base ", team, " par ", body.unit_name)

func get_side() -> bool:
	"""Retourne true si c'est le camp de l'Enfer"""
	return team == "enfer"

func get_health():
	return current_health

func set_health(value):
	current_health = value
	if current_health <= 0:
		take_damage(0)
