extends Area2D
class_name Projectile

@export var speed = 100: set = set_speed
@export var damage = 1: set = set_damage
@export var targets_enfer = true: set = set_target

var source_unit: Unit = null # Unité qui a tiré le projectile (pour multiplicateur de dégâts)

# Flèche de Cupidon (dégâts de zone)
var is_cupidon_arrow: bool = false
var area_damage: int = 35
var area_radius: float = 80.0

# Glaive de Michaël (dégâts adaptatifs massifs)
var is_michael_glaive: bool = false

func _ready():
	set_as_top_level(true)
	collision_mask = 2

func _process(delta):
	position += (Vector2.RIGHT * speed).rotated(rotation) * delta

func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	queue_free()

func change_sprite(sprite_route, hframes = 0, vframes = 0, frame = 0):
	var texture = load(sprite_route)
	$Sprite2D.texture = texture
	$Sprite2D.hframes = hframes
	$Sprite2D.vframes = vframes
	$Sprite2D.frame = frame

func set_speed(value):
	speed = value

func set_damage(value):
	damage = value

func set_target(value):
	targets_enfer = value

func _on_body_entered(body: Node2D) -> void:
	print("Projectile touché : ", body.get_class(), " (nom: ", body.name if body else "null", ")")
	
	if body is Unit:
		if body.has_method("get_side"):
			# Vérifier si c'est une cible valide
			var is_valid_target = (targets_enfer and body.get_side() == true) or (not targets_enfer and not body.get_side())
			
			if is_valid_target:
				if is_michael_glaive:
					# Glaive de Michaël : dégâts massifs adaptatifs
					print("⚔️ Explosion du Glaive de Michaël !")
					_explode_michael_glaive(body.global_position)
				elif is_cupidon_arrow:
					# Flèche de Cupidon : dégâts de zone
					print("💘 Explosion de flèche de Cupidon !")
					_explode_area_damage(body.global_position)
				else:
					# Flèche normale : dégâts directs
					var final_damage = damage
					if source_unit and source_unit.has("damage_multiplier"):
						final_damage *= source_unit.damage_multiplier
					body.set_health(body.get_health() - final_damage)
					print("Dmg infligé à unité: ", final_damage)
				
				queue_free()
	else:
		print("Projectile ignore non-Unit : ", body.get_class())

func _explode_area_damage(explosion_pos: Vector2) -> void:
	"""
	Crée une explosion qui inflige des dégâts de zone
	Args:
		explosion_pos: Position de l'explosion
	"""
	# Effet visuel d'explosion (cercle rose qui s'agrandit)
	_create_explosion_visual(explosion_pos)
	
	# Trouver toutes les unités dans la zone
	var space = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = area_radius
	
	query.shape = shape
	query.transform = Transform2D(0, explosion_pos)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.collision_mask = 2 # Layer des unités
	
	var hits = space.intersect_shape(query, 32)
	var damaged_count = 0
	
	for hit in hits:
		var unit = hit.collider
		if unit is Unit and unit.has_method("get_side"):
			# Vérifier si c'est une cible valide (camp ennemi)
			var is_valid_target = (targets_enfer and unit.get_side() == true) or (not targets_enfer and not unit.get_side())
			
			if is_valid_target:
				var final_damage = area_damage
				if source_unit and source_unit.has("damage_multiplier"):
					final_damage *= source_unit.damage_multiplier
				
				unit.set_health(unit.get_health() - final_damage)
				damaged_count += 1
				print("   💥 Dégâts de zone: ", final_damage, " à ", unit.name)
	
	print("   Total unités touchées: ", damaged_count)

func _explode_michael_glaive(explosion_pos: Vector2) -> void:
	"""
	Explosion du Glaive de Michaël avec dégâts adaptatifs
	- S (Small): One-shot complet
	- M (Medium): 75% des PV max
	- L (Large): 50% des PV max
	"""
	# Effet visuel spectaculaire (plus grand et or)
	_create_explosion_visual(explosion_pos, Color(1.8, 1.5, 0.3, 0.9), 5.0, 0.6)
	
	# Trouver toutes les unités dans la zone
	var space = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = area_radius
	
	query.shape = shape
	query.transform = Transform2D(0, explosion_pos)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.collision_mask = 2 # Layer des unités
	
	var hits = space.intersect_shape(query, 32)
	var damaged_count = 0
	
	for hit in hits:
		var unit = hit.collider
		if unit is Unit and unit.has_method("get_side"):
			# Vérifier si c'est une cible valide (camp ennemi)
			var is_valid_target = (targets_enfer and unit.get_side() == true) or (not targets_enfer and not unit.get_side())
			
			if is_valid_target:
				# Calculer dégâts selon taille
				var damage_value = _calculate_michael_damage(unit)
				
				# Appliquer multiplicateur si actif
				if source_unit and source_unit.has("damage_multiplier"):
					damage_value *= source_unit.damage_multiplier
				
				var old_health = unit.get_health()
				unit.set_health(unit.get_health() - damage_value)
				damaged_count += 1
				
				print("   ⚔️ Glaive → ", unit.name, " (", unit.unit_size, "): ", damage_value, " dmg (", old_health, " → ", unit.get_health(), ")")
	
	print("   💥 Total unités annihilées: ", damaged_count)

func _calculate_michael_damage(unit: Unit) -> int:
	"""
	Calcule les dégâts du Glaive selon la taille de l'unité
	Returns: Montant de dégâts à infliger
	"""
	if not unit.has("unit_size") or not unit.has("max_health"):
		return 50 # Dégâts par défaut
	
	var size = unit.unit_size
	var max_hp = unit.max_health
	
	match size:
		"S": # Small - One shot complet
			return max_hp # 100% des PV
		"M": # Medium - 3/4 des PV
			return int(max_hp * 0.75) # 75%
		"L": # Large - Moitié des PV
			return int(max_hp * 0.5) # 50%
		_:
			return int(max_hp * 0.75) # Par défaut: 75%

func _create_explosion_visual(pos: Vector2, color: Color = Color(1.5, 0.3, 1.0, 0.7), scale_mult: float = 3.0, duration: float = 0.4) -> void:
	"""Crée un effet visuel d'explosion personnalisable"""
	# Créer un sprite circulaire temporaire
	var explosion = Sprite2D.new()
	explosion.modulate = color
	explosion.position = pos
	explosion.z_index = 50
	
	# Utiliser une texture simple ou créer un cercle
	# Pour l'instant, utiliser la même texture que le projectile
	if $Sprite2D and $Sprite2D.texture:
		explosion.texture = $Sprite2D.texture
	
	get_parent().add_child(explosion)
	
	# Animation d'expansion et fade
	var tween = explosion.create_tween()
	tween.parallel().tween_property(explosion, "scale", Vector2(scale_mult, scale_mult), duration)
	tween.parallel().tween_property(explosion, "modulate:a", 0.0, duration)
	tween.tween_callback(explosion.queue_free)
