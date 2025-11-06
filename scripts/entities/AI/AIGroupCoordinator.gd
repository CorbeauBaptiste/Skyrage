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
	
	if ange_index == 0:
		# Premier ange : utilise sa direction actuelle
		var direction := target_pos.direction_to(ange.global_position)
		return target_pos + direction * ATTACK_DISTANCE
	
	elif ange_index == 1:
		# Deuxième ange : à l'opposé du premier
		var partner = group[0]
		if is_instance_valid(partner) and assigned_positions.has(partner):
			var partner_pos = assigned_positions[partner]
			var partner_direction := target_pos.direction_to(partner_pos)
			var opposite_direction := -partner_direction
			return target_pos + opposite_direction * ATTACK_DISTANCE
	
	return target_pos


func get_attack_position(ange: Unit, target_L: Unit) -> Vector2:
	# Retourne la position FIXE assignée
	if assigned_positions.has(ange):
		return assigned_positions[ange]
	
	# Fallback si pas de position assignée
	return target_L.global_position if target_L else Vector2.ZERO


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
	# Nettoie les unités mortes
	var to_remove := []
	
	for ange in unit_assignments.keys():
		if not is_instance_valid(ange):
			to_remove.append(ange)
	
	for ange in to_remove:
		remove_unit(ange)
	
	# Nettoie les cibles mortes
	var dead_targets := []
	for target in attack_groups.keys():
		if not is_instance_valid(target):
			dead_targets.append(target)
	
	for target in dead_targets:
		if attack_groups.has(target):
			for ange in attack_groups[target]:
				unit_assignments.erase(ange)
				assigned_positions.erase(ange)
			attack_groups.erase(target)
