class_name ItemSpawner
extends Node2D

signal item_spawned(item: Item, grid_pos: Vector2)

var item_manager: ItemManager
var grid_items: Dictionary = {}
var spawn_timer: Timer

var nombre_case_x: int
var nombre_case_y: int
var screen_size: Vector2

var sprite_texture: Texture2D
var sprite_scale: Vector2 = Vector2(0.15, 0.15)

func setup(manager: ItemManager, cases_x: int, cases_y: int, screen: Vector2):
	item_manager = manager
	nombre_case_x = cases_x
	nombre_case_y = cases_y
	screen_size = screen

func _ready():
	sprite_texture = load("res://assets/sprite/items/light_item.png")
	setup_timer()

func setup_timer(wait_time: float = 30.0):
	spawn_timer = Timer.new()
	spawn_timer.wait_time = wait_time
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.autostart = true
	add_child(spawn_timer)

func _on_spawn_timer_timeout():
	spawn_item()

func spawn_item() -> bool:
	var item = item_manager.get_random_item()
	if not item:
		return false
	
	var grid_pos = find_free_position()
	if grid_pos == Vector2(-1, -1):
		print("Aucune position libre disponible")
		return false
	
	grid_items[grid_pos] = item
	create_sprite_at(grid_pos, item)
	item_spawned.emit(item, grid_pos)
	
	print("Spawned: ", item.name, " at (", grid_pos.x, ",", grid_pos.y, ")")
	return true

func find_free_position(distance_min: int = 2) -> Vector2:
	var total_cases = nombre_case_x * nombre_case_y
	var attempts = 0
	
	while attempts < total_cases:
		var case_x = randi() % nombre_case_x
		var case_y = randi() % nombre_case_y
		var grid_pos = Vector2(case_x, case_y)
		
		if is_position_free_with_distance(grid_pos, distance_min):
			return grid_pos
		attempts += 1
	
	return Vector2(-1, -1)

func is_position_free_with_distance(grid_pos: Vector2, distance: int) -> bool:
	for x in range(grid_pos.x - distance, grid_pos.x + distance + 1):
		for y in range(grid_pos.y - distance, grid_pos.y + distance + 1):
			var check_pos = Vector2(x, y)
			if x >= 0 and x < nombre_case_x and y >= 0 and y < nombre_case_y:
				if grid_items.has(check_pos):
					return false
	return true

func create_sprite_at(grid_pos: Vector2, item: Item):
	var case_width = screen_size.x / nombre_case_x
	var case_height = screen_size.y / nombre_case_y
	
	var sprite = Sprite2D.new()
	sprite.texture = sprite_texture
	sprite.position = Vector2(
		grid_pos.x * case_width + case_width / 2,
		grid_pos.y * case_height + case_height / 2
	)
	sprite.scale = sprite_scale
	sprite.set_meta("grid_position", grid_pos)
	sprite.set_meta("item", item)
	add_child(sprite)

func remove_sprite_at_position(grid_pos: Vector2):
	for child in get_children():
		if child is Sprite2D and child.has_meta("grid_position"):
			if child.get_meta("grid_position") == grid_pos:
				child.queue_free()
				break

func remove_item_at(grid_pos: Vector2) -> Item:
	if grid_items.has(grid_pos):
		var item = grid_items[grid_pos]
		grid_items.erase(grid_pos)
		return item
	return null

func get_item_at(grid_pos: Vector2) -> Item:
	return grid_items.get(grid_pos, null)

func world_to_grid_position(world_pos: Vector2) -> Vector2:
	var case_width = screen_size.x / nombre_case_x
	var case_height = screen_size.y / nombre_case_y
	
	var grid_x = int(world_pos.x / case_width)
	var grid_y = int(world_pos.y / case_height)
	
	return Vector2(grid_x, grid_y)

func is_valid_position(grid_pos: Vector2) -> bool:
	return grid_pos.x >= 0 and grid_pos.x < nombre_case_x and grid_pos.y >= 0 and grid_pos.y < nombre_case_y

func force_spawn():
	spawn_item()
	get_parent().queue_redraw()
