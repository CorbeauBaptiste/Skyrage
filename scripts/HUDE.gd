extends Control

@onready var bar: ProgressBar           = %GoldBarE
@onready var label: Label               = %GoldLabelE
@onready var btn2: Button               = %BtnCost6
@onready var btn4: Button               = %BtnCost11
@onready var btn6: Button               = %BtnCost16
@onready var gold_manager: goldManager = %GoldManagerE



const Cout_6  := 6.0
const Cout_11 := 11.0
const Cout_16 := 16.0

const PHASE_DURATION := 30.0
var is_phase_on: bool = false
var buttons_forced_disabled: bool = false

signal btn2_pressed
signal btn4_pressed
signal btn6_pressed

func _ready() -> void:
	bar.min_value = 0.0
	bar.max_value = gold_manager.max_gold
	_refresh_ui(gold_manager.current_gold, gold_manager.max_gold)

	gold_manager.gold_changed.connect(_on_gold_changed)
	gold_manager.gold_spent.connect(_on_gold_spent)

	btn2.pressed.connect(func(): _try_spend(Cout_6))
	btn2.pressed.connect(func(): emit_signal("btn2_pressed"))
	btn4.pressed.connect(func(): _try_spend(Cout_11))
	btn4.pressed.connect(func(): emit_signal("btn4_pressed"))
	btn6.pressed.connect(func(): _try_spend(Cout_16))
	btn2.pressed.connect(func(): emit_signal("btn6_pressed"))

	_enter_phase(false)
	_run_cycle()

func _process(_delta: float) -> void:
	if buttons_forced_disabled:
		btn2.disabled = true
		btn4.disabled = true
		btn6.disabled = true
	else:
		var e = gold_manager.current_gold
		btn2.disabled = e < Cout_6
		btn4.disabled = e < Cout_11
		btn6.disabled = e < Cout_16
		

func _try_spend(cost: float) -> void:
	if not is_phase_on:
		return
	gold_manager.spend(cost)

func _on_gold_changed(current: float, max_value: float) -> void:
	if is_phase_on:
		_refresh_ui(current, max_value)

func _on_gold_spent(_cost: float) -> void:
	_pulse_bar()

func _refresh_ui(current: float, max_value: float) -> void:
	bar.value = current
	label.text = "GOLD : %.1f / %.0f" % [current, max_value]

func _pulse_bar() -> void:
	var tween := create_tween()

func _shake_label(msg: String) -> void:
	label.text = msg
	var tween := create_tween()

func _run_cycle() -> void:
	while true:
		await get_tree().create_timer(PHASE_DURATION).timeout
		_enter_phase(not is_phase_on)  

func _enter_phase(phase_on: bool) -> void:
	is_phase_on = phase_on
	if is_phase_on:
		buttons_forced_disabled = false
		gold_manager.set_process(true)
		_refresh_ui(gold_manager.current_gold, gold_manager.max_gold)
	else:
		buttons_forced_disabled = true
		gold_manager.set_process(false)
