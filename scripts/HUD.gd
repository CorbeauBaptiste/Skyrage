extends Control

@onready var bar: ProgressBar              = %GoldBar
@onready var label: Label                  = %GoldLabel
@onready var btn2: Button                  = %BtnCost5
@onready var btn4: Button                  = %BtnCost10
@onready var btn6: Button                  = %BtnCost15
@onready var gold_manager: goldManager = %GoldManager

const Cout_5 := 5.0
const Cout_10 := 10.0
const Cout_15 := 15.0

func _ready() -> void:
	bar.min_value = 0.0
	bar.max_value = gold_manager.max_gold
	_refresh_ui(gold_manager.current_gold, gold_manager.max_gold)

	gold_manager.gold_changed.connect(_on_gold_changed)
	gold_manager.gold_spent.connect(_on_gold_spent)
	gold_manager.gold_not_enough.connect(_on_gold_not_enough)

	btn2.pressed.connect(func(): _try_spend(Cout_5))
	btn4.pressed.connect(func(): _try_spend(Cout_10))
	btn6.pressed.connect(func(): _try_spend(Cout_15))

func _process(_delta: float) -> void:
	var e = gold_manager.current_gold
	btn2.disabled = e < Cout_5
	btn4.disabled = e < Cout_10
	btn6.disabled = e < Cout_15

func _try_spend(cost: float) -> void:
	gold_manager.spend(cost)

func _on_gold_changed(current: float, max_value: float) -> void:
	_refresh_ui(current, max_value)

func _on_gold_spent(_cost: float) -> void:
	_pulse_bar()

func _on_gold_not_enough(cost: float) -> void:
	_shake_label("Pas assez d’élixir (coût: %d) !" % int(cost))

func _refresh_ui(current: float, max_value: float) -> void:
	bar.value = current
	label.text = "GOLD : %.1f / %.0f" % [current, max_value]

func _pulse_bar() -> void:
	var tween := create_tween()


func _shake_label(msg: String) -> void:
	label.text = msg
	var tween := create_tween()
