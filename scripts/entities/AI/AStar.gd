extends Node
class_name AStar

## Implémentation algorithmique pure d'A* (A-Star).
## Adaptée pour cartes isométriques (stacked) avec cell_size.x = tile_width, cell_size.y = tile_height
## Conserve la structure et API originales.

# ========================================
# CLASSE NODE (NOEUD)
# ========================================

class PathNode:
	var position: Vector2
	var g_cost: float = INF
	var h_cost: float = 0.0
	var f_cost: float = INF
	var parent: PathNode = null

	func _init(pos: Vector2):
		position = pos

	func calculate_f_cost() -> void:
		f_cost = g_cost + h_cost

# ========================================
# CACHE
# ========================================

# Cache des chemins calculés
var _path_cache: Dictionary = {}
const MAX_CACHE_SIZE: int = 100  # Nombre maximum de chemins en cache

# ========================================
# CONFIGURATION
# ========================================

# cell_size.x = tile width (px), cell_size.y = tile height (px)
# Par défaut configuré pour ton cas : 32x16 (isometric stacked)
var cell_size: Vector2 = Vector2(32.0, 16.0)

# Si true, on utilisera les conversions isométriques (stacked). Sinon comportement "orthogonal" original.
var isometric: bool = true

# Liste des positions d'obstacles (en coordonnées grille Vector2i).
var obstacles: Array[Vector2i] = []

# Limite d'itérations pour éviter boucle infinie.
var max_iterations: int = 10000

# ========================================
# ALGORITHME A*
# ========================================

func find_path(start: Vector2, goal: Vector2) -> Array[Vector2]:
	# Vérifie le cache d'abord
	var cache_key = _get_cache_key(start, goal)
	if cache_key in _path_cache:
		return _path_cache[cache_key].duplicate()

	# Convertit en coordonnées grille (Vector2i)
	var start_grid := _world_to_grid(start)
	var goal_grid := _world_to_grid(goal)
	
	# Initialise les listes
	var open_list: Array[PathNode] = []
	var closed_list: Array[PathNode] = []
	
	# Crée le nœud de départ (position en monde = centre de case)
	var start_node := PathNode.new(_grid_to_world(start_grid))
	start_node.g_cost = 0
	start_node.h_cost = _heuristic(start_node.position, _grid_to_world(goal_grid))
	start_node.calculate_f_cost()
	
	open_list.append(start_node)
	
	var iterations := 0
	
	while open_list.size() > 0 and iterations < max_iterations:
		iterations += 1
		
		# 1. Trouve le nœud avec le plus petit f_cost
		var current := _get_lowest_f_cost_node(open_list)
		
		# 2. Vérifie si on est arrivé (comparé aux centres, seuil adaptatif)
		if _is_goal_reached(current.position, _grid_to_world(goal_grid)):
			var path = _retrace_path(start_node, current)
			_cache_path(cache_key, path)
			return path
		
		# 3. Déplace de open à closed
		open_list.erase(current)
		closed_list.append(current)
		
		# 4. Explore les voisins (sur la grille)
		for neighbor_grid in _get_neighbor_cells(_world_to_grid(current.position)):
			# Ignore si obstacle
			if _is_obstacle_at_grid(neighbor_grid):
				continue
			
			var neighbor_world := _grid_to_world(neighbor_grid)
			
			# Ignore si déjà dans closed
			if _is_in_closed_list(closed_list, neighbor_world):
				continue
			
			# Calcule le nouveau g_cost (distance réelle entre centres)
			var tentative_g_cost := current.g_cost + _calculate_movement_cost(current.position, neighbor_world)
			
			# Trouve ou crée le nœud voisin
			var neighbor_node := _find_or_create_node(open_list, neighbor_world)
			
			# Si nouveau chemin plus court
			if tentative_g_cost < neighbor_node.g_cost:
				neighbor_node.parent = current
				neighbor_node.g_cost = tentative_g_cost
				neighbor_node.h_cost = _heuristic(neighbor_world, _grid_to_world(goal_grid))
				neighbor_node.calculate_f_cost()
				
				# Ajoute à open si nouveau
				if not open_list.has(neighbor_node):
					open_list.append(neighbor_node)
	
	# Aucun chemin trouvé
	print("[A*] Aucun chemin trouvé après %d itérations" % iterations)
	return []

# ========================================
# HEURISTIQUE
# ========================================

func _heuristic(from: Vector2, to: Vector2) -> float:
	# heuristique euclidienne sur positions monde (en px)
	return from.distance_to(to)

# ========================================
# COÛTS DE MOUVEMENT
# ========================================

func _calculate_movement_cost(from: Vector2, to: Vector2) -> float:
	var diff := to - from
	var diagonal = abs(diff.x) > 0 and abs(diff.y) > 0
	var base_cost := from.distance_to(to)
	if diagonal:
		base_cost *= 1.4  # pénalise un peu les diagonales
	return base_cost
	
# ========================================
# VOISINAGE
# ========================================

func _get_neighbor_cells(grid_pos: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			neighbors.append(grid_pos + Vector2i(dx, dy))
	return neighbors

# ========================================
# GESTION DES LISTES
# ========================================

func _get_lowest_f_cost_node(list: Array[PathNode]) -> PathNode:
	var lowest := list[0]
	for node in list:
		if node.f_cost < lowest.f_cost:
			lowest = node
	return lowest

func _is_in_closed_list(closed: Array[PathNode], pos: Vector2) -> bool:
	var threshold = max(cell_size.x, cell_size.y) * 0.5
	for node in closed:
		if node.position.distance_to(pos) < threshold:
			return true
	return false

func _find_or_create_node(list: Array[PathNode], pos: Vector2) -> PathNode:
	var threshold = max(cell_size.x, cell_size.y) * 0.5
	for node in list:
		if node.position.distance_to(pos) < threshold:
			return node
	return PathNode.new(pos)

# ========================================
# RECONSTRUCTION DU CHEMIN
# ========================================

func _retrace_path(start: PathNode, end: PathNode) -> Array[Vector2]:
	var path: Array[Vector2] = []
	var current := end
	while current != null and current != start:
		path.append(current.position)
		current = current.parent
	path.reverse()
	
	# Mise en cache du chemin (la clé est gérée dans find_path)
	return path

# ========================================
# OBSTACLES
# ========================================

func _is_obstacle_at_grid(grid_pos: Vector2i) -> bool:
	return obstacles.has(grid_pos)

func add_obstacle(world_pos: Vector2) -> void:
	var grid_pos := _world_to_grid(world_pos)
	if not obstacles.has(grid_pos):
		obstacles.append(grid_pos)

func remove_obstacle(world_pos: Vector2) -> void:
	var grid_pos := _world_to_grid(world_pos)
	obstacles.erase(grid_pos)

func clear_obstacles() -> void:
	obstacles.clear()
	_clear_cache()

# ========================================
# GESTION DU CACHE
# ========================================

func _get_cache_key(start: Vector2, end: Vector2) -> String:
	# Crée une clé unique pour le cache basée sur les positions de départ et d'arrivée
	var start_grid = _world_to_grid(start)
	var end_grid = _world_to_grid(end)
	return "%d_%d_%d_%d" % [start_grid.x, start_grid.y, end_grid.x, end_grid.y]

func _cache_path(key: String, path: Array[Vector2]) -> void:
	# Vérifie si le cache dépasse la taille maximale
	if _path_cache.size() >= MAX_CACHE_SIZE:
		_clear_cache()
	
	# Ajoute le chemin au cache
	_path_cache[key] = path.duplicate()

func _clear_cache() -> void:
	# Vide complètement le cache
	_path_cache.clear()

func clear_cache() -> void:
	# Méthode publique pour vider le cache
	_clear_cache()

# ========================================
# CONVERSIONS DE COORDONNÉES
# ========================================

func _world_to_grid(world_pos: Vector2) -> Vector2i:
	# Retourne la cellule de grille (Vector2i) correspondant à la position monde.
	if not isometric:
		# comportement original (orthogonal)
		return Vector2i(int(world_pos.x / cell_size.x), int(world_pos.y / cell_size.x))
	
	# Mode isométrique (stacked) conversion (tile width = cell_size.x, tile height = cell_size.y)
	var w := cell_size.x
	var h := cell_size.y
	# Formules de conversion (cartesian -> tile coords)
	# tx = floor((world_x/(w/2) + world_y/(h/2)) / 2)
	# ty = floor((world_y/(h/2) - world_x/(w/2)) / 2)
	var wx := world_pos.x
	var wy := world_pos.y
	var half_w := w * 0.5
	var half_h := h * 0.5
	var tx_f := ((wx / half_w) + (wy / half_h)) * 0.5
	var ty_f := ((wy / half_h) - (wx / half_w)) * 0.5
	# floor -> int
	return Vector2i(int(floor(tx_f)), int(floor(ty_f)))

func _grid_to_world(grid_pos: Vector2i) -> Vector2:
	# Retourne la position monde (centre de la case) correspondant à la grille.
	if not isometric:
		# comportement original (centre de cellule orthogonale)
		return Vector2(grid_pos.x * cell_size.x + cell_size.x * 0.5,
					   grid_pos.y * cell_size.x + cell_size.x * 0.5)
	
	# Mode isométrique (stacked)
	var w := cell_size.x
	var h := cell_size.y
	# world_x = (gx - gy) * (w/2)
	# world_y = (gx + gy) * (h/2)
	var gx := grid_pos.x
	var gy := grid_pos.y
	var world_x := (gx - gy) * (w * 0.5)
	var world_y := (gx + gy) * (h * 0.5)
	# world_x, world_y correspondent au centre de la tuile (diamond) dans cette formule
	return Vector2(world_x, world_y)

# ========================================
# UTILITAIRES
# ========================================

func _is_goal_reached(current: Vector2, goal: Vector2) -> bool:
	var threshold = max(cell_size.x, cell_size.y)
	return current.distance_to(goal) < threshold

func get_debug_info() -> Dictionary:
	return {
		"cell_size": cell_size,
		"obstacle_count": obstacles.size(),
		"max_iterations": max_iterations,
		"isometric": isometric
	}
