extends Unit

@export var pos_base: Vector2 = Vector2(635.0, 766.0)

func _ready():
	set_health(1600)
	target = pos_base  # Cible initiale : la base

func _physics_process(delta: float):
	# Appelle le mouvement/évitement/animation de Unit
	super._physics_process(delta)

	# Si on est arrivé (target = null), on redéfinit la cible comme la base
	if target == null:
		target = pos_base
