extends Node
class_name AIGroupCoordinator

# Singleton pour coordonner les groupes d'unités
static var instance: AIGroupCoordinator = null

# Structure : { unit_L: [ange1, ange2], ... }
var attack_groups: Dictionary = {}

# Structure : { ange: unit_L, ... }
var unit_assignments: Dictionary = {}

# Structure : { ange: Vector2, ... } - Position fixe assignée
var assigned_positions: Dictionary = {}

# Distance minimale entre deux anges du même groupe
const MIN_SEPARATION_DISTANCE := 80.0

# Distance d'attaque autour de la cible
const ATTACK_DISTANCE := 150.0


func _init() -> void:
	if instance == null:
		instance = self


static func get_instance() -> AIGroupCoordinator:
	if instance == null:
		instance = AIGroupCoordinator.new()
	return instance


func assign_to_target(ange: Unit, target_L: Unit) -> void:
	# Si l'ange était déjà assigné ailleurs, le retirer
	if unit_assignments.has(ange):
		var old_target = unit_assignments[ange]
		if attack_groups.has(old_target):
			attack_groups[old_target].erase(ange)
			if attack_groups[old_target].is_empty():
				attack_groups.erase(old_target)
		assigned_positions.erase(ange)
	
	# Si le groupe pour cette cible n'existe pas, le créer
	if not attack_groups.has(target_L):
		attack_groups[target_L] = []
	
	# Ajouter l'ange au groupe (max 2)
	if attack_groups[target_L].size() < 2:
		attack_groups[target_L].append(ange)
		unit_assignments[ange] = target_L
		
		# CALCULE ET FIXE la position d'attaque maintenant
		var attack_pos := _calculate_fixed_position(ange, target_L)
		assigned_positions[ange] = attack_pos
		
	else:
		print("[Groupe] Groupe plein pour %s, cherche autre cible" % target_L.unit_name)


func _calculate_fixed_position(ange: Unit, target_L: Unit) -> Vector2:
	var group = attack_groups[target_L]
	var ange_index = group.find(ange)
	var target_pos := target_L.global_position

	var candidate_pos := target_pos

	if ange_index == 0:
		# Premier ange : utilise sa direction actuelle
		var direction := target_pos.direction_to(ange.global_position)
		candidate_pos = target_pos + direction * ATTACK_DISTANCE

	elif ange_index == 1:
		# Deuxième ange : à l'opposé du premier
		var partner = group[0]
		if is_instance_valid(partner) and assigned_positions.has(partner):
			var partner_pos = assigned_positions[partner]
			var partner_direction := target_pos.direction_to(partner_pos)
			var opposite_direction := -partner_direction
			candidate_pos = target_pos + opposite_direction * ATTACK_DISTANCE

	# Valide que la position est accessible (pas dans un mur)
	if _is_position_blocked(ange, candidate_pos):
		# Si bloquée, essaie d'autres directions
		candidate_pos = _find_valid_attack_position(ange, target_pos)

	return candidate_pos


func _is_position_blocked(ange: Unit, pos: Vector2) -> bool:
	if not is_instance_valid(ange) or not ange.is_inside_tree():
		return true

	var space := ange.get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(ange.global_position, pos)
	query.collision_mask = 1  # Layer des obstacles
	query.exclude = [ange]

	var result := space.intersect_ray(query)
	return not result.is_empty()


func _find_valid_attack_position(ange: Unit, target_pos: Vector2) -> Vector2:
	# Essaie 8 directions autour de la cible
	var angles := [0.0, 45.0, 90.0, 135.0, 180.0, 225.0, 270.0, 315.0]

	for angle in angles:
		var direction := Vector2.RIGHT.rotated(deg_to_rad(angle))
		var candidate := target_pos + direction * ATTACK_DISTANCE

		if not _is_position_blocked(ange, candidate):
			return candidate

	# Si tout est bloqué, retourne la position de l'ange (il reste sur place)
	return ange.global_position


func get_attack_position(ange: Unit, target_L: Unit) -> Vector2:
	if not is_instance_valid(target_L):
		return ange.global_position if is_instance_valid(ange) else Vector2.ZERO

	# Vérifie si la cible a bougé significativement (> 100px de la position assignée)
	if assigned_positions.has(ange):
		var assigned_pos: Vector2 = assigned_positions[ange]
		var target_distance := assigned_pos.distance_to(target_L.global_position)

		# Si la cible est trop loin de notre position assignée, recalculer
		if target_distance > ATTACK_DISTANCE + 50.0:
			var new_pos := _calculate_fixed_position(ange, target_L)
			assigned_positions[ange] = new_pos
			return new_pos

		return assigned_pos

	# Fallback si pas de position assignée
	return target_L.global_position


func is_in_formation(ange: Unit, target_L: Unit) -> bool:
	if not assigned_positions.has(ange):
		return false
	
	var desired_pos = assigned_positions[ange]
	var current_pos := ange.global_position
	
	# Considère en formation si à moins de 40px de la position voulue
	return current_pos.distance_to(desired_pos) < 40.0


func get_partner(ange: Unit) -> Unit:
	if not unit_assignments.has(ange):
		return null
	
	var target : Variant = unit_assignments[ange]
	if not attack_groups.has(target):
		return null
	
	var group = attack_groups[target]
	for other in group:
		if other != ange and is_instance_valid(other):
			return other
	
	return null


func remove_unit(ange: Unit) -> void:
	if unit_assignments.has(ange):
		var target = unit_assignments[ange]
		if attack_groups.has(target):
			attack_groups[target].erase(ange)
			if attack_groups[target].is_empty():
				attack_groups.erase(target)
		unit_assignments.erase(ange)
		assigned_positions.erase(ange)


func cleanup_dead_units() -> void:
	# Nettoie les unités mortes - on ne peut pas appeler remove_unit() car l'objet est freed
	# On doit nettoyer directement les dictionnaires
	var dead_anges := []

	for ange in unit_assignments.keys():
		if not is_instance_valid(ange):
			dead_anges.append(ange)

	for ange in dead_anges:
		var target = unit_assignments.get(ange)
		if target and attack_groups.has(target):
			attack_groups[target].erase(ange)
			if attack_groups[target].is_empty():
				attack_groups.erase(target)
		unit_assignments.erase(ange)
		assigned_positions.erase(ange)

	# Nettoie les cibles mortes
	var dead_targets := []
	for target in attack_groups.keys():
		if not is_instance_valid(target):
			dead_targets.append(target)

	for target in dead_targets:
		if attack_groups.has(target):
			for ange in attack_groups[target]:
				if is_instance_valid(ange):
					unit_assignments.erase(ange)
					assigned_positions.erase(ange)
			attack_groups.erase(target)
