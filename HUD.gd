extends Control

@onready var bar: ProgressBar              = %ElixirBar
@onready var label: Label                  = %ElixirLabel
@onready var btn2: Button                  = %BtnCost2
@onready var btn4: Button                  = %BtnCost4
@onready var btn6: Button                  = %BtnCost6
@onready var elixir_manager: ElixirManager = %ElixirManager

const COST_2 := 2.0
const COST_4 := 4.0
const COST_6 := 6.0

func _ready() -> void:
	bar.min_value = 0.0
	bar.max_value = elixir_manager.max_elixir
	_refresh_ui(elixir_manager.current_elixir, elixir_manager.max_elixir)

	elixir_manager.elixir_changed.connect(_on_elixir_changed)
	elixir_manager.elixir_spent.connect(_on_elixir_spent)
	elixir_manager.elixir_not_enough.connect(_on_elixir_not_enough)

	btn2.pressed.connect(func(): _try_spend(COST_2))
	btn4.pressed.connect(func(): _try_spend(COST_4))
	btn6.pressed.connect(func(): _try_spend(COST_6))

func _process(_delta: float) -> void:
	var e = elixir_manager.current_elixir
	btn2.disabled = e < COST_2
	btn4.disabled = e < COST_4
	btn6.disabled = e < COST_6

func _try_spend(cost: float) -> void:
	elixir_manager.spend(cost)

func _on_elixir_changed(current: float, max_value: float) -> void:
	_refresh_ui(current, max_value)

func _on_elixir_spent(_cost: float) -> void:
	_pulse_bar()

func _on_elixir_not_enough(cost: float) -> void:
	_shake_label("Pas assez d’élixir (coût: %d) !" % int(cost))

func _refresh_ui(current: float, max_value: float) -> void:
	bar.value = current
	label.text = "GOLD : %.1f / %.0f" % [current, max_value]

func _pulse_bar() -> void:
	var tween := create_tween()


func _shake_label(msg: String) -> void:
	label.text = msg
	var tween := create_tween()
