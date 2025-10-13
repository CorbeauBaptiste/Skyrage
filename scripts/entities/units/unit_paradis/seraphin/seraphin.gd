extends Unit

@export var pos_base: Vector2 = Vector2(635.0, 766.0) # Position approximatif de la base
@export var speed_sera: float = 20.0 # Rapidité de l'unité

func _ready():
	set_health(1600)
	set_speed(speed_sera)
	target = pos_base 

func _physics_process(delta: float):
	super._physics_process(delta)
	# Si la cible est null, on redéfinit la cible (la base)
	if target == null:
		target = pos_base
