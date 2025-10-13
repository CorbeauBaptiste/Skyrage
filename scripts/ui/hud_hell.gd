extends Control

@onready var bar: ProgressBar = %GoldBarE
@onready var label: Label = %GoldLabelE
@onready var btn_diablotin: Button = %BtnCost6   # Diablotin (S)
@onready var btn_ange_dechu: Button = %BtnCost11 # Ange Déchu (M)
@onready var btn_demon: Button = %BtnCost16      # Démon (L)
@onready var gold_manager: GoldManagerParadise = %GoldManagerE

const COUT_DIABLOTIN := 0.0 # S - 3 apparitions
const COUT_ANGE_DECHU := 0.0  # M - 2 apparitions
const COUT_DEMON := 0.0       # L - 1 apparition

const PHASE_DURATION := 12.0
var is_phase_on: bool = false
var buttons_forced_disabled: bool = false

signal btn_diablotin_pressed
signal btn_ange_dechu_pressed
signal btn_demon_pressed
signal phase_changed(is_active: bool)

func _ready() -> void:
	bar.min_value = 0.0
	bar.max_value = gold_manager.max_gold
	_refresh_ui(gold_manager.current_gold, gold_manager.max_gold)

	gold_manager.gold_changed.connect(_on_gold_changed)
	gold_manager.gold_spent.connect(_on_gold_spent)

	btn_diablotin.pressed.connect(func(): _try_spend(COUT_DIABLOTIN, "diablotin"))
	btn_ange_dechu.pressed.connect(func(): _try_spend(COUT_ANGE_DECHU, "ange_dechu"))
	btn_demon.pressed.connect(func(): _try_spend(COUT_DEMON, "demon"))

	_enter_phase(false)
	_run_cycle()

func _process(_delta: float) -> void:
	if buttons_forced_disabled:
		btn_diablotin.disabled = true
		btn_ange_dechu.disabled = true
		btn_demon.disabled = true
	else:
		var gold = gold_manager.current_gold
		btn_diablotin.disabled = gold < COUT_DIABLOTIN
		btn_ange_dechu.disabled = gold < COUT_ANGE_DECHU
		btn_demon.disabled = gold < COUT_DEMON

func _try_spend(cost: float, unit_type: String) -> void:
	if not is_phase_on:
		return
	
	if gold_manager.spend(cost):
		match unit_type:
			"diablotin":
				emit_signal("btn_diablotin_pressed")
			"ange_dechu":
				emit_signal("btn_ange_dechu_pressed")
			"demon":
				emit_signal("btn_demon_pressed")

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
		await get_tree().create_timer(PHASE_DURATION).timeout
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
