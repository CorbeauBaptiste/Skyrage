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
	
	# Attendre 2 frames pour que tout soit chargé
	await get_tree().process_frame
	await get_tree().process_frame
	_set_initial_target()


## Définit la base ennemie comme cible initiale.
func _set_initial_target() -> void:
	if not _parent_unit:
		return
	
	# ✅ CORRECTION : Utiliser get() au lieu de has()
	var parent_faction = _parent_unit.get("is_hell_faction")
	if parent_faction == null:
		print("⚠️ %s: Parent unit missing is_hell_faction" % name)
		return
	
	var parent_side: bool = parent_faction
	var bases := _parent_unit.get_tree().get_nodes_in_group("bases")
	
	print("🔍 %s: Searching enemy base (I'm %s, found %d bases)" % [
		_parent_unit.get("unit_name") if _parent_unit.get("unit_name") else "Unit",
		"hell" if parent_side else "heaven",
		bases.size()
	])
	
	for base in bases:
		if not is_instance_valid(base) or not base.is_inside_tree():
			continue
			
		if base.has_method("get_side"):
			var base_side: bool = base.get_side()
			print("  - Base %s: side=%s" % [base.name, "hell" if base_side else "heaven"])
			
			if base_side != parent_side:
				target = base
				var unit_name = _parent_unit.get("unit_name") if _parent_unit.get("unit_name") else "Unit"
				print("✅ %s: Target set to %s" % [unit_name, base.name])
				return
	
	var unit_name = _parent_unit.get("unit_name") if _parent_unit.get("unit_name") else "Unit"
	print("❌ %s: No enemy base found!" % unit_name)


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
	
	# ✅ CORRECTION : Utiliser get() au lieu de has()
	var parent_faction = _parent_unit.get("is_hell_faction")
	if parent_faction == null:
		return false
	
	if body is Unit:
		var body_faction = body.get("is_hell_faction")
		if body_faction == null:
			return false
		return body_faction != parent_faction
	
	if body is Base:
		return body.get_side() != parent_faction
	
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
			return Vector2.ZERO
		return target.global_position
	return Vector2.ZERO


## Nettoie les ennemis invalides de la liste.
func cleanup_invalid_enemies() -> void:
	enemies_in_range = enemies_in_range.filter(func(e): return is_instance_valid(e))
