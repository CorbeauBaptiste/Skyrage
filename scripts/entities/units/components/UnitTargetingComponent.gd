class_name UnitTargetingComponent
extends Node

## Component gérant la détection et le ciblage des ennemis.
##
## Responsabilités :
## - Détecter les ennemis à portée
## - Sélectionner la meilleure cible
## - Maintenir une liste des ennemis proches
## - Distinguer ordres manuels vs cibles automatiques
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

## Si la cible est un ordre manuel du joueur (sinon c'est une cible automatique).
var manual_order: bool = false

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
	
	if not _range_area:
		push_error("UnitTargetingComponent: Range Area2D manquante sur %s" % _parent_unit.name)
		return
	
	if not _detection_area:
		push_warning("UnitTargetingComponent: Detect Area2D manquante sur %s" % _parent_unit.name)
	
	# Connexion des signaux
	_range_area.body_entered.connect(_on_enemy_in_range)
	_range_area.body_exited.connect(_on_enemy_out_of_range)
	
	# Attendre que tout soit chargé
	await get_tree().process_frame
	await get_tree().process_frame
	_set_initial_target()


## Définit la base ennemie comme cible initiale.
func _set_initial_target() -> void:
	## Définit la base ennemie comme cible initiale (automatique, pas manuelle).
	if not _parent_unit or not is_instance_valid(_parent_unit):
		return
	
	if not (_parent_unit is Unit):
		return
	
	var parent_side: bool = _parent_unit.is_hell_faction
	var bases := _parent_unit.get_tree().get_nodes_in_group("bases")
	
	for base in bases:
		if not is_instance_valid(base) or not base.is_inside_tree():
			continue
		
		if not (base is Base):
			continue
			
		var base_side: bool = base.get_side()
		
		if base_side != parent_side:
			target = base
			manual_order = false  # Cible automatique
			return


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
	## Callback quand un ennemi entre à portée.
	if not _is_valid_enemy(body):
		return
	
	if not enemies_in_range.has(body):
		enemies_in_range.append(body)
		enemy_detected.emit(body)
	
	if body is Base:
		current_enemy = body
		is_attacking_base = true
		
		target = body
		manual_order = false  # Base = cible automatique
		
		if body.has_method("take_damage"):
			body.take_damage(0, _parent_unit)
	
	elif body is Unit:
		if not current_enemy:
			current_enemy = body
			is_attacking_base = false
			print("🎯 %s cible %s" % [_parent_unit.unit_name, body.unit_name])


## Callback quand un ennemi sort de portée.
##
## @param body: Corps qui sort
func _on_enemy_out_of_range(body: Node2D) -> void:
	## Callback quand un ennemi sort de portée.
	enemies_in_range.erase(body)
	
	if body == current_enemy:
		if body is Base:
			body.stop_attacking(_parent_unit)
			is_attacking_base = false
		
		# Cherche une nouvelle cible
		current_enemy = find_best_target()
		
		# Met à jour le flag selon la nouvelle cible
		if current_enemy is Base:
			is_attacking_base = true
		else:
			is_attacking_base = false
		
		if not current_enemy:
			enemy_lost.emit(body)
			print("❌ %s perd sa cible" % _parent_unit.unit_name)
		else:
			print("🔄 %s change de cible" % _parent_unit.unit_name)


## Vérifie si une entité est un ennemi valide.
##
## @param body: Entité à vérifier
## @return: true si ennemi valide
func _is_valid_enemy(body: Node2D) -> bool:
	## Vérifie si une entité est un ennemi valide.
	if not is_instance_valid(body) or body == _parent_unit:
		return false
	
	if not (_parent_unit is Unit):
		return false
	
	var parent_side: bool = _parent_unit.is_hell_faction
	
	if body is Unit:
		return body.is_hell_faction != parent_side
	
	if body is Base:
		return body.get_side() != parent_side
	
	return false


## Trouve une cible alternative si la cible actuelle est invalide.
func find_alternative_target() -> void:
	if current_enemy is Base:
		is_attacking_base = true
		return
	
	current_enemy = find_best_target()
	is_attacking_base = false


## Définit manuellement une cible (ordre du joueur).
##
## @param new_target: Vector2 ou Node2D
func set_target(new_target: Variant) -> void:
	target = new_target
	manual_order = true  # Ordre manuel du joueur


## Vérifie si l'unité a un ordre manuel.
##
## @return: true si ordre manuel du joueur
func has_manual_order() -> bool:
	return manual_order and target != null


## Supprime l'ordre manuel (arrivé à destination).
func clear_manual_order() -> void:
	manual_order = false


## Retourne la position de la cible actuelle.
##
## @return: Position ou Vector2.ZERO
func get_target_position() -> Vector2:
	## Retourne la position de la cible actuelle.
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
