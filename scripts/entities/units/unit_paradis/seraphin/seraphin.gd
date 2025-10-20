extends Unit

@export var pos_base: Vector2 = Vector2(635.0, 766.0) # Position approximatif de la base
@export var speed_sera: float = 20.0 # Rapidité de l'unité
@export var att_cooldown: float = 0.50 # Temps  de recharge entre chaque attaque (en seconde)
var can_attack: bool = true 
var current_target: Node = null  # Pour suivre la cible actuelle

func _ready():
	set_health(1600)
	set_speed(speed_sera)
	target = pos_base
	$Timer.timeout.connect(_if_attcooldown_end)

func _physics_process(delta: float):
	super._physics_process(delta)
	if target == null:
		target = pos_base
		
	# Vérifie les ennemis à chaque frame
	if can_attack:
		_check_and_attack()

# Vérifie l'identité de chaque ennemis
func _check_and_attack():
	var enemies = $Range.get_overlapping_bodies()
	for body in enemies:
		if is_instance_valid(body) and body != self and body.has_method("get_side") and body.get_side() != self.get_side():
			attack(body)
			can_attack = false
			$Timer.start(att_cooldown)
			break  

# Permets à l'unité d'attaquer lorsque le cooldown est fini
func _if_attcooldown_end():
	can_attack = true

# Permets de gérer les attaque sur les ennemies
func attack(target_body):
	var target_pos = target_body.global_position
	$Marker2D.look_at(target_pos)
	
	# Instanciation du projectile
	var arrow_instance = arrow.instantiate()
	arrow_instance.change_sprite("res://assets/sprites/projectiles/vent.png")
	
	# Paramètre pour l'attaque de zone
	arrow_instance.is_cupidon_arrow = true
	arrow_instance.area_damage = 600
	arrow_instance.area_radius = 20
	arrow_instance.set_target(not self.get_side())
	
	arrow_instance.rotation = $Marker2D.rotation
	arrow_instance.global_position = $Marker2D.global_position
	add_child(arrow_instance)
	
	print("Attaque sur : ", target_body.name)
