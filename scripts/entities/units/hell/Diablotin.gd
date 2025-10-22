extends Unit

## Diablotin - Unité rapide de l'Enfer (S).
##
## SPECS :
## - Taille : S (petite, rapide)
## - PV : 600
## - Dégâts : 150
## - Vitesse : 30
## - Portée : 50 (courte, corps à corps)
## - Style : Assaut rapide

var _spawn_move_time: float = 0.0
const INITIAL_MOVE_DURATION: float = 1.0
var _initial_move_done: bool = false


func _ready() -> void:
	# ⚠️ IMPORTANT : Définir les propriétés AVANT super._ready()
	unit_name = "Diablotin"
	unit_size = "S"
	max_health = 600
	base_damage = 150
	base_speed = 30.0
	attack_range = 50.0
	attack_cooldown = 1.0
	detection_radius = 200.0
	is_hell_faction = true
	
	# Appel au parent pour initialiser les components
	super._ready()
	
	print("🔥 %s ready at %s" % [unit_name, global_position])


## Implémente le mouvement spécifique du Diablotin
##
## Comportement :
## - Phase 1 (1 sec) : Avance pour sortir de la zone de spawn
## - Phase 2 : Reste statique (mode tourelle)
## - Peut se déplacer si le joueur clique sur une position
##
## @param delta: Temps écoulé depuis la dernière frame
func handle_movement(delta: float) -> void:
	if not movement_component or not targeting_component:
		push_warning("%s: Missing required components" % unit_name)
		velocity = Vector2.ZERO
		return
	
	# Phase 1 : Mouvement initial (sortir de la zone de spawn)
	if not _initial_move_done:
		_spawn_move_time += delta
		
		if _spawn_move_time >= INITIAL_MOVE_DURATION:
			_initial_move_done = true
			velocity = Vector2.ZERO
			print("✅ %s : Phase 1 terminée (position statique)" % unit_name)
			return
		
		# Avance vers la cible initiale
		if targeting_component.target:
			var target_pos: Vector2 = targeting_component.get_target_position()
			if target_pos != Vector2.ZERO:
				var direction: Vector2 = global_position.direction_to(target_pos)
				var avoidance: Vector2 = movement_component.calculate_avoidance()
				var final_direction: Vector2 = (direction + avoidance * 0.6).normalized()
				velocity = final_direction * movement_component.get_effective_speed()
				return
	
	# Phase 2 : Mode statique
	# Vérifie si le joueur a cliqué pour donner un ordre de déplacement manuel
	if targeting_component.target is Vector2:
		var target_pos: Vector2 = targeting_component.target
		var distance: float = global_position.distance_to(target_pos)
		
		# Arrivé à destination
		if distance < 10.0:
			velocity = Vector2.ZERO
			targeting_component.target = null
			return
		
		# Se déplace vers la position cliquée
		var direction: Vector2 = global_position.direction_to(target_pos)
		var avoidance: Vector2 = movement_component.calculate_avoidance()
		var final_direction: Vector2 = (direction + avoidance * 0.4).normalized()
		velocity = final_direction * movement_component.get_effective_speed()
		return
	
	# Si on a une cible (base ennemie), s'en approcher si hors de portée
	if targeting_component.target:
		var target_pos: Vector2 = targeting_component.get_target_position()
		if target_pos != Vector2.ZERO:
			var distance: float = global_position.distance_to(target_pos)
			if distance > attack_range:
				var direction: Vector2 = global_position.direction_to(target_pos)
				var avoidance: Vector2 = movement_component.calculate_avoidance()
				var final_direction: Vector2 = (direction + avoidance * 0.5).normalized()
				velocity = final_direction * movement_component.get_effective_speed()
				return
	
	# Par défaut : immobile
	velocity = Vector2.ZERO
