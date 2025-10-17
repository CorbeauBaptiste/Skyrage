extends Control

@onready var bar: ProgressBar = %GoldBar
@onready var label: Label = %GoldLabel
@onready var btn_archange: Button = %BtnCost5   # Archange (S)
@onready var btn_ange: Button = %BtnCost10      # Ange/Chérubin (M)
@onready var btn_seraphin: Button = %BtnCost15  # Séraphin (L)
@onready var gold_manager: GoldManagerParadise = %GoldManager

var cout_archange: float = Constants.UNIT_COSTS["archange"]
var cout_ange: float = Constants.UNIT_COSTS["ange"]
var cout_seraphin: float = Constants.UNIT_COSTS["seraphin"]

var is_phase_on: bool = true
var buttons_forced_disabled: bool = false

signal btn_archange_pressed
signal btn_ange_pressed
signal btn_seraphin_pressed
signal phase_changed(is_active: bool)

func _ready() -> void:
	bar.min_value = 0.0
	bar.max_value = gold_manager.max_gold
	_refresh_ui(gold_manager.current_gold, gold_manager.max_gold)

	gold_manager.gold_changed.connect(_on_gold_changed)
	gold_manager.gold_spent.connect(_on_gold_spent)

	btn_archange.pressed.connect(func(): _try_spend(cout_archange, "archange"))
	btn_ange.pressed.connect(func(): _try_spend(cout_ange, "ange"))
	btn_seraphin.pressed.connect(func(): _try_spend(cout_seraphin, "seraphin"))

	_enter_phase(true)
	_run_cycle()

func _process(_delta: float) -> void:
	if buttons_forced_disabled:
		btn_archange.disabled = true
		btn_ange.disabled = true
		btn_seraphin.disabled = true
	else:
		var gold = gold_manager.current_gold
		btn_archange.disabled = gold < cout_archange
		btn_ange.disabled = gold < cout_archange
		btn_seraphin.disabled = gold < cout_seraphin

func _try_spend(cost: float, unit_type: String) -> void:
	if not is_phase_on:
		return
	
	if gold_manager.spend(cost):
		match unit_type:
			"archange":
				emit_signal("btn_archange_pressed")
			"ange":
				emit_signal("btn_ange_pressed")
			"seraphin":
				emit_signal("btn_seraphin_pressed")

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

func _run_cycle() -> void:
	while true:
		await get_tree().create_timer(Constants.PHASE_DURATION).timeout
		_enter_phase(not is_phase_on)

func _enter_phase(phase_on: bool) -> void:
	is_phase_on = phase_on
	emit_signal("phase_changed", phase_on)
	if is_phase_on:
		buttons_forced_disabled = false
		gold_manager.set_process(true)
		_refresh_ui(gold_manager.current_gold, gold_manager.max_gold)
	else:
		buttons_forced_disabled = true
		gold_manager.set_process(false)
