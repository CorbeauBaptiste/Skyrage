extends StaticBody2D
class_name Base

@export var team: String = "neutral"  # "enfer" ou "paradis"
@export var max_health: int = 2500    # PV max du GDD
var current_health: int              # PV actuels

var gold_manager: goldManager        # Ton goldManager intégré
var player: Joueur                   # Le joueur lié à cette base

signal health_changed(current: int, max: int)  # Pour UI/timer fin de match
signal base_destroyed(winning_team: String)    # Victoire !

func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)
	
	# Intégrer goldManager (créé auto si pas assigné via éditeur)
	if not gold_manager:
		gold_manager = goldManager.new()
		add_child(gold_manager)  # Ajoute comme enfant
		gold_manager.max_gold = 20.0  # Limite max or
		gold_manager.regen_per_sec = 1.0  # 1 or/sec du GDD
		gold_manager.use_overtime_curve = true
		# Sync avec GDD : Double regen après 4 min (300s total match)
	
	# Créer/lier Joueur (on fixera le camp plus tard)
	player = Joueur.new(1, "Player")  # ID 1 pour l'instant
	add_child(player)
	player.camp = team  # Lier au camp de la base
	
	# Connecter détection ennemis (unités proches = attaque auto)
	$DetectionArea.body_entered.connect(_on_enemy_near)
	
	add_to_group("bases")  # Pour trouver l'autre base facilement

func take_damage(amount: int) -> void:
	current_health -= amount
	current_health = max(0, current_health)  # Pas négatif
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		# Victoire adverse ! (GDD)
		var winner = "paradis" if team == "enfer" else "enfer"
		base_destroyed.emit(winner)
		queue_free()  # Détruit la base

func get_enemy_base() -> Base:
	# Trouve la base adverse (pour cibler unités)
	var bases = get_tree().get_nodes_in_group("bases")
	for b in bases:
		if b.team != team:
			return b
	return null

func _on_enemy_near(body: Node2D) -> void:
	if body is Unit and body.get_side() != (team == "enfer"):  # Ennemi ?
		body.target = self  # Redirige l'unité vers la base
