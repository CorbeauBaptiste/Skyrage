extends Area2D
class_name Projectile

## Projectile tiré par les unités.
##
## Responsabilités :
## - Se déplacer vers la cible avec guidage
## - Infliger des dégâts au contact
## - Gérer les effets spéciaux (Cupidon, Michaël)

# ========================================
# PROPRIÉTÉS EXPORTÉES
# ========================================

## Vitesse du projectile (px/sec).
@export var speed: int = 100: set = set_speed

## Dégâts de base.
@export var damage: int = 1: set = set_damage

## Si cible le camp Enfer.
@export var targets_enfer: bool = true: set = set_target

# ========================================
# VARIABLES D'ÉTAT
# ========================================

## Unité source du projectile.
var source_unit: Unit = null

## Cible actuelle.
var target_unit: Node2D = null

## Si flèche de Cupidon (zone).
var is_cupidon_arrow: bool = false

## Dégâts de zone.
var area_damage: int = 35

## Rayon de zone.
var area_radius: float = 80.0

## Si guidage activé.
var is_homing: bool = true

## Force du guidage.
var homing_strength: float = 5.0

## Angle max de rotation par frame.
var max_homing_angle: float = PI / 4

## Position de spawn.
var spawn_position: Vector2

## Distance max avant disparition.
var max_distance: float = 0.0

## Si glaive de Michaël.
var is_michael_glaive: bool = false

# ========================================
# INITIALISATION
# ========================================

func _ready() -> void:
	set_as_top_level(true)
	collision_mask = 2
	spawn_position = global_position
	_find_initial_target()

# ========================================
# CIBLAGE
# ========================================

func _find_initial_target() -> void:
	## Trouve la cible la plus proche dans la direction du tir.
	if not source_unit or not is_instance_valid(source_unit):
		return
	
	if source_unit.has_node("Range"):
		var range_area: Area2D = source_unit.get_node("Range")
		var bodies := range_area.get_overlapping_bodies()
		
		var closest: Node2D = null
		var min_dist := INF
		
		for body in bodies:
			if not is_instance_valid(body):
				continue
			
			var is_valid := false
			if body is Unit and body.is_hell_faction != source_unit.is_hell_faction:
				is_valid = true
			elif body is Base and body.get_side() != source_unit.is_hell_faction:
				is_valid = true
			
			if is_valid:
				var dist := global_position.distance_to(body.global_position)
				if dist < min_dist:
					min_dist = dist
					closest = body
		
		target_unit = closest

# ========================================
# UPDATE
# ========================================

func _process(delta: float) -> void:
	## Met à jour la position et la rotation du projectile.
	if target_unit and not is_instance_valid(target_unit):
		queue_free()
		return
	
	if global_position.distance_to(spawn_position) > max_distance and max_distance > 0:
		queue_free()
		return
	
	if is_homing and target_unit and is_instance_valid(target_unit):
		var target_direction := (target_unit.global_position - global_position).normalized()
		var current_direction := Vector2.RIGHT.rotated(rotation)
		var angle_diff := current_direction.angle_to(target_direction)
		angle_diff = clamp(angle_diff, -max_homing_angle, max_homing_angle)
		rotation += angle_diff * homing_strength * delta
	
	position += (Vector2.RIGHT * speed).rotated(rotation) * delta

# ========================================
# COLLISIONS
# ========================================

func _on_body_entered(body: Node2D) -> void:
	## Callback quand le projectile touche quelque chose.
	if not is_instance_valid(body):
		return
	
	if body is Base:
		var is_valid_target : bool = (targets_enfer and body.team == "enfer") or (not targets_enfer and body.team == "paradis")

		if is_valid_target:
			var final_damage := damage
			if is_instance_valid(source_unit) and source_unit is Unit:
				if source_unit.combat_component:
					final_damage = int(damage * source_unit.combat_component.damage_multiplier)

			# Passer l'attaquant seulement s'il existe encore
			var attacker: Node2D = source_unit if is_instance_valid(source_unit) else null
			body.take_damage(final_damage, attacker)
			queue_free()
		return
	
	if body is Unit:
		var is_valid_target : bool = (targets_enfer and body.get_side() == true) or (not targets_enfer and body.get_side() == false)

		if is_valid_target:
			if is_michael_glaive:
				_explode_michael_glaive(body.global_position)
			elif is_cupidon_arrow:
				_explode_area_damage(body.global_position)
			else:
				var final_damage := damage
				if is_instance_valid(source_unit) and source_unit is Unit:
					if source_unit.combat_component:
						final_damage = int(damage * source_unit.combat_component.damage_multiplier)

				body.set_health(body.get_health() - final_damage)

			queue_free()

# ========================================
# EXPLOSIONS
# ========================================

func _explode_area_damage(explosion_pos: Vector2) -> void:
	## Explosion de zone (Cupidon/Séraphin/Démon).
	##
	## @param explosion_pos: Position de l'explosion
	_create_explosion_visual(explosion_pos)
	
	var space := get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = area_radius
	
	query.shape = shape
	query.transform = Transform2D(0, explosion_pos)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.collision_mask = 2
	
	var hits := space.intersect_shape(query, 32)
	
	for hit in hits:
		var unit = hit.collider
		if not is_instance_valid(unit):
			continue
			
		if unit is Unit:
			var is_valid_target : bool = (targets_enfer and unit.get_side() == true) or (not targets_enfer and unit.get_side() == false)
			
			if is_valid_target:
				var final_damage := area_damage
				if source_unit and source_unit is Unit:
					if source_unit.combat_component:
						final_damage = int(area_damage * source_unit.combat_component.damage_multiplier)
				
				unit.set_health(unit.get_health() - final_damage)


func _explode_michael_glaive(explosion_pos: Vector2) -> void:
	## Explosion du Glaive de Michaël.
	##
	## @param explosion_pos: Position de l'explosion
	_create_explosion_visual(explosion_pos, Color(1.8, 1.5, 0.3, 0.9), 5.0, 0.6)
	
	var space := get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = area_radius
	
	query.shape = shape
	query.transform = Transform2D(0, explosion_pos)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.collision_mask = 2
	
	var hits := space.intersect_shape(query, 32)
	
	for hit in hits:
		var unit = hit.collider
		if not is_instance_valid(unit):
			continue
			
		if unit is Unit:
			var is_valid_target : bool = (targets_enfer and unit.get_side() == true) or (not targets_enfer and unit.get_side() == false)
			
			if is_valid_target:
				var damage_value := _calculate_michael_damage(unit)
				
				if source_unit and source_unit is Unit:
					if source_unit.combat_component:
						damage_value = int(damage_value * source_unit.combat_component.damage_multiplier)
				
				unit.set_health(unit.get_health() - damage_value)


func _calculate_michael_damage(unit: Unit) -> int:
	## Calcule les dégâts du Glaive selon la taille.
	##
	## @param unit: Unité touchée
	## @return: Dégâts calculés
	var size := unit.unit_size
	var max_hp := unit.max_health
	
	match size:
		"S": return max_hp
		"M": return int(max_hp * 0.75)
		"L": return int(max_hp * 0.5)
		_: return int(max_hp * 0.75)


func _create_explosion_visual(pos: Vector2, color: Color = Color(1.5, 0.3, 1.0, 0.7), scale_mult: float = 3.0, duration: float = 0.4) -> void:
	## Crée l'effet visuel d'explosion.
	##
	## @param pos: Position de l'explosion
	## @param color: Couleur de l'effet
	## @param scale_mult: Multiplicateur de taille
	## @param duration: Durée de l'animation
	var explosion := Sprite2D.new()
	explosion.modulate = color
	explosion.position = pos
	explosion.z_index = 50
	
	if $Sprite2D and $Sprite2D.texture:
		explosion.texture = $Sprite2D.texture
	
	get_parent().add_child(explosion)
	
	var tween := explosion.create_tween()
	tween.parallel().tween_property(explosion, "scale", Vector2(scale_mult, scale_mult), duration)
	tween.parallel().tween_property(explosion, "modulate:a", 0.0, duration)
	tween.tween_callback(explosion.queue_free)

# ========================================
# UTILITAIRES
# ========================================

func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	## Détruit le projectile quand il sort de l'écran.
	queue_free()


func change_sprite(sprite_route: String, hframes: int = 1, vframes: int = 1, frame: int = 0) -> void:
	## Change le sprite du projectile.
	##
	## @param sprite_route: Chemin vers la texture
	## @param hframes: Nombre de frames horizontales
	## @param vframes: Nombre de frames verticales
	## @param frame: Frame à afficher
	var texture := load(sprite_route)
	$Sprite2D.texture = texture
	if hframes > 1:
		$Sprite2D.hframes = hframes
	if vframes > 1:
		$Sprite2D.vframes = vframes
	$Sprite2D.frame = frame

# ========================================
# SETTERS
# ========================================

func set_speed(value: int) -> void:
	speed = value


func set_damage(value: int) -> void:
	damage = value


func set_target(value: bool) -> void:
	targets_enfer = value
