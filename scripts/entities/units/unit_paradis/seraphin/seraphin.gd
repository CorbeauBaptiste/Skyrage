extends Unit

var _destination_position: Vector2  # Position de destination pour le déplacement
@export var pos_base: Vector2 = Vector2(612.0, 727.0)
@export var speed_sera: float = 20.0
@export var att_cooldown: float = 0.50
var can_attack: bool = true
var current_enemy: Node = null  # Référence à l'ennemi actuel
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

func _ready():
	set_health(1600)
	_destination_position = pos_base
	if navigation_agent:
		navigation_agent.target_position = _destination_position
	else:
		push_error("NavigationAgent2D non trouvé !")
	$Timer.timeout.connect(_if_attcooldown_end)

func _physics_process(delta: float):
	super._physics_process(delta)
	if navigation_agent:
		if navigation_agent.is_target_reached():
			navigation_agent.target_position = _destination_position
		if !navigation_agent.is_target_reached() and !navigation_agent.is_navigation_finished():
			var next_path_position = navigation_agent.get_next_path_position()
			var direction = (next_path_position - global_position).normalized()
			velocity = direction * speed_sera
			move_and_slide()
	if can_attack:
		_check_and_attack()

func _check_and_attack():
	var enemies = $Range.get_overlapping_bodies()
	for body in enemies:
		if is_instance_valid(body) and body != self and body.has_method("get_side") and body.get_side() != self.get_side():
			current_enemy = body
			attack(current_enemy)
			can_attack = false
			$Timer.start(att_cooldown)
			break

func _if_attcooldown_end():
	can_attack = true

func attack(enemy: Node):
	if not is_instance_valid(enemy):
		return
	var enemy_pos = enemy.global_position
	$Marker2D.look_at(enemy_pos)
	var arrow_instance = arrow.instantiate()
	arrow_instance.change_sprite("res://assets/sprites/projectiles/vent.png")
	arrow_instance.is_cupidon_arrow = true
	arrow_instance.area_damage = 600
	arrow_instance.area_radius = 20
	arrow_instance.set_target(not self.get_side())
	arrow_instance.rotation = $Marker2D.rotation
	arrow_instance.global_position = $Marker2D.global_position
	add_child(arrow_instance)
	print("Attaque sur : ", enemy.name)

# Fonction pour définir la destination
func set_destination(new_destination: Vector2):
	_destination_position = new_destination
	if navigation_agent:
		navigation_agent.target_position = _destination_position
