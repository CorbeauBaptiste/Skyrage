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
# SIGNALS
# ========================================

## Émis quand la santé change.
signal health_changed(current: int, max_hp: int)

## Émis quand l'unité meurt.
signal unit_died()

## Émis quand des dégâts sont infligés.
signal damage_dealt(amount: int)

# ========================================
# EXPORTED PROPERTIES
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

@export_group("Comportement")

## Si l'unité peut attaquer (false = seulement se déplacer)
@export var can_attack: bool = true

# ========================================
# STATES VARIABLES
# ========================================

## Cible actuelle (Vector2 ou Node2D).
var target: Variant = null

## Si l'unité est sélectionnée.
var selected: bool = false:
	set(value):
		selected = value
		if selection_component:
			selection_component.set_selected(value)

## Si les components sont prêts.
var components_ready: bool = false

## Si l'unité est contrôlée par le joueur (true) ou par l'IA (false).
@export var is_player_unit: bool = false

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
var item_effect_component: UnitItemEffectComponent = null

# ========================================
# PROJECTILE SCENES
# ========================================

var arrow_scene: PackedScene = preload("res://scenes/entities/projectiles/projectile.tscn")

# ========================================
# INITIALISATION
# ========================================

func _ready() -> void:
	# Configuration physique
	collision_layer = 2
	collision_mask = 1
	add_to_group("units")
	
	# Setup des nodes
	_setup_nodes()
	
	# Setup différé pour laisser les enfants définir leurs propriétés
	call_deferred("_deferred_setup")

## Setup différé exécuté après que les classes enfants aient configuré leurs valeurs
func _deferred_setup() -> void:
	_setup_components()
	_connect_signals()
	_apply_faction_color()
	
	# Synchronise le flag d'attaque
	if combat_component:
		combat_component.is_enabled = can_attack
	
	# Marquer les components comme prêts
	components_ready = true

## Configure les composants de l'unité.
func _setup_components() -> void:
	# Création des composants avec leurs vrais types
	health_component = _create_component("HealthComponent", UnitHealthComponent)
	movement_component = _create_component("MovementComponent", UnitMovementComponent)
	combat_component = _create_component("CombatComponent", UnitCombatComponent)
	targeting_component = _create_component("TargetingComponent", UnitTargetingComponent)
	selection_component = _create_component("SelectionComponent", UnitSelectionComponent)
	item_effect_component = _create_component("ItemEffectComponent", UnitItemEffectComponent)
	
	await get_tree().process_frame
	
	if health_component:
		health_component.max_health = max_health
		health_component.current_health = max_health
		
	if movement_component:
		movement_component.base_speed = base_speed
		movement_component.current_speed = base_speed
		
	if combat_component:
		combat_component.base_damage = base_damage
		combat_component.current_damage = base_damage
		combat_component.attack_range = attack_range
		combat_component.attack_cooldown = attack_cooldown
		
	if targeting_component:
		targeting_component.detection_radius = detection_radius

## Crée un component avec le bon type
func _create_component(component_name: String, component_type) -> Node:
	var existing := get_node_or_null(component_name)
	if existing:
		return existing
		
	var component = component_type.new()
	component.name = component_name
	add_child(component)
	return component

## Récupère les nodes enfants requis.
func _setup_nodes() -> void:
	sprite = get_node_or_null("Sprite2D")
	anim_player = get_node_or_null("AnimationPlayer")

## Connecte les signaux des composants.
func _connect_signals() -> void:
	if health_component:
		health_component.health_changed.connect(_on_health_changed)
		health_component.died.connect(_on_died)
	
	if combat_component:
		combat_component.damage_dealt.connect(_on_damage_dealt)

# ========================================
# MAIN LOOP
# ========================================

func _physics_process(delta: float) -> void:
	## Boucle principale (à ne pas override).
	##
	## Gère automatiquement les ordres de mouvement via targeting_component.target.
	if not components_ready:
		return
	
	# 1. Si en train d'attaquer, on ne bouge pas
	if combat_component and combat_component.is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	# 2. Mise à jour du ciblage
	if targeting_component:
		# Priorité 1 : Ennemi détecté
		if targeting_component.current_enemy and is_instance_valid(targeting_component.current_enemy):
			# Vérifie si l'unité peut attaquer
			if can_attack:
				# Annuler l'ordre manuel si on a trouvé un ennemi
				if targeting_component.manual_order:
					targeting_component.clear_manual_order()
				
				if combat_component:
					var distance := global_position.distance_to(targeting_component.current_enemy.global_position)
					
					# Pas de marge pour les unités, grande marge pour les bases
					var effective_range := combat_component.attack_range
					
					if targeting_component.current_enemy is Base:
						effective_range += 160.0
					
					if distance <= effective_range:
						# À portée : on attaque
						_handle_combat()
						velocity = Vector2.ZERO
						move_and_slide()
						return
					else:
						# Pas à portée : on s'approche de l'ennemi
						var direction := global_position.direction_to(targeting_component.current_enemy.global_position)
						if movement_component:
							movement_component.apply_velocity_with_avoidance(direction, delta)
						else:
							velocity = direction.normalized() * base_speed

						move_and_slide()
						_update_animation()
						return
			else:
				# Si ne peut pas attaquer, ignore l'ennemi détecté
				# et continue le comportement normal (ordre manuel ou handle_movement)
				pass
		
		# Priorité 2 : Ordre manuel du joueur (seulement si pas d'ennemi OU si can_attack = false)
		if targeting_component.has_manual_order():
			var target_pos := targeting_component.get_target_position()
			if target_pos != Vector2.ZERO:
				var distance := global_position.distance_to(target_pos)
				
				# Si on est arrivé (< 20px), on supprime l'ordre
				if distance < 20.0:
					targeting_component.clear_manual_order()
					velocity = Vector2.ZERO
					move_and_slide()
					return
				
				# Sinon on se déplace vers la cible
				var direction := global_position.direction_to(target_pos)
				if movement_component:
					movement_component.apply_velocity_with_avoidance(direction, delta)
				else:
					velocity = direction.normalized() * base_speed

				move_and_slide()
				_update_animation()
				return
	
	# 3. Pas d'ennemi à portée et pas d'ordre : on laisse handle_movement() gérer
	handle_movement(delta)
	
	# 4. Application du mouvement
	move_and_slide()
	
	# 5. Animation
	_update_animation()

# ========================================
# ABSTRACT METHODE
# ========================================

## ⚠️ MÉTHODE ABSTRAITE : Doit être override par toutes les unités enfants.
##
## Définit la logique de mouvement spécifique à chaque type d'unité.
## Utilise les helpers de movement_component (calculate_avoidance, apply_velocity).
##
## NOTE: Cette méthode n'est appelée QUE si l'unité n'a ni ennemi ni ordre de mouvement.
## Gère le déplacement de base de l'unité
##
## @param delta: Temps écoulé depuis la dernière frame
func handle_movement(delta: float) -> void:
	# Si on a un movement_component, on l'utilise
	if movement_component and is_instance_valid(movement_component):
		# Si on a une vélocité non nulle, on l'applique avec évitement
		if velocity != Vector2.ZERO:
			movement_component.apply_velocity_with_avoidance(velocity.normalized(), delta)
		else:
			movement_component.stop()
	else:
		# Fallback si pas de movement_component
		if velocity != Vector2.ZERO:
			move_and_slide()

# ========================================
# FIGHT SYSTEM
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
# HEALTH GESTION (IDamageable)
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
# TEAM GESTION (ITargetable)
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

## Active ou désactive les attaques de cette unité
func set_can_attack(value: bool) -> void:
	can_attack = value
	if combat_component:
		combat_component.is_enabled = value

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
# SIGNALS CALLBACKS
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
