class_name Unit
extends CharacterBody2D

## Classe abstraite de base pour toutes les unités du jeu.
##
## ⚠️ IMPORTANT : Chaque unité enfant DOIT override handle_movement(delta).
##
## Architecture par composition :
## - Les components gèrent les comportements (santé, mouvement, combat, etc.)
## - La classe Unit orchestre ces components
## - Chaque unité concrète définit sa propre logique de mouvement
##
## @tutorial: Voir Diablotin.gd, Archange.gd pour exemples d'implémentation

# ========================================
# SIGNAUX
# ========================================

## Émis quand la santé change.
signal health_changed(current: int, max_hp: int)

## Émis quand l'unité meurt.
signal unit_died()

## Émis quand des dégâts sont infligés.
signal damage_dealt(amount: int)

# ========================================
# PROPRIÉTÉS EXPORTÉES
# ========================================

@export_group("Identité")
## Nom de l'unité.
@export var unit_name: String = "Unit"

## Taille de l'unité (S/M/L).
@export_enum("S", "M", "L") var unit_size: String = "M"

## Camp de l'unité (true = Enfer, false = Paradis).
@export var is_hell_faction: bool = false

@export_group("Stats de base")
## Points de vie maximum.
@export var max_health: int = 100

## Dégâts de base.
@export var base_damage: int = 10

## Vitesse de base (px/sec).
@export var base_speed: float = 50.0

## Portée d'attaque.
@export var attack_range: float = 150.0

## Cooldown entre attaques.
@export var attack_cooldown: float = 1.0

## Rayon de détection.
@export var detection_radius: float = 200.0

# ========================================
# VARIABLES D'ÉTAT
# ========================================

## Cible actuelle (Vector2 ou Node2D).
var target: Variant = null

## Si l'unité est sélectionnée.
var selected: bool = false:
	set(value):
		selected = value
		if selection_component:
			selection_component.set_selected(value)

# ========================================
# COMPONENTS
# ========================================

## Référence au sprite
@onready var sprite: Sprite2D = $Sprite2D

## Référence au lecteur d'animations
@onready var anim_player: AnimationPlayer = $AnimationPlayer

## Composants
var health_component: UnitHealthComponent = null
var movement_component: UnitMovementComponent = null
var combat_component: UnitCombatComponent = null
var targeting_component: UnitTargetingComponent = null
var selection_component: UnitSelectionComponent = null

# ========================================
# NODES ENFANTS
# ========================================

# ========================================
# SCENE DE PROJECTILE
# ========================================

var arrow_scene: PackedScene = preload("res://scenes/entities/projectiles/projectile.tscn")

# ========================================
# INITIALISATION
# ========================================

func _ready() -> void:
	print("\n🚀 Unit._ready() called for %s" % unit_name)
	
	# Configuration physique
	collision_layer = 2
	collision_mask = 1  # Collisions uniquement avec le terrain
	add_to_group("units")
	
	# Configuration des composants
	_setup_components()
	_connect_signals()
	_apply_faction_color()
	
	print("\n✅ Unit setup complete for %s" % unit_name)

## Configure les composants de l'unité.
func _setup_components() -> void:
	print("\n🔧 Setting up components for %s" % unit_name)

	# Création des composants s'ils n'existent pas
	health_component = _get_or_create_component("HealthComponent", "res://scripts/entities/units/components/UnitHealthComponent.gd")
	movement_component = _get_or_create_component("MovementComponent", "res://scripts/entities/units/components/UnitMovementComponent.gd")
	combat_component = _get_or_create_component("CombatComponent", "res://scripts/entities/units/components/UnitCombatComponent.gd")
	targeting_component = _get_or_create_component("TargetingComponent", "res://scripts/entities/units/components/UnitTargetingComponent.gd")
	selection_component = _get_or_create_component("SelectionComponent", "res://scripts/entities/units/components/UnitSelectionComponent.gd")
	
	# Configuration des composants
	if health_component and health_component.has_method("setup"):
		health_component.setup({
			"max_health": max_health,
			"current_health": max_health
		})
		
	if movement_component and movement_component.has_method("setup"):
		movement_component.setup({
			"speed": base_speed,
			"acceleration": 10.0,
			"deceleration": 15.0
		})
		
	if combat_component and combat_component.has_method("setup"):
		combat_component.setup({
			"damage": base_damage,
			"attack_range": attack_range,
			"attack_cooldown": attack_cooldown
		})
		
	if targeting_component and targeting_component.has_method("setup"):
		targeting_component.setup({
			"detection_radius": detection_radius,
			"is_hell_faction": is_hell_faction
		})

## Récupère les nodes enfants requis.
func _setup_nodes() -> void:
	sprite = get_node_or_null("Sprite2D")
	anim_player = get_node_or_null("AnimationPlayer")


## Fonction utilitaire pour créer un composant s'il n'existe pas
func _get_or_create_component(component_name: String, script_path: String) -> Node:
	# Vérifie si le composant existe déjà
	var existing = get_node_or_null(component_name)
	if existing:
		print("    ✅ Found existing %s" % component_name)
		return existing
		
	# Crée le composant s'il n'existe pas
	print("    ➕ Creating new %s" % component_name)
	var component = Node.new()
	component.name = component_name
	var script = load(script_path)
	if script:
		component.set_script(script)
	else:
		push_error("Failed to load script: %s" % script_path)
	
	add_child(component)
	return component

## Connecte les signaux des composants.
func _connect_signals() -> void:
	if health_component:
		health_component.health_changed.connect(_on_health_changed)
		health_component.died.connect(_on_died)
	
	if combat_component:
		combat_component.damage_dealt.connect(_on_damage_dealt)


# ========================================
# BOUCLE PRINCIPALE (À NE PAS OVERRIDE)
# ========================================

func _physics_process(delta: float) -> void:
	# Debug: Track physics process execution
	if Engine.get_frames_drawn() % 60 == 0:  # Print every second
		print("\n🔧 %s _physics_process" % unit_name)
		print("Position: %s" % global_position)
		print("Velocity: %s" % velocity)
		print("Components - Health: %s, Movement: %s, Combat: %s, Targeting: %s" % [
			"✅" if health_component else "❌",
			"✅" if movement_component else "❌",
			"✅" if combat_component else "❌",
			"✅" if targeting_component else "❌"
		])

	# 1. Si en train d'attaquer, on ne bouge pas
	if combat_component and combat_component.is_attacking:
		if velocity != Vector2.ZERO:
			print("⚔️ %s: Attacking, stopping movement" % unit_name)
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	# 2. Si un ennemi est détecté ET à portée d'attaque, on combat
	if targeting_component and targeting_component.current_enemy:
		if is_instance_valid(targeting_component.current_enemy):
			# Vérifie si l'ennemi est à portée
			if combat_component and combat_component.is_target_in_range():
				_handle_combat()
				velocity = Vector2.ZERO
				move_and_slide()
				return
			# Sinon, on continue le mouvement normal pour s'approcher
	
	# 3. Appel de la logique de mouvement personnalisée
	handle_movement(delta)
	
	# 4. Application du mouvement
	if velocity != Vector2.ZERO:
		print("🚀 %s: Moving with velocity %s" % [unit_name, velocity])
	move_and_slide()
	
	# Debug: Check if position changed after move_and_slide()
	if Engine.get_frames_drawn() % 60 == 0 and velocity != Vector2.ZERO:
		print("📌 %s: After move_and_slide() - Position: %s" % [unit_name, global_position])
	
	# 5. Animation
	_update_animation()


# ========================================
# MÉTHODE ABSTRAITE (OBLIGATOIRE)
# ========================================

## ⚠️ MÉTHODE ABSTRAITE : Doit être override par toutes les unités enfants.
##
## Définit la logique de mouvement spécifique à chaque type d'unité.
## Utilise les helpers de movement_component (calculate_avoidance, apply_velocity).
##
## @param delta: Temps écoulé depuis la dernière frame
func handle_movement(_delta: float) -> void:
	push_error("%s: handle_movement() must be overridden!" % unit_name)
	# Par défaut, on arrête le mouvement
	if movement_component:
		movement_component.stop()


# ========================================
# SYSTÈME DE COMBAT
# ========================================

## Gère le combat avec l'ennemi actuel.
func _handle_combat() -> void:
	if not combat_component or not targeting_component:
		return
	
	var enemy: Node2D = targeting_component.current_enemy
	
	if not is_instance_valid(enemy):
		targeting_component.current_enemy = null
		return
	
	# Oriente vers l'ennemi
	combat_component.set_target(enemy)
	
	# Attaque si possible
	combat_component.try_attack()


# ========================================
# GESTION DE LA SANTÉ (IDamageable)
# ========================================

## Inflige des dégâts à l'unité.
##
## @param amount: Montant des dégâts
func take_damage(amount: int) -> void:
	if health_component:
		health_component.take_damage(amount)


## Soigne l'unité.
##
## @param amount: Montant de soin
## @return: Montant réellement soigné
func heal(amount: int) -> int:
	if health_component:
		return health_component.heal(amount)
	return 0


## Définit directement la santé.
##
## @param value: Nouvelle valeur de santé
func set_health(value: int) -> void:
	if health_component:
		health_component.set_health(value)


## Retourne la santé actuelle.
##
## @return: PV actuels
func get_health() -> int:
	if health_component:
		return health_component.get_health()
	return 0


## Retourne les PV manquants.
##
## @return: Différence entre max et actuel
func get_missing_health() -> int:
	if health_component:
		return health_component.get_missing_health()
	return 0


# ========================================
# GESTION DU CAMP (ITargetable)
# ========================================

## Retourne le camp de l'unité.
##
## @return: true si Enfer, false si Paradis
func get_side() -> bool:
	return is_hell_faction


## Définit le camp de l'unité.
##
## @param value: true pour Enfer, false pour Paradis
func set_side(value: bool) -> void:
	is_hell_faction = value
	_apply_faction_color()


## Applique la couleur selon le camp.
func _apply_faction_color() -> void:
	if sprite:
		sprite.modulate = Color.RED if is_hell_faction else Color.WHITE


# ========================================
# ANIMATION
# ========================================

## Met à jour l'animation selon la vélocité.
func _update_animation() -> void:
	if not anim_player:
		return
	
	if velocity.length() < 1.0:
		anim_player.stop()
		return
	
	# Détermine la direction principale
	if abs(velocity.x) > abs(velocity.y):
		if velocity.x > 0:
			anim_player.play("running-right")
		else:
			anim_player.play("running-left")
	else:
		if velocity.y > 0:
			anim_player.play("running-down")
		else:
			anim_player.play("running-up")


# ========================================
# CALLBACKS DES SIGNAUX
# ========================================

func _on_health_changed(current: int, max_hp: int) -> void:
	health_changed.emit(current, max_hp)


func _on_damage_dealt(amount: int) -> void:
	damage_dealt.emit(amount)


func _on_died() -> void:
	# Notifie la base si on l'attaquait
	if targeting_component and targeting_component.current_enemy is Base:
		targeting_component.current_enemy.stop_attacking(self)
	
	unit_died.emit()
	queue_free()
