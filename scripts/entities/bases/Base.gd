class_name Base
extends StaticBody2D

## Classe de base pour les bases (Enfer et Paradis).
##
## Architecture par composition :
## - Utilise des components pour gérer santé, spawn, attaque, or
## - Délègue les responsabilités aux components
## - Classe légère et maintenable
##
## @tutorial: Voir BaseEnfer.gd et BaseParadis.gd pour implémentations

# ========================================
# SIGNAUX
# ========================================

## Émis quand la santé change.
signal health_changed(current: int, max_hp: int)

## Émis quand la base est détruite.
signal base_destroyed(winning_team: String)

## Émis quand une unité est spawnée.
signal unit_spawned(unit: Unit)

## Émis quand la base est attaquée.
signal base_under_attack(attacker: Node2D)

## Émis quand une attaque se termine.
signal attack_ended(attacker: Node2D)

## Émis quand l'or change.
signal gold_changed(current: float, max_gold: float)

# ========================================
# PROPRIÉTÉS
# ========================================

## Camp de la base ("enfer" ou "paradis").
@export var team: String = "neutral"

## Points de vie maximum.
@export var max_health: int = 2500

## Référence au joueur propriétaire.
var player: Player = null

# ========================================
# COMPONENTS
# ========================================

var health_component: BaseHealthComponent = null
var spawn_component: BaseSpawnComponent = null
var attack_component: BaseAttackComponent = null
var gold_component: BaseGoldComponent = null

# ========================================
# INITIALISATION
# ========================================

func _ready() -> void:
	# Configuration de base
	add_to_group("bases")
	
	# Setup des components
	_setup_components()
	
	# Connexion des signaux
	_connect_signals()
	
	# Création du joueur
	_setup_player()
	
	print("✅ Base %s initialisée (PV: %d, Or: %.1f)" % [team, max_health, gold_component.get_current_gold() if gold_component else 0.0])


## Configure tous les components de la base.
func _setup_components() -> void:
	# Cherche les components existants
	for child in get_children():
		if child is BaseHealthComponent:
			health_component = child
		elif child is BaseSpawnComponent:
			spawn_component = child
		elif child is BaseAttackComponent:
			attack_component = child
		elif child is BaseGoldComponent:
			gold_component = child
	
	# Si pas de components, crée-les dynamiquement
	if not health_component:
		health_component = BaseHealthComponent.new()
		health_component.name = "HealthComponent"
		health_component.max_health = max_health
		add_child(health_component)
	
	if not spawn_component:
		spawn_component = BaseSpawnComponent.new()
		spawn_component.name = "SpawnComponent"
		add_child(spawn_component)
	
	if not attack_component:
		attack_component = BaseAttackComponent.new()
		attack_component.name = "AttackComponent"
		add_child(attack_component)
	
	if not gold_component:
		gold_component = BaseGoldComponent.new()
		gold_component.name = "GoldComponent"
		add_child(gold_component)


## Connecte les signaux des components aux signaux de la base.
func _connect_signals() -> void:
	if health_component:
		health_component.health_changed.connect(_on_health_changed)
		health_component.base_destroyed.connect(_on_base_destroyed)
	
	if spawn_component:
		spawn_component.unit_spawned.connect(_on_unit_spawned)
	
	if attack_component:
		attack_component.base_under_attack.connect(_on_base_under_attack)
		attack_component.attack_ended.connect(_on_attack_ended)
	
	if gold_component:
		gold_component.gold_changed.connect(_on_gold_changed)


## Crée et configure le joueur de la base.
func _setup_player() -> void:
	var player_id: int = 1 if team == "enfer" else 2
	var player_name: String = "Joueur " + team.capitalize()
	
	player = Player.new(player_id, player_name, team)
	add_child(player)
	
	player.set_camp(team)
	player.base = self
	player.modifier_or(0)  # Initialise à 0


# ========================================
# GESTION DES DÉGÂTS (IDamageable)
# ========================================

## Inflige des dégâts à la base.
##
## @param amount: Montant des dégâts
## @param attacker: Source des dégâts
## @return: true si base détruite
func take_damage(amount: int, attacker: Node2D = null) -> bool:
	if not health_component:
		return false
	
	# Enregistre l'attaquant
	if attacker and attack_component:
		attack_component.register_attacker(attacker)
	
	print("🔥 Base %s prend %d dégâts (PV: %d → %d)" % [
		team, 
		amount, 
		health_component.current_health, 
		health_component.current_health - amount
	])
	
	return health_component.take_damage(amount, attacker)


## Vérifie si une unité peut attaquer la base.
##
## @param unit: Unité à vérifier
## @return: true si peut attaquer
func can_attack_base(unit: Node2D) -> bool:
	if not attack_component:
		return true
	return attack_component.can_attack(unit)


## Vérifie si la base peut accepter plus d'attaquants.
##
## @return: true si place disponible
func attacking_has_room() -> bool:
	if not attack_component:
		return true
	return attack_component.has_room()


## Retire une unité de la liste des attaquants.
##
## @param unit: Unité à retirer
func stop_attacking(unit: Node2D) -> void:
	if attack_component:
		attack_component.unregister_attacker(unit)


## Retourne la santé actuelle.
##
## @return: PV actuels
func get_health() -> int:
	if health_component:
		return health_component.get_health()
	return 0


## Définit la santé directement.
##
## @param value: Nouvelle valeur
func set_health(value: int) -> void:
	if health_component:
		health_component.set_health(value)


# ========================================
# SPAWN D'UNITÉS
# ========================================

## Spawne une unité avec vérification du coût.
##
## @param unit_scene: Scene de l'unité
## @param cost: Coût en or
## @return: Unité créée ou null
func spawn_unit(unit_scene: PackedScene, cost: float) -> Unit:
	if not spawn_component or not gold_component:
		push_error("Base %s: Components manquants pour spawn" % team)
		return null

	print("💰 Tentative spawn pour %s (or: %.1f, coût: %.1f)" % [team, gold_component.get_current_gold(), cost])

	# Vérifie si assez d'or
	if not gold_component.can_spend(cost):
		print("⚠️ Or insuffisant pour %s" % team)
		return null

	# Dépense l'or
	if not gold_component.spend(cost):
		return null

	# Spawne l'unité
	var unit: Unit = await spawn_component.spawn_unit(unit_scene)

	if unit:
		print("✅ Unité spawnée: %s à %s (or restant: %.1f)" % [
			unit.unit_name,
			unit.global_position,
			gold_component.get_current_gold()
		])

	return unit


## Spawne une unité sans vérifier/dépenser l'or (coût déjà payé).
##
## @param unit_scene: Scene de l'unité
## @return: Unité créée ou null
func spawn_unit_no_cost(unit_scene: PackedScene) -> Unit:
	if not spawn_component:
		push_error("Base %s: SpawnComponent manquant" % team)
		return null

	var unit: Unit = await spawn_component.spawn_unit(unit_scene)

	if unit:
		print("✅ Unité spawnée: %s à %s" % [unit.unit_name, unit.global_position])

	return unit


# ========================================
# UTILITAIRES
# ========================================

## Trouve la base ennemie.
##
## @return: Base ennemie ou null
func get_enemy_base() -> Base:
	for base in get_tree().get_nodes_in_group("bases"):
		if base.team != team:
			return base
	return null


## Retourne le camp de la base.
##
## @return: true si Enfer, false si Paradis
func get_side() -> bool:
	return team == "enfer"


# ========================================
# CALLBACKS DES SIGNAUX
# ========================================

func _on_health_changed(current: int, max_hp: int) -> void:
	health_changed.emit(current, max_hp)


func _on_base_destroyed(winning_team: String) -> void:
	base_destroyed.emit(winning_team)


func _on_unit_spawned(unit: Unit) -> void:
	unit_spawned.emit(unit)


func _on_base_under_attack(attacker: Node2D) -> void:
	base_under_attack.emit(attacker)


func _on_attack_ended(attacker: Node2D) -> void:
	attack_ended.emit(attacker)


func _on_gold_changed(current: float, max_gold: float) -> void:
	gold_changed.emit(current, max_gold)
