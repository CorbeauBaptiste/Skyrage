class_name ItemSpawnSystem
extends Node

signal item_collected(item: Item, position: Vector2)

@export var spawn_interval: float = 5.0
@export var min_distance_between_items: float = 32.0
@export var grid_size: int = 64
@export var item_texture: Texture2D

const ITEM_SPRITE_SCALE := Vector2(0.1, 0.1)
const ITEM_FADE_DURATION := 0.5
const ITEM_COLLECTION_DISTANCE := 25.0
const ITEM_VERTICAL_OFFSET := -8
const COLLISION_CHECK_RADIUS := 30.0
const MAX_SPAWN_ATTEMPTS := 100
const ITEM_Z_INDEX := 50
const DECORATION_MARGIN_RADIUS := 1

# Coordonnées des tuiles jouables
const PLAYABLE_TILE_COORDS := [
	Vector2i(0, 6),   # Herbe
	Vector2i(8, 2),   # Sol
	Vector2i(12, 2),  # Sol
]

# ==============================
# 🧩 VARIABLES INTERNES
# ==============================
var item_manager: ItemManager
var spawned_items: Dictionary = {}  # position -> item
var spawn_timer: Timer

@onready var tilemap_sol: TileMapLayer
@onready var tilemap_decoration: TileMapLayer


func _init() -> void:
	item_manager = ItemManager.new()


func setup(sol_layer: TileMapLayer, decoration_layer: TileMapLayer, texture: Texture2D = null) -> void:
	"""
	Configure le système avec les bonnes TileMaps
	Args:
		sol_layer: Layer du sol
		decoration_layer: Layer des décorations
		texture: Texture optionnelle pour les items
	"""
	tilemap_sol = sol_layer
	tilemap_decoration = decoration_layer
	
	if texture:
		item_texture = texture
	
	_setup_timer()


func _setup_timer() -> void:
	"""Crée et démarre le timer de spawn automatique"""
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.autostart = true
	add_child(spawn_timer)


func _on_spawn_timer_timeout() -> void:
	"""Callback du timer : tente de spawner un item"""
	spawn_random_item()


func spawn_random_item() -> void:
	"""Génère un item aléatoire à une position valide"""
	var item := item_manager.get_random_item()
	if not item:
		push_warning("Aucun item disponible pour le spawn")
		return
	
	var spawn_position := _get_random_valid_position()
	if spawn_position != Vector2.ZERO:
		_create_item_sprite(item, spawn_position)
	else:
		push_warning("Impossible de trouver une position de spawn valide")


func _get_random_valid_position() -> Vector2:
	"""
	Trouve une position valide aléatoire pour spawner un item
	Returns: Position valide ou Vector2.ZERO si aucune trouvée
	"""
	if not tilemap_sol or not tilemap_decoration:
		push_error("TileMaps non configurée")
		return Vector2.ZERO
	
	var used_cells := tilemap_sol.get_used_cells()
	if used_cells.is_empty():
		return Vector2.ZERO
	
	# Filtrage des cellules jouables et bloquées
	var playable_cells := _filter_border_tiles(used_cells)
	var blocked_cells := _get_decoration_cells_with_collision()
	
	# Génération des positions possibles
	var possible_positions := _generate_possible_positions(playable_cells, blocked_cells)
	
	return _select_random_valid_position(possible_positions)


func _generate_possible_positions(playable_cells: Array, blocked_cells: Array) -> Array:
	"""
	Génère toutes les positions possibles basées sur les cellules jouables
	Returns: Array de Vector2 avec les positions possibles
	"""
	var positions := []
	
	# Convertir blocked_cells en Set pour recherche plus rapide
	var blocked_set := {}
	for blocked_cell in blocked_cells:
		blocked_set[blocked_cell] = true
	
	for cell in playable_cells:
		if blocked_set.has(cell):
			continue
		
		# Conversion cellule -> position monde (gère l'isométrique automatiquement)
		var local_pos := tilemap_sol.map_to_local(cell)
		var world_pos := tilemap_sol.to_global(local_pos)
		
		world_pos += Vector2(0, ITEM_VERTICAL_OFFSET)
		
		positions.append(world_pos)
	
	return _remove_duplicates(positions)


func _select_random_valid_position(possible_positions: Array) -> Vector2:
	"""
	Sélectionne aléatoirement une position valide parmi les positions possibles
	Returns: Position valide ou Vector2.ZERO
	"""
	for attempt in range(MAX_SPAWN_ATTEMPTS):
		if possible_positions.is_empty():
			return Vector2.ZERO
		
		var pos: Vector2 = possible_positions[randi() % possible_positions.size()]
		
		# Vérification 1 : Collision avec StaticBody2D
		if _has_static_collision_at_position(pos):
			continue
		
		# Vérification 2 : Distance minimale avec autres items
		if not _is_position_valid(pos):
			continue
		
		# Vérification 3 : Distance minimale avec les décorations (world space)
		if not _is_far_enough_from_decorations(pos):
			continue
		
		return pos
	
	return Vector2.ZERO


func _is_far_enough_from_decorations(world_pos: Vector2) -> bool:
	"""
	Vérifie que la position est suffisamment éloignée des décorations
	Returns: true si assez loin
	"""
	const MIN_DISTANCE := 50.0
	
	var decoration_cells := tilemap_decoration.get_used_cells()
	
	for cell in decoration_cells:
		var tile_data := tilemap_decoration.get_cell_tile_data(cell)
		if tile_data and tile_data.get_collision_polygons_count(0) > 0:
			var decoration_local := tilemap_decoration.map_to_local(cell)
			var decoration_world := tilemap_decoration.to_global(decoration_local)
			
			if world_pos.distance_to(decoration_world) < MIN_DISTANCE:
				return false
	
	return true


func _filter_border_tiles(cells: Array) -> Array:
	"""
	Garde uniquement les tuiles de terrain jouables (pas de bordure)
	Returns: Array des cellules jouables
	"""
	var playable := []
	
	for cell in cells:
		var tile_data := tilemap_sol.get_cell_tile_data(cell)
		if not tile_data:
			continue
		
		var atlas_coords := tilemap_sol.get_cell_atlas_coords(cell)
		if atlas_coords in PLAYABLE_TILE_COORDS:
			playable.append(cell)
	
	return playable


func _get_decoration_cells_with_collision() -> Array:
	"""
	Récupère toutes les cellules de décoration avec collision
	Returns: Array des cellules bloquées
	"""
	var blocked_cells := []
	var decoration_cells := tilemap_decoration.get_used_cells()
	
	for cell in decoration_cells:
		var tile_data := tilemap_decoration.get_cell_tile_data(cell)
		if tile_data and tile_data.get_collision_polygons_count(0) > 0:
			blocked_cells.append(cell)
			
			for x in range(-DECORATION_MARGIN_RADIUS, DECORATION_MARGIN_RADIUS + 1):
				for y in range(-DECORATION_MARGIN_RADIUS, DECORATION_MARGIN_RADIUS + 1):
					var offset := Vector2i(x, y)
					if offset.length() <= DECORATION_MARGIN_RADIUS:
						blocked_cells.append(cell + offset)
	
	return blocked_cells


func _is_position_valid(position: Vector2) -> bool:
	"""
	Vérifie si une position est valide (distance minimale avec autres items)
	Returns: true si valide
	"""
	for existing_pos in spawned_items.keys():
		if position.distance_to(existing_pos) < min_distance_between_items:
			return false
	return true


func _has_static_collision_at_position(world_pos: Vector2) -> bool:
	"""
	Vérifie s'il y a une collision statique à cette position
	Returns: true si collision détectée
	"""
	var world := tilemap_sol.get_world_2d()
	if not world:
		return false
	
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = COLLISION_CHECK_RADIUS
	
	query.shape = shape
	query.transform = Transform2D(0, world_pos)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.collision_mask = 1
	
	for collision in world.direct_space_state.intersect_shape(query, 32):
		if collision.collider is StaticBody2D:
			return true
	
	return false


func _create_item_sprite(item: Item, position: Vector2) -> void:
	"""
	Crée le sprite visuel de l'item
	"""
	var sprite := Sprite2D.new()
	sprite.texture = item_texture
	sprite.position = position
	sprite.scale = ITEM_SPRITE_SCALE
	sprite.z_index = ITEM_Z_INDEX
	
	sprite.set_meta("item", item)
	sprite.set_meta("spawn_position", position)
	
	spawned_items[position] = item
	sprite.modulate.a = 0.0
	add_child(sprite)
	
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 1.0, ITEM_FADE_DURATION)


func check_collection(units: Array) -> void:
	"""
	Vérifie si des unités sont proches d'items pour les ramasser
	Args:
		units: Array des unités à vérifier
	"""
	for unit in units:
		if unit == null:
			continue
			
		for item_pos in spawned_items.keys():
			if unit.global_position.distance_to(item_pos) < ITEM_COLLECTION_DISTANCE:
				_collect_item(item_pos)
				return


func _collect_item(item_pos: Vector2) -> void:
	"""
	Collecte un item et émet un signal
	Args:
		item_pos: Position de l'item à collecter
	"""
	if not spawned_items.has(item_pos):
		return
	
	var item: Item = spawned_items[item_pos]
	spawned_items.erase(item_pos)
	
	# Suppression du sprite
	for child in get_children():
		if child is Sprite2D and child.has_meta("spawn_position"):
			if child.get_meta("spawn_position") == item_pos:
				child.queue_free()
				break
	
	item_collected.emit(item, item_pos)


func clear_all_items() -> void:
	"""Supprime tous les items spawnés"""
	for child in get_children():
		if child is Sprite2D:
			child.queue_free()
	spawned_items.clear()


func _remove_duplicates(arr: Array) -> Array:
	"""
	Supprime les doublons dans un Array
	Returns: Array sans doublons
	"""
	var seen := {}
	var unique := []
	
	for v in arr:
		if not seen.has(v):
			seen[v] = true
			unique.append(v)
	
	return unique
