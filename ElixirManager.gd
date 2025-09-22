extends Node
class_name ElixirManager

signal elixir_changed(current: float, max_value: float)
signal elixir_spent(cost: float)
signal elixir_not_enough(cost: float)

var max_elixir: float = 10.0
var current_elixir: float = 0.0
var regen_per_sec: float = 0.8

var use_overtime_curve: bool = true
var t_elapsed: float = 0.0
var regen_mult: float = 1.0

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	t_elapsed += delta
	if use_overtime_curve:
		if t_elapsed >= 20.0:
			regen_mult = 2.0
		else:
			regen_mult = 1.0

	if current_elixir < max_elixir:
		current_elixir = min(max_elixir, current_elixir + regen_per_sec * regen_mult * delta)
		elixir_changed.emit(current_elixir, max_elixir)

func can_spend(cost: float) -> bool:
	return current_elixir >= cost

func spend(cost: float) -> bool:
	if can_spend(cost):
		current_elixir -= cost
		elixir_changed.emit(current_elixir, max_elixir)
		elixir_spent.emit(cost)
		return true
	elixir_not_enough.emit(cost)
	return false

func fill_full() -> void:
	current_elixir = max_elixir
	elixir_changed.emit(current_elixir, max_elixir)

func reset_match() -> void:
	t_elapsed = 0.0
	regen_mult = 1.0
	current_elixir = 0.0
	elixir_changed.emit(current_elixir, max_elixir)
