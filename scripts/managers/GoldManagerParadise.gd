extends Node
class_name GoldManagerParadise

signal gold_changed(current: float, max_value: float)
signal gold_spent(cost: float)
signal gold_not_enough(cost: float)

var max_gold: float = 20.0
var current_gold: float = 0.0
var regen_per_sec: float = 0.8

var use_overtime_curve: bool = true
var t_elapsed: float = 0.0
var regen_mult: float = 1.0

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	t_elapsed += delta
	if use_overtime_curve:
		regen_mult = 2.0 if t_elapsed >= 240.0 else 1.0

	if current_gold < max_gold:
		current_gold = min(max_gold, current_gold + regen_per_sec * regen_mult * delta)
		gold_changed.emit(current_gold, max_gold)
		
	#print("Or regen: ", regen_per_sec * regen_mult, "/sec")

func can_spend(cost: float) -> bool:
	return current_gold >= cost

func spend(cost: float) -> bool:
	if can_spend(cost):
		current_gold -= cost
		gold_changed.emit(current_gold, max_gold)
		gold_spent.emit(cost)
		return true
	gold_not_enough.emit(cost)
	return false

func fill_full() -> void:
	current_gold = max_gold
	gold_changed.emit(current_gold, max_gold)

func reset_match() -> void:
	t_elapsed = 0.0
	regen_mult = 1.0
	current_gold = 0.0
	gold_changed.emit(current_gold, max_gold)
