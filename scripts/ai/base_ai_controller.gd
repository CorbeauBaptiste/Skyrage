class_name BaseAIController
extends Node

## Contrôleur IA pour la gestion économique d'une base.
##
## Décide automatiquement quand et quelles unités acheter.
## Utilise le gold_component de la base pour les achats.

# ========================================
# CONFIGURATION
# ========================================

## Camp contrôlé par l'IA ("enfer" ou "paradis")
var team: String = ""

## Référence à la base contrôlée
var base: Base = null

## Référence au world pour spawner les unités
var world: Node = null

## Timer entre chaque décision d'achat
var decision_timer: Timer = null

## Intervalle entre les décisions (en secondes)
const DECISION_INTERVAL: float = 3.0

## Temps écoulé depuis le début du match
var match_time: float = 0.0

## Compteur d'achats pour varier les unités
var purchase_count: int = 0

# ========================================
# UNITÉS DISPONIBLES PAR CAMP
# ========================================

var unit_types: Dictionary = {
	"enfer": ["diablotin", "ange_dechu", "demon"],
	"paradis": ["archange", "ange", "seraphin"]
}

# ========================================
# INITIALISATION
# ========================================

func _ready() -> void:
	set_process(true)


## Configure l'IA avec sa base et le world.
func setup(p_base: Base, p_world: Node) -> void:
	base = p_base
	world = p_world
	team = base.team

	# Créer le timer de décision
	decision_timer = Timer.new()
	decision_timer.wait_time = DECISION_INTERVAL
	decision_timer.timeout.connect(_on_decision_timer)
	decision_timer.autostart = true
	add_child(decision_timer)

	print("[IA %s] Initialisée" % team.capitalize())


func _process(delta: float) -> void:
	match_time += delta

# ========================================
# PRISE DE DÉCISION
# ========================================

func _on_decision_timer() -> void:
	if not base or not base.gold_component:
		return

	var gold: float = base.gold_component.get_current_gold()
	var unit_to_buy: String = _choose_unit(gold)

	if unit_to_buy != "":
		_buy_unit(unit_to_buy)


## Choisit quelle unité acheter en fonction de l'or et du contexte.
func _choose_unit(gold: float) -> String:
	var available_units: Array = unit_types[team]

	# Récupérer les coûts
	var costs: Dictionary = {}
	for unit_type in available_units:
		costs[unit_type] = Constants.UNIT_COSTS[unit_type]

	# Stratégie basée sur le temps de match
	var strategy: String = _get_current_strategy()

	match strategy:
		"early":
			return _early_game_decision(gold, available_units, costs)
		"mid":
			return _mid_game_decision(gold, available_units, costs)
		"late":
			return _late_game_decision(gold, available_units, costs)

	return ""


## Détermine la stratégie actuelle basée sur le temps.
func _get_current_strategy() -> String:
	if match_time < 60.0:
		return "early"
	elif match_time < 180.0:
		return "mid"
	else:
		return "late"


## Décision early game : mix S/M pour une armée équilibrée.
func _early_game_decision(gold: float, units: Array, costs: Dictionary) -> String:
	var small_unit: String = units[0]  # diablotin ou archange
	var medium_unit: String = units[1]  # ange_dechu ou ange

	# Alterner : 2 achats S, puis 1 achat M
	if purchase_count % 3 < 2:
		if gold >= costs[small_unit]:
			return small_unit
	else:
		if gold >= costs[medium_unit]:
			return medium_unit
		if gold >= costs[small_unit]:
			return small_unit

	return ""


## Décision mid game : mix équilibré S/M/L.
func _mid_game_decision(gold: float, units: Array, costs: Dictionary) -> String:
	var small_unit: String = units[0]
	var medium_unit: String = units[1]
	var large_unit: String = units[2]

	# Cycle : S, M, S, L (répétition)
	var cycle_pos: int = purchase_count % 4

	if cycle_pos == 0 or cycle_pos == 2:
		if gold >= costs[small_unit]:
			return small_unit
	elif cycle_pos == 1:
		if gold >= costs[medium_unit]:
			return medium_unit
		if gold >= costs[small_unit]:
			return small_unit
	else:  # cycle_pos == 3
		if gold >= costs[large_unit]:
			return large_unit
		if gold >= costs[medium_unit]:
			return medium_unit

	return ""


## Décision late game : priorité aux unités L et M.
func _late_game_decision(gold: float, units: Array, costs: Dictionary) -> String:
	var small_unit: String = units[0]
	var medium_unit: String = units[1]
	var large_unit: String = units[2]

	# Cycle : L, M, L, M (priorité aux grosses unités)
	var cycle_pos: int = purchase_count % 4

	if cycle_pos == 0 or cycle_pos == 2:
		if gold >= costs[large_unit]:
			return large_unit
		if gold >= costs[medium_unit]:
			return medium_unit
	else:
		if gold >= costs[medium_unit]:
			return medium_unit
		if gold >= costs[small_unit]:
			return small_unit

	return ""

# ========================================
# ACHAT D'UNITÉS
# ========================================

## Achète une unité via le système de spawn.
func _buy_unit(unit_type: String) -> void:
	if not world or not base:
		return

	var cost: float = Constants.UNIT_COSTS[unit_type]

	# Vérifier si assez d'or
	if not base.gold_component.can_spend(cost):
		return

	# Dépenser l'or
	if not base.gold_component.spend(cost):
		return

	purchase_count += 1
	print("[IA %s] Achat #%d: %s (%.1f or)" % [team.capitalize(), purchase_count, unit_type, cost])

	# Spawner les unités
	_spawn_units(unit_type)


## Spawne les unités achetées.
func _spawn_units(unit_type: String) -> void:
	var unit_scene: PackedScene = Constants.UNITS[team][unit_type]
	var count: int = Constants.SPAWN_COUNTS[unit_type]

	for i in range(count):
		await base.spawn_unit_no_cost(unit_scene)
		if i < count - 1:
			await get_tree().create_timer(0.5).timeout
