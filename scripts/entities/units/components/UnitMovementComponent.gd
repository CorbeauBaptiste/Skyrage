class_name UnitMovementComponent
extends Node

## Component fournissant des utilitaires de mouvement pour les unités.
##
## ⚠️ NE GÈRE PAS la logique de mouvement ! Chaque Unit doit override handle_movement().
##
## Responsabilités :
## - Fournir des helpers pour le calcul d'évitement
## - Stocker la vitesse et ses multiplicateurs
## - Appliquer la velocity au CharacterBody2D
##
## @tutorial: Utilisé par les Units dans leur handle_movement() custom

## Vitesse de base de l'unité (px/sec).
@export var base_speed: float = 50.0

## Rayon d'évitement des autres unités.
@export var avoidance_radius: float = 30.0

## Poids de l'évitement dans le calcul final.
@export_range(0.0, 1.0) var avoidance_weight: float = 0.5

@export_group("Évitement d'obstacles")
## Nombre de rayons pour la détection d'obstacles.
@export var obstacle_ray_count: int = 9

## Angle de dispersion des rayons (en degrés).
@export var obstacle_ray_spread_deg: float = 60.0

## Distance de détection des obstacles (px).
@export var obstacle_check_distance: float = 50.0

## Masque de collision pour les obstacles.
@export var obstacle_collision_mask: int = 1

## Force du burst d'évitement (multiplicateur de vitesse).
@export var obstacle_avoid_strength: float = 1.15

## Angle de rotation lors de l'évitement (degrés).
@export var obstacle_avoid_angle_deg: float = 35.0

## Durée du burst d'évitement (secondes).
@export var obstacle_steer_burst_time: float = 0.12

## Durée maximale d'un burst d'évitement (timeout).
@export var obstacle_burst_max_duration: float = 0.5

## Active l'évitement d'obstacles.
@export var obstacle_avoidance_enabled: bool = true

## Vitesse actuelle (peut être modifiée par buffs/debuffs).
var current_speed: float = 50.0

## Multiplicateur de vitesse (items, buffs).
var speed_multiplier: float = 1.0

## Référence au CharacterBody2D parent.
var _body: CharacterBody2D = null

## Timer pour le burst d'évitement d'obstacles.
var _obstacle_steer_timer: float = 0.0

## Vélocité du burst d'évitement.
var _obstacle_steer_velocity: Vector2 = Vector2.ZERO

## Temps total écoulé dans le burst actuel.
var _total_burst_time: float = 0.0


func _ready() -> void:
	current_speed = base_speed
	_body = get_parent() as CharacterBody2D
	
	if not _body:
		push_error("MovementComponent must be child of CharacterBody2D")


## HELPER: Calcule le vecteur d'évitement des unités proches.
##
## @return: Vecteur d'évitement normalisé (à combiner avec direction de mouvement)
func calculate_avoidance() -> Vector2:
	if not _body or not _body.is_inside_tree():
		return Vector2.ZERO

	var avoidance := Vector2.ZERO
	var nearby_count := 0
	var my_pos := _body.global_position
	var radius_sq := avoidance_radius * avoidance_radius

	for unit in _body.get_tree().get_nodes_in_group("units"):
		if unit == _body or not is_instance_valid(unit):
			continue

		var unit_node := unit as Node2D
		if not unit_node:
			continue

		var diff: Vector2 = unit_node.global_position - my_pos
		var dist_sq: float = diff.length_squared()

		# Utilise distance_squared pour éviter sqrt coûteux
		if dist_sq < radius_sq and dist_sq > 0.01:
			var distance := sqrt(dist_sq)  # sqrt seulement si nécessaire
			var push_strength := 1.0 - (distance / avoidance_radius)
			avoidance -= diff.normalized() * push_strength
			nearby_count += 1

	if nearby_count > 0:
		avoidance = avoidance.normalized()

	return avoidance


## HELPER: Applique une vélocité finale au CharacterBody2D.
##
## À appeler depuis handle_movement() après avoir calculé la direction.
##
## @param direction: Direction finale du mouvement (normalisée)
func apply_velocity(direction: Vector2) -> void:
	if not _body:
		return
	
	_body.velocity = direction.normalized() * current_speed * speed_multiplier


## HELPER: Arrête le mouvement (met velocity à zéro).
func stop() -> void:
	if _body:
		_body.velocity = Vector2.ZERO


## Met à jour la vitesse de base (pour buffs/debuffs).
##
## @param new_speed: Nouvelle vitesse de base
func set_base_speed(new_speed: float) -> void:
	current_speed = new_speed


## Réinitialise la vitesse à la valeur de base.
func reset_speed() -> void:
	current_speed = base_speed
	speed_multiplier = 1.0


## Retourne la vitesse effective actuelle.
##
## @return: Vitesse en px/sec
func get_effective_speed() -> float:
	return current_speed * speed_multiplier


# ========================================
# ÉVITEMENT D'OBSTACLES (RAYCASTING)
# ========================================

## Lance les rayons pour détecter les obstacles devant l'unité.
##
## @param dir_ref: Direction de référence pour le lancer de rayons
## @return: Dictionnaire avec infos sur les collisions détectées
func _check_obstacle_rays(dir_ref: Vector2) -> Dictionary:
	if not _body:
		return {"any_hit": false}

	var space_state := _body.get_world_2d().direct_space_state
	var any_hit := false
	var left_hit := false
	var right_hit := false
	var left_hits_count := 0
	var right_hits_count := 0
	var nearest_left_t := INF
	var nearest_right_t := INF
	var half_spread: float = deg_to_rad(obstacle_ray_spread_deg) * 0.5

	for i in range(obstacle_ray_count):
		var ti: float = 0.5 if obstacle_ray_count == 1 else float(i) / float(obstacle_ray_count - 1)
		var angle: float = lerp(-half_spread, half_spread, ti)
		var rdir: Vector2 = dir_ref.rotated(angle)
		var to_global: Vector2 = _body.global_position + rdir * obstacle_check_distance

		var q := PhysicsRayQueryParameters2D.new()
		q.from = _body.global_position
		q.to = to_global
		q.exclude = [_body]
		q.collision_mask = obstacle_collision_mask

		var res: Dictionary = space_state.intersect_ray(q)
		var hit: bool = (res.size() > 0)

		if hit:
			any_hit = true
			var hit_pos: Vector2 = (res.get("position", _body.global_position) as Vector2)
			var hit_dist: float = (hit_pos - _body.global_position).length()
			var hit_t: float = clamp(hit_dist / max(obstacle_check_distance, 0.001), 0.0, 1.0)

			if angle < 0.0:
				left_hit = true
				left_hits_count += 1
				if hit_t < nearest_left_t:
					nearest_left_t = hit_t
			else:
				right_hit = true
				right_hits_count += 1
				if hit_t < nearest_right_t:
					nearest_right_t = hit_t

	return {
		"any_hit": any_hit,
		"left_hit": left_hit,
		"right_hit": right_hit,
		"left_hits_count": left_hits_count,
		"right_hits_count": right_hits_count,
		"nearest_left_t": nearest_left_t,
		"nearest_right_t": nearest_right_t
	}


## Calcule la direction d'évitement d'obstacles.
##
## @param desired_direction: Direction souhaitée du mouvement
## @return: true si un obstacle a été détecté et l'évitement est actif
func calculate_obstacle_avoidance(desired_direction: Vector2) -> bool:
	if not obstacle_avoidance_enabled or not _body:
		return false

	var hit_info := _check_obstacle_rays(desired_direction)

	if not hit_info.any_hit:
		return false

	# Détermine le sens de rotation
	var sign_dir := 0
	if hit_info.left_hit and not hit_info.right_hit:
		sign_dir = 1  # Tourne à droite
	elif hit_info.right_hit and not hit_info.left_hit:
		sign_dir = -1  # Tourne à gauche
	else:
		# Les deux côtés touchés : choisir le côté le plus dégagé
		if hit_info.nearest_left_t < hit_info.nearest_right_t - 0.02:
			sign_dir = 1  # Droite plus dégagée
		elif hit_info.nearest_right_t < hit_info.nearest_left_t - 0.02:
			sign_dir = -1  # Gauche plus dégagée
		elif hit_info.left_hits_count != hit_info.right_hits_count:
			sign_dir = 1 if hit_info.left_hits_count > hit_info.right_hits_count else -1
		else:
			sign_dir = -1 if desired_direction.x >= 0.0 else 1

	# Calcule la direction d'évitement avec boost de vitesse
	var angle := deg_to_rad(sign_dir * obstacle_avoid_angle_deg)
	var avoid_dir := desired_direction.rotated(angle).normalized()
	_obstacle_steer_velocity = avoid_dir * current_speed * obstacle_avoid_strength
	_obstacle_steer_timer = obstacle_steer_burst_time

	return true


## Applique la vélocité avec évitement d'obstacles et d'unités.
##
## @param direction: Direction souhaitée du mouvement
## @param delta: Temps écoulé depuis la dernière frame
## @param include_unit_avoidance: Inclure l'évitement des autres unités
func apply_velocity_with_avoidance(
	direction: Vector2,
	delta: float,
	include_unit_avoidance: bool = true
) -> void:
	if not _body:
		return

	# Si en burst d'évitement, vérifier timeout
	if _obstacle_steer_timer > 0.0:
		_total_burst_time += delta

		# Timeout : sortie forcée du burst
		if _total_burst_time > obstacle_burst_max_duration:
			_obstacle_steer_timer = 0.0
			_total_burst_time = 0.0
			_obstacle_steer_velocity = Vector2.ZERO
		else:
			# Continue le burst normalement
			_obstacle_steer_timer -= delta
			_body.velocity = _obstacle_steer_velocity
			return
	else:
		# Reset compteur si pas en burst
		_total_burst_time = 0.0

	# Vérifie les obstacles devant
	var dir_normalized := direction.normalized()
	if dir_normalized == Vector2.ZERO:
		stop()
		return

	# Si obstacle détecté, on lance un burst d'évitement
	if calculate_obstacle_avoidance(dir_normalized):
		_body.velocity = _obstacle_steer_velocity
		return

	# Pas d'obstacle : mouvement normal avec évitement des unités
	var final_direction := dir_normalized
	if include_unit_avoidance:
		var unit_avoidance := calculate_avoidance()
		final_direction = (dir_normalized + unit_avoidance * avoidance_weight).normalized()

	_body.velocity = final_direction * current_speed * speed_multiplier


## Retourne true si l'unité est actuellement en train d'éviter un obstacle.
func is_avoiding_obstacle() -> bool:
	return _obstacle_steer_timer > 0.0


## Réinitialise le timer d'évitement d'obstacles.
func reset_obstacle_avoidance() -> void:
	_obstacle_steer_timer = 0.0
	_obstacle_steer_velocity = Vector2.ZERO
