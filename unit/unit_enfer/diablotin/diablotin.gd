extends Unit

@export var ai_enabled: bool = true
@export var ai_speed: float = 110.0
@export var arrive_epsilon: float = 8.0

@export var cell_size: Vector2 = Vector2(32, 32)
@export var grid_size: Vector2i = Vector2i(160, 90)
@export var grid_world_origin: Vector2 = Vector2.ZERO
@export var allow_diagonals: bool = true

@export var obstacles_tilemap_path: NodePath
@export var target_base_path: NodePath

var _astar: AStarGrid2D
var _path: Array[Vector2] = []
var _path_index: int = 0
var _target_node: Node2D
var _tilemap: TileMap
var _repath_timer: float = 0.0
var _repath_interval: float = 0.5

func _ready():
	set_health(3)
	set_side(true)

	_build_grid()
	_target_node = get_node_or_null(target_base_path)
	_tilemap = get_node_or_null(obstacles_tilemap_path)
	_mark_obstacles_from_tilemap()
	_request_path_to_target(true)

func _physics_process(delta):
	if not ai_enabled:
		return

	if _target_node == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	_repath_timer += delta
	if _repath_timer >= _repath_interval:
		_repath_timer = 0.0
		_request_path_to_target(false)

	if _path.is_empty():
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var wp = _path[_path_index]
	var dir = wp - global_position
	if dir.length() > arrive_epsilon:
		dir = dir.normalized()
		velocity = dir * ai_speed
		move_and_slide()
	else:
		if _path_index < _path.size() - 1:
			_path_index += 1
		else:
			velocity = Vector2.ZERO
			move_and_slide()

# ---------------------- A* GRID ----------------------

func _build_grid():
	_astar = AStarGrid2D.new()
	_astar.cell_size = cell_size
	_astar.size = grid_size
	_astar.offset = grid_world_origin
	_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	if allow_diagonals:
		_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	else:
		_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_astar.update()

func _mark_obstacles_from_tilemap():
	if _tilemap == null:
		return
	for cell in _tilemap.get_used_cells(0):
		_astar.set_point_solid(cell, true)

# ---------------------- PATHFIND ----------------------

func _request_path_to_target(force: bool):
	var start_cell = _world_to_cell(global_position)
	var goal_cell = _world_to_cell(_target_node.global_position)

	if not _in_bounds(start_cell):
		return
	if not _in_bounds(goal_cell):
		goal_cell = _clamp_to_bounds(goal_cell)

	if _astar.is_point_solid(goal_cell):
		var alt = _nearest_walkable(goal_cell, 10)
		if alt != null:
			goal_cell = alt
		else:
			return

	if not force and _path.size() > 0:
		var last_goal = _world_to_cell(_path.back())
		if last_goal == goal_cell:
			return

	var grid_points = _astar.get_point_path(start_cell, goal_cell)
	if grid_points.size() == 0:
		var alt2 = _nearest_walkable(goal_cell, 14)
		if alt2 != null:
			grid_points = _astar.get_point_path(start_cell, alt2)
		if grid_points.size() == 0:
			_path.clear()
			return

	_path.clear()
	for gp in grid_points:
		_path.append(_cell_center_to_world(Vector2i(gp)))
	_path_index = 0

# ---------------------- HELPERS ----------------------

func _world_to_cell(p: Vector2) -> Vector2i:
	var local = (p - grid_world_origin) / cell_size
	return Vector2i(floor(local.x), floor(local.y))

func _cell_to_world(c: Vector2i) -> Vector2:
	return grid_world_origin + Vector2(c) * cell_size

func _cell_center_to_world(c: Vector2i) -> Vector2:
	return _cell_to_world(c) + cell_size * 0.5

func _in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < grid_size.x and c.y < grid_size.y

func _clamp_to_bounds(c: Vector2i) -> Vector2i:
	return Vector2i(clamp(c.x, 0, grid_size.x - 1), clamp(c.y, 0, grid_size.y - 1))

func _nearest_walkable(from: Vector2i, max_r: int) -> Vector2i:
	for r in range(1, max_r + 1):
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				var cc = Vector2i(from.x + dx, from.y + dy)
				if not _in_bounds(cc):
					continue
				if not _astar.is_point_solid(cc):
					return cc
	return Vector2i.ZERO
