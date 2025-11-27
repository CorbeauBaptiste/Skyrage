extends Node
class_name UnitTargetingComponent

## Component gérant la détection et le ciblage intelligent des ennemis.
##
## PRIORITÉS DE CIBLAGE :
## 1. Base ennemie (objectif principal)
## 2. Unités L sur le chemin (menaces prioritaires)
## 3. Unités S/M à portée (opportunités)
##
## @tutorial: Component de Unit
## @see: Unit, AIController

# ========================================
# SIGNAUX
# ========================================

## Émis quand un ennemi est détecté.
signal enemy_detected(enemy: Node2D)

## Émis quand un ennemi quitte la portée.
signal enemy_lost(enemy: Node2D)

# ========================================
# PROPRIÉTÉS
# ========================================

## Rayon de détection.
@export var detection_radius: float = 200.0

## Cible actuelle (Vector2 ou Node2D).
var target: Variant = null

## Si la cible est un ordre manuel du joueur.
var manual_order: bool = false

## Ennemi actuellement ciblé.
var current_enemy: Node2D = null

## Liste des ennemis à portée.
var enemies_in_range: Array[Node2D] = []

## Si l'unité attaque une base.
var is_attacking_base: bool = false

# ========================================
# RÉFÉRENCES INTERNES
# ========================================

var _detection_area: Area2D = null
var _range_area: Area2D = null
var _parent_unit: Node2D = null

# ========================================
# INITIALISATION
# ========================================

func _ready() -> void:
	_parent_unit = get_parent()
	
	_range_area = _parent_unit.get_node_or_null("Range")
	_detection_area = _parent_unit.get_node_or_null("Detect")
	
	if not _range_area:
		push_error("UnitTargetingComponent: Range Area2D manquante sur %s" % _parent_unit.name)
		return
	
	# Connexion des signaux
	_range_area.body_entered.connect(_on_enemy_in_range)
	_range_area.body_exited.connect(_on_enemy_out_of_range)
	
	# Configuration initiale
	var tree := get_tree()
	if tree:
		await tree.process_frame
		await tree.process_frame
	_set_initial_target()


## Définit la base ennemie comme cible initiale.
func _set_initial_target() -> void:
	if not is_instance_valid(_parent_unit) or not (_parent_unit is Unit):
		return

	if not _parent_unit.is_inside_tree():
		return

	var parent_side: bool = (_parent_unit as Unit).is_hell_faction

	for base in _parent_unit.get_tree().get_nodes_in_group("bases"):
		if is_instance_valid(base) and base is Base and base.get_side() != parent_side:
			target = base
			manual_order = false
			return

# ========================================
# CIBLAGE INTELLIGENT
# ========================================

## Trouve la cible prioritaire selon les règles tactiques.
##
## RÈGLES :
## 1. Unité L plus proche que la base → PRIORITÉ HAUTE
## 2. Unité S/M dans Range → PRIORITÉ MOYENNE
## 3. Base ennemie → OBJECTIF PAR DÉFAUT
##
## @return: Cible prioritaire ou null
func find_priority_target() -> Node2D:
	if not is_instance_valid(_parent_unit) or not (_parent_unit is Unit):
		return null

	if not _parent_unit.is_inside_tree():
		return null

	var unit := _parent_unit as Unit
	var unit_side := unit.is_hell_faction
	var my_pos := unit.global_position

	# Trouve la base ennemie
	var enemy_base: Base = null
	var distance_to_base := INF

	for base in unit.get_tree().get_nodes_in_group("bases"):
		if is_instance_valid(base) and base is Base and base.get_side() != unit_side:
			enemy_base = base
			distance_to_base = my_pos.distance_to(base.global_position)
			break
	
	# Cherche les unités ennemies
	var closest_large: Unit = null
	var distance_to_large := INF

	var closest_small_medium: Unit = null
	var distance_to_small_medium := INF
	
	for enemy_unit in unit.get_tree().get_nodes_in_group("units"):
		if not is_instance_valid(enemy_unit) or not (enemy_unit is Unit):
			continue
		
		if enemy_unit == unit or (enemy_unit as Unit).is_hell_faction == unit_side:
			continue
		
		var distance := my_pos.distance_to(enemy_unit.global_position)
		var enemy_typed := enemy_unit as Unit
		
		# Unités L (priorité haute)
		if enemy_typed.unit_size == "L" and distance < distance_to_large:
			distance_to_large = distance
			closest_large = enemy_typed

		# Unités S/M (priorité moyenne, seulement si dans Range)
		elif enemy_typed.unit_size in ["S", "M"] and enemies_in_range.has(enemy_unit):
			if distance < distance_to_small_medium:
				distance_to_small_medium = distance
				closest_small_medium = enemy_typed
	
	# ========================================
	# LOGIQUE DE PRIORITÉ
	# ========================================
	
	# 1. Unité L plus proche que la base
	if closest_large and distance_to_large < distance_to_base:
		print("[Priorité] %s cible unité L : %s (%.0fpx vs base %.0fpx)" % [
			unit.unit_name, closest_large.unit_name, distance_to_large, distance_to_base
		])
		return closest_large

	# 2. Unité S/M dans Range
	if closest_small_medium:
		print("[Priorité] %s cible unité S/M : %s (%.0fpx)" % [
			unit.unit_name, closest_small_medium.unit_name, distance_to_small_medium
		])
		return closest_small_medium
	
	# 3. Base ennemie par défaut
	if enemy_base:
		return enemy_base
	
	return null


## Trouve la meilleure cible parmi les ennemis à portée.
##
## @deprecated: Utilisez find_priority_target() à la place
## @return: Cible prioritaire
func find_best_target() -> Node2D:
	return find_priority_target()

# ========================================
# CALLBACKS DE DÉTECTION
# ========================================

## Callback quand un ennemi entre à portée.
##
## @param body: Corps détecté
func _on_enemy_in_range(body: Node2D) -> void:
	if not is_instance_valid(_parent_unit) or not _parent_unit.is_inside_tree():
		return

	if body == _parent_unit or not _is_valid_enemy(body):
		return
	
	if not enemies_in_range.has(body):
		enemies_in_range.append(body)
		enemy_detected.emit(body)
	
	# Recalcule la cible prioritaire
	var new_target := find_priority_target()
	if new_target != current_enemy:
		current_enemy = new_target
		is_attacking_base = (current_enemy is Base)
		
		if current_enemy is Base and current_enemy.has_method("take_damage"):
			current_enemy.take_damage(0, _parent_unit)


## Callback quand un ennemi sort de portée.
##
## @param body: Corps qui sort
func _on_enemy_out_of_range(body: Node2D) -> void:
	if not is_instance_valid(_parent_unit) or not _parent_unit.is_inside_tree():
		return

	if body == _parent_unit:
		return
	
	enemies_in_range.erase(body)
	
	# Si on perd notre cible actuelle, recalcule
	if body == current_enemy:
		if body is Base:
			body.stop_attacking(_parent_unit)
		
		current_enemy = find_priority_target()
		is_attacking_base = (current_enemy is Base)
		
		if not current_enemy:
			enemy_lost.emit(body)


## Vérifie si une entité est un ennemi valide.
##
## @param body: Entité à vérifier
## @return: true si ennemi valide
func _is_valid_enemy(body: Node2D) -> bool:
	if not is_instance_valid(body) or body == _parent_unit:
		return false

	if not is_instance_valid(_parent_unit) or not (_parent_unit is Unit):
		return false

	var parent_side: bool = (_parent_unit as Unit).is_hell_faction
	
	if body is Unit:
		return (body as Unit).is_hell_faction != parent_side
	
	if body is Base:
		return (body as Base).get_side() != parent_side
	
	return false

# ========================================
# ORDRES MANUELS
# ========================================

## Définit manuellement une cible (ordre du joueur).
##
## @param new_target: Vector2 ou Node2D
func set_target(new_target: Variant) -> void:
	target = new_target
	manual_order = true


## Vérifie si l'unité a un ordre manuel.
##
## @return: true si ordre manuel actif
func has_manual_order() -> bool:
	return manual_order and target != null


## Supprime l'ordre manuel.
func clear_manual_order() -> void:
	manual_order = false


## Retourne la position de la cible actuelle.
##
## @return: Position ou Vector2.ZERO
func get_target_position() -> Vector2:
	if target is Vector2:
		return target
	elif target is Node2D and is_instance_valid(target):
		if target.is_inside_tree():
			return target.global_position
	return Vector2.ZERO

# ========================================
# MAINTENANCE
# ========================================

## Nettoie les ennemis invalides de la liste.
func cleanup_invalid_enemies() -> void:
	enemies_in_range = enemies_in_range.filter(func(e): return is_instance_valid(e))


## Trouve une cible alternative.
func find_alternative_target() -> void:
	current_enemy = find_priority_target()
	is_attacking_base = (current_enemy is Base)
