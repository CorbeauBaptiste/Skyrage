class_name UnitTargetingComponent
extends Node

## Component gérant la détection et le ciblage des ennemis.
##
## Responsabilités :
## - Détecter les ennemis à portée
## - Sélectionner la meilleure cible
## - Maintenir une liste des ennemis proches
##
## @tutorial: Utilisé par Unit pour trouver des cibles automatiquement

## Émis quand un nouvel ennemi est détecté.
## @param enemy: Ennemi détecté
signal enemy_detected(enemy: Node2D)

## Émis quand un ennemi quitte la portée.
## @param enemy: Ennemi qui part
signal enemy_lost(enemy: Node2D)

## Rayon de détection des ennemis.
@export var detection_radius: float = 200.0

## Cible actuelle (peut être Vector2 ou Node2D).
var target: Variant = null

## Ennemi actuellement ciblé.
var current_enemy: Node2D = null

## Liste des ennemis à portée.
var enemies_in_range: Array[Node2D] = []

## Si l'unité attaque une base.
var is_attacking_base: bool = false

## Position de formation pour attaque de base.
var base_attack_position: Vector2 = Vector2.ZERO

## Nodes requis.
var _detection_area: Area2D = null
var _range_area: Area2D = null
var _parent_unit: Node2D = null


func _ready() -> void:
	_parent_unit = get_parent()
	
	_detection_area = _parent_unit.get_node_or_null("Detect")
	_range_area = _parent_unit.get_node_or_null("Range")
	
	if _range_area:
		_range_area.body_entered.connect(_on_enemy_in_range)
		_range_area.body_exited.connect(_on_enemy_out_of_range)
	
	# On attend une frame pour être sûr que tout est bien chargé
	await get_tree().process_frame
	_set_initial_target()


## Définit la base ennemie comme cible initiale.
func _set_initial_target() -> void:
	# Vérification sécurisée de la propriété is_hell_faction
	if not _parent_unit.get("is_hell_faction") is bool:
		print("❌ %s: Parent unit missing is_hell_faction" % _parent_unit.name)
		return
	
	# Debug: Afficher tous les groupes existants
	print("\n🔍 Debug - Groupes disponibles:")
	var group_names = []
	var nodes = _parent_unit.get_tree().get_nodes_in_group("")
	for node in nodes:
		for group in node.get_groups():
			if not group in group_names:
				group_names.append(group)
	print("Groupes trouvés: " + str(group_names))
	
	var bases := _parent_unit.get_tree().get_nodes_in_group("bases")
	print("\n🔍 %s: Found %d bases in scene" % [_parent_unit.name, bases.size()])
	
	# Debug: Afficher des informations sur chaque base trouvée
	for i in bases.size():
		var base = bases[i]
		if not is_instance_valid(base):
			print("  %d. Base invalide (déjà libérée)" % i)
			continue
			
		print("  %d. %s (type: %s, in tree: %s)" % [
			i,
			base.name,
			base.get_class(),
			base.is_inside_tree()
		])
		
		# Afficher les propriétés de la base
		print("     - Team: " + (str(base.get("team")) if base.get("team") != null else "No team property"))
		print("     - Groups: " + str(base.get_groups()))
			
		var base_side = base.get_side() if base.has_method("get_side") else "unknown"
		print("  - Base: %s (side: %s, our side: %s)" % [base.name, base_side, "hell" if _parent_unit.is_hell_faction else "heaven"])
		
		if base.has_method("get_side") and base.get_side() != _parent_unit.is_hell_faction:
			target = base
			print("🎯 %s: Found enemy base target: %s" % [_parent_unit.name, base.name])
			return
	
	print("⚠️ %s: No valid enemy base found!" % _parent_unit.name)


## Trouve la meilleure cible parmi les ennemis à portée.
##
## @return: Node2D de la meilleure cible ou null
func find_best_target() -> Node2D:
	if enemies_in_range.is_empty():
		return null
	
	# Nettoie les références invalides
	enemies_in_range = enemies_in_range.filter(func(e): return is_instance_valid(e))
	
	if enemies_in_range.is_empty():
		return null
	
	# Priorise les unités proches
	var closest: Node2D = null
	var min_distance: float = INF
	
	for enemy in enemies_in_range:
		var distance: float = _parent_unit.global_position.distance_to(enemy.global_position)
		if distance < min_distance:
			min_distance = distance
			closest = enemy
	
	return closest


## Callback quand un ennemi entre à portée.
##
## @param body: Corps qui entre
func _on_enemy_in_range(body: Node2D) -> void:
	if not _is_valid_enemy(body):
		return
	
	if body is Base:
		if not current_enemy or current_enemy == body:
			current_enemy = body
			is_attacking_base = true
			base_attack_position = _parent_unit.global_position
			
			# Notifie la base
			if body.has_method("take_damage"):
				body.take_damage(0, _parent_unit)
	
	elif not current_enemy:
		current_enemy = body
		is_attacking_base = false
	
	if not enemies_in_range.has(body):
		enemies_in_range.append(body)
		enemy_detected.emit(body)


## Callback quand un ennemi sort de portée.
##
## @param body: Corps qui sort
func _on_enemy_out_of_range(body: Node2D) -> void:
	enemies_in_range.erase(body)
	
	if body == current_enemy:
		if body is Base:
			body.stop_attacking(_parent_unit)
			is_attacking_base = false
		
		current_enemy = null
		enemy_lost.emit(body)


## Vérifie si une entité est un ennemi valide.
##
## @param body: Entité à vérifier
## @return: true si ennemi valide
func _is_valid_enemy(body: Node2D) -> bool:
	if not is_instance_valid(body) or body == _parent_unit:
		return false
	
	if not _parent_unit.has("is_hell_faction"):
		return false
	
	if body is Unit:
		return body.is_hell_faction != _parent_unit.is_hell_faction
	
	if body is Base:
		return body.get_side() != _parent_unit.is_hell_faction
	
	return false


## Trouve une cible alternative si la cible actuelle est invalide.
func find_alternative_target() -> void:
	if current_enemy is Base:
		is_attacking_base = true
		return
	
	current_enemy = find_best_target()
	is_attacking_base = false


## Définit manuellement une cible.
##
## @param new_target: Vector2 ou Node2D
func set_target(new_target: Variant) -> void:
	target = new_target


## Retourne la position de la cible actuelle.
##
## @return: Position ou Vector2.ZERO
func get_target_position() -> Vector2:
	if target is Vector2:
		return target
	elif target is Node2D and is_instance_valid(target):
		if not target.is_inside_tree():
			print("⚠️ %s: Target is not in scene tree!" % _parent_unit.name)
			return Vector2.ZERO
		return target.global_position
	else:
		if target != null:
			print("⚠️ %s: Invalid target type: %s" % [_parent_unit.name, typeof(target)])
		return Vector2.ZERO
	return Vector2.ZERO


## Nettoie les ennemis invalides de la liste.
func cleanup_invalid_enemies() -> void:
	enemies_in_range = enemies_in_range.filter(func(e): return is_instance_valid(e))
