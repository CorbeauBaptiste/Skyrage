extends Control

## HUD du camp Paradis.
##
## Affiche et gère :
## - La barre d'or et son label
## - Les boutons de spawn d'unités
## - Le système de phases (alternance Paradis/Enfer)
## - Les coûts et la disponibilité des unités

# ========================================
# NODES
# ========================================

@onready var bar: ProgressBar = %GoldBar
@onready var label: Label = %GoldLabel
@onready var btn_archange: Button = %BtnCost5
@onready var btn_ange: Button = %BtnCost10
@onready var btn_seraphin: Button = %BtnCost15
@onready var gold_manager: GoldManager = %GoldManager

# ========================================
# COÛTS DES UNITÉS
# ========================================

var cout_archange: float = Constants.UNIT_COSTS["archange"]
var cout_ange: float = Constants.UNIT_COSTS["ange"]
var cout_seraphin: float = Constants.UNIT_COSTS["seraphin"]

# ========================================
# ÉTAT DES PHASES
# ========================================

## Si la phase Paradis est active.
var is_phase_on: bool = true

## Si les boutons sont forcés désactivés.
var buttons_forced_disabled: bool = false

# ========================================
# SIGNAUX
# ========================================

## Émis quand le bouton Archange est pressé.
signal btn_archange_pressed

## Émis quand le bouton Ange est pressé.
signal btn_ange_pressed

## Émis quand le bouton Séraphin est pressé.
signal btn_seraphin_pressed

## Émis quand la phase change.
signal phase_changed(is_active: bool)

# ========================================
# INITIALISATION
# ========================================

func _ready() -> void:
	bar.min_value = 0.0
	bar.max_value = gold_manager.max_gold
	_refresh_ui(gold_manager.current_gold, gold_manager.max_gold)

	# Connexions signaux gold
	gold_manager.gold_changed.connect(_on_gold_changed)
	gold_manager.gold_spent.connect(_on_gold_spent)

	# Connexions boutons
	btn_archange.pressed.connect(func(): _try_spend(cout_archange, "archange"))
	btn_ange.pressed.connect(func(): _try_spend(cout_ange, "ange"))
	btn_seraphin.pressed.connect(func(): _try_spend(cout_seraphin, "seraphin"))
	
	_enter_phase(true)

	"(Tour par tour)# Démarre la phase Paradis
	_run_cycle()"

# ========================================
# UPDATE
# ========================================

func _process(_delta: float) -> void:
	"# (Tour par tour) Gestion de la disponibilité des boutons
	if buttons_forced_disabled:
		btn_archange.disabled = true
		btn_ange.disabled = true
		btn_seraphin.disabled = true
	else:"
	
	var gold: float = gold_manager.current_gold
	btn_archange.disabled = gold < cout_archange
	btn_ange.disabled = gold < cout_ange
	btn_seraphin.disabled = gold < cout_seraphin

# ========================================
# DÉPENSES
# ========================================

## Tente de dépenser de l'or pour spawner une unité.
##
## @param cost: Coût de l'unité
## @param unit_type: Type d'unité à spawner
func _try_spend(cost: float, unit_type: String) -> void:
	"(Tour par tour)
	if not is_phase_on:
		return"
	
	if gold_manager.spend(cost):
		match unit_type:
			"archange":
				emit_signal("btn_archange_pressed")
			"ange":
				emit_signal("btn_ange_pressed")
			"seraphin":
				emit_signal("btn_seraphin_pressed")

# ========================================
# CALLBACKS GOLD
# ========================================

## Callback quand l'or change.
##
## @param current: Or actuel
## @param max_value: Or maximum
func _on_gold_changed(current: float, max_value: float) -> void:
	if is_phase_on:
		_refresh_ui(current, max_value)


## Callback quand de l'or est dépensé.
##
## @param _cost: Coût dépensé (non utilisé)
func _on_gold_spent(_cost: float) -> void:
	_pulse_bar()
	_refresh_ui(gold_manager.current_gold, gold_manager.max_gold)

# ========================================
# UI
# ========================================

## Met à jour l'affichage de la barre et du label d'or.
##
## @param current: Or actuel
## @param max_value: Or maximum
func _refresh_ui(current: float, max_value: float) -> void:
	bar.value = current
	label.text = "GOLD : %.1f / %.0f" % [current, max_value]


## Animation visuelle de la barre lors d'une dépense.
func _pulse_bar() -> void:
	var tween: Tween = create_tween()
	# Animation à compléter si nécessaire

# ========================================
# SYSTÈME DE PHASES
# ========================================

## Boucle infinie gérant l'alternance des phases.
func _run_cycle() -> void:
	while true:
		await get_tree().create_timer(Constants.PHASE_DURATION).timeout
		_enter_phase(is_phase_on)


## Entre dans une phase (active ou inactive).
##
## @param phase_on: true si phase active, false sinon
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
