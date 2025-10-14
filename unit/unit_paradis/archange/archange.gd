extends Unit

@export var posi : Vector2 = Vector2(635.0, 766.0)
@export var speed_arch : float = 30

func _ready():
	set_health(800)
	#set_damage(300)
	set_attack_speed(2.5)
	#set_attack_range(3)
	set_speed(speed_arch)
	target = posi 
	
func _physics_process(delta: float) -> void:
	super ._physics_process(	delta)
	if target == null:
		target = posi
