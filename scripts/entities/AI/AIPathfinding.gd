extends Node
class_name AIPathfinding

const WALKABLE_TILE_COORDS := [
	Vector2i(0, 6),
	Vector2i(8, 2),
	Vector2i(12, 2),
]

# Cache statique partagé entre toutes les instances
static var _shared_obstacles: Dictionary = {}
static var _obstacles_loaded: bool = false

var unit: Unit
var astar: AStar

var current_path: Array[Vector2] = []
var current_waypoint_index := 0

var waypoint_reached_distance := 25.0
var path_recalculation_time := 2.0
var recalculation_timer := 0.0
var direct_movement_threshold := 300.0
var _last_delta := 0.016  # Pour l'évitement d'obstacles


func _ready() -> void:
	unit = get_parent() as Unit
	if not unit:
		push_error("[AIPathfinding] Doit être enfant d'une Unit")
		queue_free()
		return

	astar = AStar.new()
	astar.cell_size = Vector2(32, 16)
	astar.isometric = true
	add_child(astar)

	await get_tree().process_frame
	_load_obstacles_from_tilemaps()


func _process(delta: float) -> void:
	recalculation_timer += delta
	_last_delta = delta


func move_towards_target(target_pos: Vector2) -> void:
	if not _is_valid():
		return

	var distance_to_target := unit.global_position.distance_to(target_pos)
	
	if distance_to_target < direct_movement_threshold:
		_move_direct(target_pos)
		return

	if _should_recalculate_path(target_pos):
		_calculate_path(target_pos)
		recalculation_timer = 0.0

	if current_path.is_empty():
		_move_direct(target_pos)
		return

	_follow_path()


func _should_recalculate_path(_target_pos: Vector2) -> bool:
	if current_path.is_empty():
		return true
	
	if recalculation_timer >= path_recalculation_time:
		return true

	if current_waypoint_index < current_path.size():
		var next_point := current_path[current_waypoint_index]
		if unit.global_position.distance_to(next_point) > astar.cell_size.x * 3.0:
			return true

	return false


func _calculate_path(target: Vector2) -> void:
	if not astar:
		return

	var start := unit.global_position
	current_path = astar.find_path(start, target)
	current_waypoint_index = 0

	if not current_path.is_empty():
		current_path = _smooth_path(current_path)


func _smooth_path(path: Array[Vector2]) -> Array[Vector2]:
	if path.size() <= 2:
		return path
	
	var smoothed: Array[Vector2] = []
	smoothed.append(path[0])
	
	var i := 0
	while i < path.size() - 1:
		var current := path[i]
		var farthest := i + 1
		
		for j in range(i + 2, min(i + 10, path.size())):
			if _is_line_clear(current, path[j]):
				farthest = j
		
		if farthest != i:
			smoothed.append(path[farthest])
			i = farthest
		else:
			i += 1
	
	if smoothed.back() != path.back():
		smoothed.append(path.back())
	
	return smoothed


func _is_line_clear(from: Vector2, to: Vector2) -> bool:
	var space := unit.get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(from, to)
	query.collision_mask = 1
	query.exclude = [unit]
	
	var result := space.intersect_ray(query)
	return result.is_empty()


func _follow_path() -> void:
	if current_waypoint_index >= current_path.size():
		current_path.clear()
		return

	var waypoint := current_path[current_waypoint_index]
	var distance := unit.global_position.distance_to(waypoint)

	if distance < waypoint_reached_distance:
		current_waypoint_index += 1
		if current_waypoint_index >= current_path.size():
			current_path.clear()
			return
		waypoint = current_path[current_waypoint_index]

	var direction := unit.global_position.direction_to(waypoint)
	unit.movement_component.apply_velocity_with_avoidance(direction, _last_delta)


func _move_direct(target_pos: Vector2) -> void:
	var direction := unit.global_position.direction_to(target_pos)
	unit.movement_component.apply_velocity_with_avoidance(direction, _last_delta)


func _is_valid() -> bool:
	return unit and is_instance_valid(unit) and unit.movement_component


func _load_obstacles_from_tilemaps() -> void:
	# Si les obstacles sont déjà chargés globalement, on les réutilise
	if _obstacles_loaded:
		astar.obstacles = _shared_obstacles
		return

	var world_node = unit.get_tree().root.get_node_or_null("Level")
	if not world_node:
		return

	var tilemap_sol: TileMapLayer = world_node.get_node_or_null("TileMap/Sol")
	var tilemap_decoration: TileMapLayer = world_node.get_node_or_null("TileMap/Decoration")

	if not tilemap_sol:
		return

	var bases = unit.get_tree().get_nodes_in_group("bases")
	var base_exclusion_zones: Array[Rect2] = []

	for base in bases:
		if is_instance_valid(base):
			var exclusion_zone = Rect2(
				base.global_position - Vector2(300, 300),
				Vector2(600, 600)
			)
			base_exclusion_zones.append(exclusion_zone)

	var tilemap_offset := tilemap_sol.global_position

	# Ajoute obstacles SOL
	for cell in tilemap_sol.get_used_cells():
		var atlas := tilemap_sol.get_cell_atlas_coords(cell)
		if atlas not in WALKABLE_TILE_COORDS:
			var local_pos := tilemap_sol.map_to_local(cell)
			var global_pos := local_pos + tilemap_offset

			var in_exclusion_zone := false
			for zone in base_exclusion_zones:
				if zone.has_point(global_pos):
					in_exclusion_zone = true
					break

			if not in_exclusion_zone:
				astar.add_obstacle(global_pos)

	# Ajoute obstacles DECORATION
	if tilemap_decoration:
		var deco_offset := tilemap_decoration.global_position

		for cell in tilemap_decoration.get_used_cells():
			var tile_data := tilemap_decoration.get_cell_tile_data(cell)
			if tile_data and tile_data.get_collision_polygons_count(0) > 0:
				var local_pos := tilemap_decoration.map_to_local(cell)
				var global_pos := local_pos + deco_offset

				var in_exclusion_zone := false
				for zone in base_exclusion_zones:
					if zone.has_point(global_pos):
						in_exclusion_zone = true
						break

				if not in_exclusion_zone:
					_add_obstacle_with_margin(global_pos, 1)

	# Sauvegarde dans le cache statique partagé
	_shared_obstacles = astar.obstacles
	_obstacles_loaded = true
	print("[Pathfinding] Obstacles chargés: %d (partagés entre toutes les unités)" % astar.get_obstacle_count())


func _add_obstacle_with_margin(world_pos: Vector2, margin_radius: int = 1) -> void:
	astar.add_obstacle(world_pos)

	if margin_radius <= 0:
		return

	var w := astar.cell_size.x
	var h := astar.cell_size.y

	for x in range(-margin_radius, margin_radius + 1):
		for y in range(-margin_radius, margin_radius + 1):
			if x == 0 and y == 0:
				continue
			if sqrt(x * x + y * y) <= margin_radius:
				var offset_world := world_pos + Vector2(x * w * 0.5, y * h * 0.5)
				astar.add_obstacle(offset_world)
