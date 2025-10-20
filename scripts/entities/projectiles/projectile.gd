extends Area2D
class_name Projectile

@export var speed = 100: set = set_speed
@export var damage = 1: set = set_damage
@export var targets_enfer = true: set = set_target

var source_unit: Unit = null
var target_unit: Node2D = null  # Référence à la cible

# flèche de Cupidon (dégâts de zone)
var is_cupidon_arrow: bool = false
var area_damage: int = 35
var area_radius: float = 80.0

var is_homing: bool = true  # Whether the projectile homes in on its target
var homing_strength: float = 5.0  # How strongly the projectile turns toward its target
var max_homing_angle: float = PI / 4  # Maximum angle the projectile can turn per frame
var has_reached_target: bool = false

var spawn_position: Vector2
var max_distance: float = 0.0  # Will be set by the unit


# glaive de Michaël (dégâts adaptatifs massifs)
var is_michael_glaive: bool = false

func _ready():
	set_as_top_level(true)
	collision_mask = 2
	spawn_position = global_position  # Store the initial position
	_find_initial_target()

func _find_initial_target() -> void:
	"""Trouve la cible la plus proche dans la direction du tir"""
	if not source_unit or not is_instance_valid(source_unit):
		return
	
	# Chercher dans la zone de portée de l'unité
	if source_unit.has_node("Range"):
		var range_area = source_unit.get_node("Range")
		var bodies = range_area.get_overlapping_bodies()
		
		var closest: Node2D = null
		var min_dist = INF
		
		for body in bodies:
			if not is_instance_valid(body):
				continue
			
			# Vérifier si c'est un ennemi valide
			var is_valid = false
			if body is Unit and body.is_hell_faction != source_unit.is_hell_faction:
				is_valid = true
			elif body is Base and body.get_side() != source_unit.is_hell_faction:
				is_valid = true
			
			if is_valid:
				var dist = global_position.distance_to(body.global_position)
				if dist < min_dist:
					min_dist = dist
					closest = body
		
		target_unit = closest

func _process(delta):
	# Check if target is still valid
	if target_unit and not is_instance_valid(target_unit):
		queue_free()
		return
	
	# Check if projectile has traveled beyond max distance
	if global_position.distance_to(spawn_position) > max_distance and max_distance > 0:
		queue_free()
		return
	
	# Homing behavior remains the same
	if is_homing and target_unit and is_instance_valid(target_unit):
		var target_direction = (target_unit.global_position - global_position).normalized()
		var current_direction = Vector2.RIGHT.rotated(rotation)
		var angle_diff = current_direction.angle_to(target_direction)
		angle_diff = clamp(angle_diff, -max_homing_angle, max_homing_angle)
		rotation += angle_diff * homing_strength * delta
	
	# Move in the current facing direction
	position += (Vector2.RIGHT * speed).rotated(rotation) * delta


func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	queue_free()

func change_sprite(sprite_route, hframes = 1, vframes = 1, frame = 0):
	var texture = load(sprite_route)
	$Sprite2D.texture = texture
	if hframes > 1:
		$Sprite2D.hframes = hframes
	if vframes > 1:
		$Sprite2D.vframes = vframes
	$Sprite2D.frame = frame

func set_speed(value):
	speed = value

func set_damage(value):
	damage = value

func set_target(value):
	targets_enfer = value

func _on_body_entered(body: Node2D) -> void:
	if not is_instance_valid(body):
		return
	
	if body is Base:
		var is_valid_target = (targets_enfer and body.team == "enfer") or (not targets_enfer and body.team == "paradis")
		
		if is_valid_target:
			var final_damage = damage
			if source_unit and "damage_multiplier" in source_unit:
				final_damage = int(damage * source_unit.damage_multiplier)
			
			# Pass the source unit as the attacker
			body.take_damage(final_damage, source_unit)
			
			# If the source unit is attacking a base, update its state
			if source_unit and source_unit.has_method("_on_base_attacked"):
				source_unit.call_deferred("_on_base_attacked", body)
			
			queue_free()
		return
	
	if body is Unit and body.has_method("get_side"):
		var is_valid_target = (targets_enfer and body.get_side() == true) or (not targets_enfer and body.get_side() == false)
			
		if is_valid_target:
			if is_michael_glaive:
				_explode_michael_glaive(body.global_position)
			elif is_cupidon_arrow:
				_explode_area_damage(body.global_position)
			else:
				# Attaque normale
				var final_damage = damage
				if source_unit and "damage_multiplier" in source_unit:
					final_damage = int(damage * source_unit.damage_multiplier)
				
				body.set_health(body.get_health() - final_damage)
				
			queue_free()

func _explode_area_damage(explosion_pos: Vector2) -> void:
	"""Explosion de zone (Cupidon/Séraphin/Démon)"""
	_create_explosion_visual(explosion_pos)
	
	var space = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = area_radius
	
	query.shape = shape
	query.transform = Transform2D(0, explosion_pos)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.collision_mask = 2
	
	var hits = space.intersect_shape(query, 32)
	
	for hit in hits:
		var unit = hit.collider
		if not is_instance_valid(unit):
			continue
			
		if unit is Unit and unit.has_method("get_side"):
			var is_valid_target = (targets_enfer and unit.get_side() == true) or (not targets_enfer and unit.get_side() == false)
			
			if is_valid_target:
				var final_damage = area_damage
				if source_unit and "damage_multiplier" in source_unit:
					final_damage = int(area_damage * source_unit.damage_multiplier)
				
				unit.set_health(unit.get_health() - final_damage)

func _explode_michael_glaive(explosion_pos: Vector2) -> void:
	"""Explosion du Glaive de Michaël"""
	_create_explosion_visual(explosion_pos, Color(1.8, 1.5, 0.3, 0.9), 5.0, 0.6)
	
	var space = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = area_radius
	
	query.shape = shape
	query.transform = Transform2D(0, explosion_pos)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.collision_mask = 2
	
	var hits = space.intersect_shape(query, 32)
	
	for hit in hits:
		var unit = hit.collider
		if not is_instance_valid(unit):
			continue
			
		if unit is Unit and unit.has_method("get_side"):
			var is_valid_target = (targets_enfer and unit.get_side() == true) or (not targets_enfer and unit.get_side() == false)
			
			if is_valid_target:
				var damage_value = _calculate_michael_damage(unit)
				
				if source_unit and source_unit.has("damage_multiplier"):
					damage_value = int(damage_value * source_unit.damage_multiplier)
				
				unit.set_health(unit.get_health() - damage_value)

func _calculate_michael_damage(unit: Unit) -> int:
	"""Calcule les dégâts du Glaive selon la taille"""
	if not unit.has("unit_size") or not unit.has("max_health"):
		return 50
	
	var size = unit.unit_size
	var max_hp = unit.max_health
	
	match size:
		"S": return max_hp  # One shot
		"M": return int(max_hp * 0.75)  # 75%
		"L": return int(max_hp * 0.5)  # 50%
		_: return int(max_hp * 0.75)

func _create_explosion_visual(pos: Vector2, color: Color = Color(1.5, 0.3, 1.0, 0.7), scale_mult: float = 3.0, duration: float = 0.4) -> void:
	"""Effet visuel d'explosion"""
	var explosion = Sprite2D.new()
	explosion.modulate = color
	explosion.position = pos
	explosion.z_index = 50
	
	if $Sprite2D and $Sprite2D.texture:
		explosion.texture = $Sprite2D.texture
	
	get_parent().add_child(explosion)
	
	var tween = explosion.create_tween()
	tween.parallel().tween_property(explosion, "scale", Vector2(scale_mult, scale_mult), duration)
	tween.parallel().tween_property(explosion, "modulate:a", 0.0, duration)
	tween.tween_callback(explosion.queue_free)
