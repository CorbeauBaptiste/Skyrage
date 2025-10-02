extends CharacterBody2D
class_name Base

@export var enfer = true: set = set_enfer
@export var health = 20: set = set_health

### utilisée pour test, garder au cas où
func is_base():
	return "base"

func set_enfer(value):
	enfer = value

func set_health(value):
	health = value
	
	### comportement quand base morte, changer de scène ou quelque chose
	if health == 0:
		if enfer:
			print("Heaven wins")
		else:
			print("Hell wins")

func get_health():
	return health

func get_side():
	return enfer
