extends Node2D

var item_manager: ItemManager

var screen_size: Vector2

var nombre_case_x: int = 10
var nombre_case_y: int = 15
var nombre_distance_entre_item: int

var grid_items: Dictionary = {} 

var spawn_timer: Timer

func _ready():
	item_manager = ItemManager.new()
	screen_size = get_viewport().get_visible_rect().size
	
	spawn_timer = Timer.new()
	spawn_timer.wait_time = 30.0
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.autostart = true
	add_child(spawn_timer)

func _on_spawn_timer_timeout():
	spawn_item()
	queue_redraw()

func _input(event):
	if event.is_action_pressed("ui_accept"):
		spawn_item()
		queue_redraw()
		
func _draw():
	var case_width = screen_size.x / nombre_case_x
	var case_height = screen_size.y / nombre_case_y
	# Dessiner chaque case
	for x in nombre_case_x:
		for y in nombre_case_y:
			var rect = Rect2(
				Vector2(x * case_width, y * case_height),
				Vector2(case_width, case_height)
			)
			draw_rect(rect, Color.GREEN, false)

func spawn_item():
	var item = item_manager.get_random_item()
	
	var case_width = screen_size.x / nombre_case_x
	var case_height = screen_size.y / nombre_case_y
	
	var case_x: int
	var case_y: int
	var attempts = 0
	var total_case: int = (nombre_case_x * nombre_case_y)

	# Nombre de case de distance entre chaque item
	var distance_min: int = 2
	
	while attempts < total_case:
		case_x = randi() % nombre_case_x
		case_y = randi() % nombre_case_y
		var grid_pos = Vector2(case_x, case_y)
		
		if is_position_free_with_distance(grid_pos, distance_min):
			grid_items[grid_pos] = item 
			break
		attempts += 1
	
	if attempts >= total_case:
		print("end")
		return
	
	var pos = Vector2(
		case_x * case_width + case_width / 2,
		case_y * case_height + case_height / 2
	)
	
	var sprite = Sprite2D.new()
	# Sprite a modifier si necessaire	
	sprite.texture = load("res://assets/sprite/items/light_item.png")
	sprite.position = pos
	sprite.scale = Vector2(0.15, 0.15)
	sprite.set_meta("grid_position", Vector2(case_x, case_y))
	
	add_child(sprite)
	print("Spawned: ", item.name, " at (", case_x, ",", case_y, ")")

func remove_item_at(grid_pos: Vector2):
	if grid_items.has(grid_pos):
		grid_items.erase(grid_pos)

func get_item_at(grid_pos: Vector2) -> Item:
	return grid_items.get(grid_pos, null)

func is_position_free_with_distance(grid_pos: Vector2, distance: int) -> bool:
	for x in range(grid_pos.x - distance, grid_pos.x + distance + 1):
		for y in range(grid_pos.y - distance, grid_pos.y + distance + 1):
			var check_pos = Vector2(x, y)
			
			if x >= 0 and x < nombre_case_x and y >= 0 and y < nombre_case_y:
				if grid_items.has(check_pos):
					return false
	
	return true
