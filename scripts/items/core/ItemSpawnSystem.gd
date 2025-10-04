class_name ItemSpawnSystem
extends Node

signal item_collected(item: Item, position: Vector2)

@export var spawn_interval: float = 5.0
@export var min_distance_between_items: float = 80.0
@export var item_texture: Texture2D

var item_manager: ItemManager
var spawned_items: Dictionary = {}
var spawn_timer: Timer

@onready var tilemap_sol: TileMapLayer
@onready var tilemap_decoration: TileMapLayer

func _init():
	item_manager = ItemManager.new()

func setup(sol_layer: TileMapLayer, decoration_layer: TileMapLayer, texture: Texture2D = null):
	"""Configure le système de spawn avec les références nécessaires"""
	tilemap_sol = sol_layer
	tilemap_decoration = decoration_layer
	if texture:
		item_texture = texture
	
	_setup_timer()

func _setup_timer():
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.autostart = true
	add_child(spawn_timer)

func _on_spawn_timer_timeout():
	spawn_random_item()

func spawn_random_item():
	var item = item_manager.get_random_item()
	if not item:
		return
	
	var spawn_position = _get_random_valid_position()
	if spawn_position != Vector2.ZERO:
		_create_item_sprite(item, spawn_position)

func _get_random_valid_position() -> Vector2:
	if not tilemap_sol or not tilemap_decoration:
		push_error("TileMaps non configurées!")
		return Vector2.ZERO
	
	var used_cells = tilemap_sol.get_used_cells()
	if used_cells.is_empty():
		return Vector2.ZERO
	
	var decoration_cells = tilemap_decoration.get_used_cells()
	
	# Tente de trouver une position valide
	for i in range(100):
		var random_cell = used_cells[randi() % used_cells.size()]
		
		# Vérifie qu'il n'y a pas de décoration
		if random_cell in decoration_cells:
			continue
		
		var local_pos = tilemap_sol.map_to_local(random_cell)
		var world_pos = tilemap_sol.to_global(local_pos)
		
		# Vérifie la distance avec les autres items
		if _is_position_valid(world_pos):
			return world_pos
	
	return Vector2.ZERO

func _is_position_valid(position: Vector2) -> bool:
	for existing_pos in spawned_items.keys():
		if position.distance_to(existing_pos) < min_distance_between_items:
			return false
	return true

func _create_item_sprite(item: Item, position: Vector2):
	var sprite = Sprite2D.new()
	sprite.texture = item_texture
	sprite.position = position
	sprite.scale = Vector2(0.1, 0.1)
	sprite.set_meta("item", item)
	sprite.set_meta("spawn_position", position)
	
	spawned_items[position] = item
	
	# Animation d'apparition
	sprite.modulate.a = 0.0
	add_child(sprite)
	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 1.0, 0.5)

func check_collection(units: Array):
	"""Vérifie si une unité ramasse un item"""
	for unit in units:
		if unit == null:
			continue
		
		for item_pos in spawned_items.keys():
			if unit.global_position.distance_to(item_pos) < 25:
				_collect_item(item_pos)
				return

func _collect_item(item_pos: Vector2):
	if not spawned_items.has(item_pos):
		return
	
	var item = spawned_items[item_pos]
	spawned_items.erase(item_pos)
	
	# Supprime le sprite
	for child in get_children():
		if child is Sprite2D and child.has_meta("spawn_position"):
			if child.get_meta("spawn_position") == item_pos:
				child.queue_free()
				break
	
	# Émet le signal pour que d'autres systèmes réagissent
	item_collected.emit(item, item_pos)

func clear_all_items():
	for child in get_children():
		if child is Sprite2D:
			child.queue_free()
	spawned_items.clear()
