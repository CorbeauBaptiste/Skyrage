extends Node2D

# Composants
var item_manager: ItemManager
var item_spawner: ItemSpawner
var ui_manager: ItemUIManager
var grid_renderer: Grid

# Configuration
var nombre_case_x: int = 10
var nombre_case_y: int = 15
var spawn_wait_time: float = 30.0

func _ready():   
	setup_components()
	connect_signals()

func setup_components():
	var screen_size = get_viewport().get_visible_rect().size
	
	item_manager = ItemManager.new()
	ui_manager = ItemUIManager.new(screen_size)
	add_child(ui_manager)
	
	grid_renderer = Grid.new()
	grid_renderer.setup(nombre_case_x, nombre_case_y, screen_size)
	add_child(grid_renderer)
	
	item_spawner = ItemSpawner.new()
	item_spawner.setup(item_manager, nombre_case_x, nombre_case_y, screen_size)
	item_spawner.setup_timer(spawn_wait_time)
	add_child(item_spawner)

func connect_signals():
	item_spawner.item_spawned.connect(_on_item_spawned)

func _on_item_spawned(item: Item, grid_pos: Vector2):
	queue_redraw()

func _input(event):
	if event.is_action_pressed("ui_accept"):
		item_spawner.force_spawn()
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		handle_mouse_click(event.position)

func handle_mouse_click(mouse_pos: Vector2):
	var grid_pos = item_spawner.world_to_grid_position(mouse_pos)
	
	if not item_spawner.is_valid_position(grid_pos):
		return
	
	var item = item_spawner.get_item_at(grid_pos)
	if not item:
		return
	
	ui_manager.show_item_info(item, mouse_pos)
	
	item_spawner.remove_item_at(grid_pos)
	item_spawner.remove_sprite_at_position(grid_pos)
