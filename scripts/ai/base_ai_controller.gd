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


## Évalue le nombre d'unités alliées vs ennemies.
## Retourne un ratio : valeurs négatives = on est en infériorité numérique
func _evaluate_unit_balance() -> Dictionary:
	if not base or not base.is_inside_tree():
		return {"allied": 0, "enemy": 0, "ratio": 0.0}

	var allied_count := 0
	var enemy_count := 0

	for unit in base.get_tree().get_nodes_in_group("units"):
		if not is_instance_valid(unit) or not (unit is Unit):
			continue

		var unit_typed := unit as Unit
		if unit_typed.is_hell_faction == (team == "enfer"):
			allied_count += 1
		else:
			enemy_count += 1

	var ratio := 0.0
	if enemy_count > 0:
		ratio = float(allied_count) / float(enemy_count)

	return {
		"allied": allied_count,
		"enemy": enemy_count,
		"ratio": ratio
	}


## Ajuste les probabilités en fonction du surnombre ennemi.
## Si l'ennemi a beaucoup d'unités, favorise les S (spawn rapide et nombreux).
## Retourne un modificateur : {"S": +%, "M": ±%, "L": -%}
func _get_counter_strategy_modifier() -> Dictionary:
	var balance := _evaluate_unit_balance()
	var modifier := {"S": 0.0, "M": 0.0, "L": 0.0}

	# Si ratio < 0.7 : on est en infériorité (ex: 7 vs 10)
	if balance.ratio < 0.7 and balance.enemy > 5:
		# CONTRE-STRATÉGIE : Spam de S pour compenser en nombre
		modifier.S = +0.20  # +20% de chance pour S
		modifier.M = +0.05  # +5% pour M
		modifier.L = -0.25  # -25% pour L

		print("[IA %s] DÉFENSIVE - Surnombre ennemi (%d vs %d) - Favorise S" % [
			team.capitalize(), balance.allied, balance.enemy
		])

	# Si ratio > 1.3 : on est en supériorité (ex: 13 vs 10)
	elif balance.ratio > 1.3 and balance.allied > 5:
		# STRATÉGIE AGRESSIVE : Grosses unités pour finir
		modifier.S = -0.15  # -15% pour S
		modifier.M = +0.05  # +5% pour M
		modifier.L = +0.10  # +10% pour L

		print("[IA %s] OFFENSIVE - Supériorité (%d vs %d) - Favorise L" % [
			team.capitalize(), balance.allied, balance.enemy
		])

	return modifier


## Décision early game : mix S/M pour une armée équilibrée avec aléatoire.
func _early_game_decision(gold: float, units: Array, costs: Dictionary) -> String:
	var small_unit: String = units[0]  # diablotin ou archange
	var medium_unit: String = units[1]  # ange_dechu ou ange

	# Priorités : 70% S, 30% M (si assez d'or)
	var rand: float = randf()

	if rand < 0.7:  # 70% chance d'acheter S
		if gold >= costs[small_unit]:
			return small_unit
	else:  # 30% chance d'acheter M
		if gold >= costs[medium_unit]:
			return medium_unit
		elif gold >= costs[small_unit]:
			return small_unit

	return ""


## Décision mid game : mix équilibré S/M/L avec priorisation des L (maintenant à 13).
func _mid_game_decision(gold: float, units: Array, costs: Dictionary) -> String:
	var small_unit: String = units[0]
	var medium_unit: String = units[1]
	var large_unit: String = units[2]

	# Probabilités de base : 40% L, 35% M, 25% S
	var prob_L := 0.40
	var prob_M := 0.35
	var prob_S := 0.25

	# Ajustement dynamique selon la situation
	var modifier := _get_counter_strategy_modifier()
	prob_L += modifier.L
	prob_M += modifier.M
	prob_S += modifier.S

	# Normaliser pour que la somme = 1.0
	var total := prob_L + prob_M + prob_S
	prob_L /= total
	prob_M /= total
	prob_S /= total

	# Décider quel type d'unité viser
	var rand: float = randf()
	var target_unit: String = ""
	var target_cost: float = 0.0

	if rand < prob_L:
		target_unit = large_unit
		target_cost = costs[large_unit]
	elif rand < prob_L + prob_M:
		target_unit = medium_unit
		target_cost = costs[medium_unit]
	else:
		target_unit = small_unit
		target_cost = costs[small_unit]

	# N'acheter QUE si on a assez d'or pour l'unité visée
	if gold >= target_cost:
		return target_unit

	# Sinon, attendre
	return ""


## Décision late game : priorité maximale aux unités L et M.
func _late_game_decision(gold: float, units: Array, costs: Dictionary) -> String:
	var small_unit: String = units[0]
	var medium_unit: String = units[1]
	var large_unit: String = units[2]

	# Probabilités de base : 60% L, 30% M, 10% S
	var prob_L := 0.60
	var prob_M := 0.30
	var prob_S := 0.10

	# Ajustement dynamique selon la situation
	var modifier := _get_counter_strategy_modifier()
	prob_L += modifier.L
	prob_M += modifier.M
	prob_S += modifier.S

	# Normaliser pour que la somme = 1.0
	var total := prob_L + prob_M + prob_S
	prob_L /= total
	prob_M /= total
	prob_S /= total

	# Décider quel type d'unité viser
	var rand: float = randf()
	var target_unit: String = ""
	var target_cost: float = 0.0

	if rand < prob_L:
		target_unit = large_unit
		target_cost = costs[large_unit]
	elif rand < prob_L + prob_M:
		target_unit = medium_unit
		target_cost = costs[medium_unit]
	else:
		target_unit = small_unit
		target_cost = costs[small_unit]

	# N'acheter QUE si on a assez d'or pour l'unité visée
	if gold >= target_cost:
		return target_unit

	# Sinon, attendre
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
		if not is_inside_tree():
			return

		await base.spawn_unit_no_cost(unit_scene)

		if i < count - 1:
			if not is_inside_tree():
				return
			await get_tree().create_timer(0.5).timeout
