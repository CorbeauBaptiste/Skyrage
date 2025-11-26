class_name BaseSpawnComponent
extends Node

## Component gérant le spawn d'unités depuis une base.
##
## Responsabilités :
## - Spawner des unités
## - Gérer les positions de spawn
## - Appliquer des offsets aléatoires
##
## @tutorial: Utilisé par Base pour créer des unités

## Émis quand une unité est spawnée.
## @param unit: Unité créée
signal unit_spawned(unit: Unit)

## Offset aléatoire maximum pour le spawn.
@export var spawn_random_offset: float = 50.0

## Délai entre spawns multiples (secondes).
@export var spawn_delay: float = 0.15

## Référence à la base parente.
var _parent_base: Node2D = null

## Node de spawn (SpawnPoint, SpawnPointEnfer, SpawnPointParadis).
var _spawn_point: Node2D = null


func _ready() -> void:
	_parent_base = get_parent()
	_find_spawn_point()


## Trouve le node de spawn approprié.
func _find_spawn_point() -> void:
	if not _parent_base:
		return
	
	var spawn_node_name := "SpawnPoint"
	
	# Vérifie si la base a une propriété team
	if "team" in _parent_base:
		match _parent_base.team:
			"enfer":
				spawn_node_name = "SpawnPointEnfer"
			"paradis":
				spawn_node_name = "SpawnPointParadis"
	
	_spawn_point = _parent_base.get_node_or_null(spawn_node_name)


## Spawne une unité.
##
## @param unit_scene: Scene de l'unité à créer
## @return: Unité créée ou null
func spawn_unit(unit_scene: PackedScene) -> Unit:
	if not unit_scene:
		push_error("BaseSpawnComponent: unit_scene is null")
		return null
	
	var spawn_pos := _get_spawn_position()
	var unit := unit_scene.instantiate() as Unit

	if not unit:
		push_error("BaseSpawnComponent: Failed to instantiate unit")
		return null

	# Position avec offset aléatoire
	var random_offset := Vector2(
		randf_range(-spawn_random_offset, spawn_random_offset),
		randf_range(-spawn_random_offset, spawn_random_offset)
	)
	var target_pos := spawn_pos + random_offset

	# Clamp dans les limites de la map
	const MAP_BOUNDS := Rect2(50, 50, 1820, 980)
	target_pos.x = clamp(
		target_pos.x,
		MAP_BOUNDS.position.x,
		MAP_BOUNDS.position.x + MAP_BOUNDS.size.x
	)
	target_pos.y = clamp(
		target_pos.y,
		MAP_BOUNDS.position.y,
		MAP_BOUNDS.position.y + MAP_BOUNDS.size.y
	)

	unit.global_position = target_pos

	# Configuration camp
	if _parent_base.team != null:
		unit.is_hell_faction = (_parent_base.team == "enfer")

	# Désactiver le traitement pendant le spawn
	unit.collision_layer = 0
	unit.collision_mask = 0
	unit.components_ready = false

	# Ajouter au monde
	_parent_base.get_parent().add_child(unit)
	unit.add_to_group("units")

	# Attendre que les components soient initialisés
	await unit.get_tree().process_frame

	# Réactiver les collisions
	unit.collision_layer = 2
	unit.collision_mask = 3

	# Désactiver temporairement l'évitement d'obstacles
	var obstacle_was_enabled := false
	if unit.movement_component:
		obstacle_was_enabled = unit.movement_component.obstacle_avoidance_enabled
		unit.movement_component.obstacle_avoidance_enabled = false

	# Configurer le ciblage
	var enemy_base := _get_enemy_base()
	if enemy_base and unit.targeting_component:
		unit.targeting_component.target = enemy_base

	# Activer le traitement
	unit.components_ready = true

	# Réactiver l'évitement d'obstacles
	await unit.get_tree().process_frame
	if unit.movement_component and obstacle_was_enabled:
		unit.movement_component.obstacle_avoidance_enabled = true
	
	unit_spawned.emit(unit)
	
	return unit


## Spawne plusieurs unités avec délai.
##
## @param unit_scene: Scene de l'unité
## @param count: Nombre d'unités à spawner
func spawn_multiple(unit_scene: PackedScene, count: int) -> void:
	for i in range(count):
		await spawn_unit(unit_scene)

		if i < count - 1:
			await get_tree().create_timer(spawn_delay).timeout


## Retourne la position de spawn.
##
## @return: Position globale de spawn
func _get_spawn_position() -> Vector2:
	if _spawn_point:
		return _spawn_point.global_position
	
	# Fallback : position de la base avec offset selon le camp
	if _parent_base and _parent_base.has("team"):
		var offset_x := 50.0 if _parent_base.team == "enfer" else -50.0
		return _parent_base.global_position + Vector2(offset_x, 0)
	
	return _parent_base.global_position if _parent_base else Vector2.ZERO


## Trouve la base ennemie.
##
## @return: Base ennemie ou null
func _get_enemy_base() -> Base:
	if not _parent_base or _parent_base.team == null:
		return null
	
	for base in _parent_base.get_tree().get_nodes_in_group("bases"):
		if base.team != _parent_base.team:
			return base
	
	return null
