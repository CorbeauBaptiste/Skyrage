extends Unit

## Diablotin - Unité rapide de l'Enfer (S).
##
## 📋 SPECS :
## - Taille : S (petite, rapide)
## - PV : 600
## - Dégâts : 150
## - Vitesse : 30
## - Portée : 50 (courte, corps à corps)
## - Style : Assaut rapide
##
## 🎯 À IMPLÉMENTER PAR : [NOM_DEV]
## 
## @tutorial: Implémente handle_movement() avec ton comportement custom !

var _spawn_move_time: float = 0.0
const INITIAL_MOVE_DURATION: float = 1.0
var _initial_move_done: bool = false


func _ready() -> void:
	# Configuration des propriétés de base
	unit_name = "Diablotin"
	unit_size = "S"
	max_health = 600
	base_damage = 150
	base_speed = 30.0
	attack_range = 50.0
	attack_cooldown = 1.0
	detection_radius = 200.0
	is_hell_faction = true
	
	# Appel au parent pour terminer l'initialisation
	super._ready()
	
	print("🔥 %s ready at %s" % [unit_name, global_position])


## Implémente le mouvement spécifique du Diablotin
##
## Comportement du Diablotin (unité S rapide) :
## - Fonce droit sur la cible
## - Peut faire des micro-zigzags pour esquiver
## - Utilise bien l'évitement pour pas se bloquer en groupe
##
## @param delta: Temps écoulé depuis la dernière frame
func handle_movement(delta: float) -> void:
	# Vérification des composants nécessaires
	if not movement_component or not targeting_component:
		push_warning("%s: Missing required components" % unit_name)
		velocity = Vector2.ZERO
		return
	
	# Phase 1 : Mouvement initial (1 seconde pour libérer la zone de spawn)
	if not _initial_move_done:
		_spawn_move_time += delta
		
		if _spawn_move_time >= INITIAL_MOVE_DURATION:
			_initial_move_done = true
			velocity = Vector2.ZERO
			print("✅ %s : Mode tourelle activé (position statique)" % unit_name)
			return
		
		# Continue d'avancer pendant la phase initiale
		if targeting_component.target:
			var target_pos: Vector2 = targeting_component.get_target_position()
			if target_pos != Vector2.ZERO:
				var direction: Vector2 = global_position.direction_to(target_pos)
				var avoidance: Vector2 = movement_component.calculate_avoidance()
				var final_direction: Vector2 = (direction + avoidance * 0.6).normalized()
				velocity = final_direction * movement_component.current_speed * movement_component.speed_multiplier
				return
	
	# Phase 2 : Mode statique (ne bouge plus, sauf si le joueur clique)
	# Vérifie si le joueur a assigné une nouvelle cible manuellement
	if targeting_component.target is Vector2:
		# Le joueur a cliqué quelque part, on y va
		var target_pos: Vector2 = targeting_component.target
		var distance: float = global_position.distance_to(target_pos)
		
		# Si on est arrivé à destination, on s'arrête
		if distance < 10.0:
			velocity = Vector2.ZERO
			targeting_component.target = null  # Réinitialise la cible manuelle
			return
		
		# Sinon on y va
		var direction: Vector2 = global_position.direction_to(target_pos)
		var avoidance: Vector2 = movement_component.calculate_avoidance()
		var final_direction: Vector2 = (direction + avoidance * 0.4).normalized()
		velocity = final_direction * movement_component.current_speed * movement_component.speed_multiplier
		return
	
	# Si on a une cible (comme une base ennemie), on s'en approche
	if targeting_component.target:
		var target_pos: Vector2 = targeting_component.get_target_position()
		if target_pos != Vector2.ZERO:
			var distance: float = global_position.distance_to(target_pos)
			if distance > attack_range:  # Ne s'approche que si hors de portée
				var direction: Vector2 = global_position.direction_to(target_pos)
				var avoidance: Vector2 = movement_component.calculate_avoidance()
				var final_direction: Vector2 = (direction + avoidance * 0.5).normalized()
				velocity = final_direction * movement_component.current_speed * movement_component.speed_multiplier
				return
	
	# Si on arrive ici, on s'arrête
	velocity = Vector2.ZERO
	
	# Debug - Print detailed movement info every second
	if Engine.get_frames_drawn() % 60 == 0:  # Every second
		var target_pos = targeting_component.get_target_position() if targeting_component else Vector2.ZERO
		var distance = global_position.distance_to(target_pos) if target_pos != Vector2.ZERO else 0.0
		print("--- %s Debug ---" % unit_name)
		print("Position: %s" % global_position)
		print("Velocity: %s (speed: %.1f)" % [velocity, movement_component.current_speed * movement_component.speed_multiplier])
		print("Target: %s" % ("None" if target_pos == Vector2.ZERO else target_pos))
		print("Distance to target: %.1f (range: %.1f)" % [distance, attack_range])
		print("Initial move done: %s" % _initial_move_done)
		print("Targeting component: %s" % ("Valid" if targeting_component else "Missing"))
		print("Movement component: %s" % ("Valid" if movement_component else "Missing"))
		print("--- End Debug ---")
