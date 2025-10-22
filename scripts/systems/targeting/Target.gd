class_name Target
extends RefCounted

## Système de ciblage générique et réutilisable.
##
## Permet de définir qui/quoi est ciblé par un effet, une compétence ou un item.
## Architecture extensible pour ajouter de nouveaux types de ciblage.
##
## @tutorial: Utilisé pour les items, compétences, sorts, effets de zone, etc.

# ========================================
# ÉNUMÉRATIONS
# ========================================

## Type de ciblage.
enum TargetType {
	SELF,              # Uniquement soi-même
	SINGLE_ALLY,       # Un allié spécifique
	ALL_ALLIES,        # Tous les alliés
	SINGLE_ENEMY,      # Un ennemi spécifique
	ALL_ENEMIES,       # Tous les ennemis
	ALLY_BASE,         # La base alliée
	ENEMY_BASE,        # La base ennemie
	ALL_UNITS,         # Toutes les unités (alliés + ennemis)
	PLAYER,            # Le joueur (pour effets d'or, etc.)
	AREA,              # Zone géographique (AoE)
	CUSTOM             # Ciblage personnalisé via fonction
}

## Filtre sur les cibles.
enum TargetFilter {
	NONE,              # Pas de filtre
	DAMAGED,           # Uniquement les unités blessées
	LOW_HEALTH,        # Unités en dessous de X% PV
	HIGH_HEALTH,       # Unités au-dessus de X% PV
	SIZE_S,            # Uniquement taille S
	SIZE_M,            # Uniquement taille M
	SIZE_L,            # Uniquement taille L
	IN_COMBAT,         # Uniquement celles en combat
	IDLE,              # Uniquement celles inactives
	CUSTOM             # Filtre personnalisé
}

# ========================================
# PROPRIÉTÉS
# ========================================

## Type de ciblage principal.
var target_type: TargetType = TargetType.SELF

## Filtre optionnel sur les cibles.
var filter: TargetFilter = TargetFilter.NONE

## Nombre maximum de cibles (0 = illimité).
var max_targets: int = 0

## Rayon pour ciblage AREA (en pixels).
var area_radius: float = 0.0

## Position centrale pour ciblage AREA.
var area_center: Vector2 = Vector2.ZERO

## Seuil pour les filtres LOW_HEALTH / HIGH_HEALTH (pourcentage 0.0-1.0).
var health_threshold: float = 0.5

## Fonction personnalisée pour CUSTOM (callable).
var custom_filter: Callable = Callable()

# ========================================
# CONSTRUCTEURS STATIQUES (FACTORY)
# ========================================

## Cible soi-même uniquement.
static func self_target() -> Target:
	var t := Target.new()
	t.target_type = TargetType.SELF
	return t


## Cible tous les alliés.
static func all_allies() -> Target:
	var t := Target.new()
	t.target_type = TargetType.ALL_ALLIES
	return t


## Cible tous les alliés blessés (pour soins).
static func wounded_allies(max_count: int = 0) -> Target:
	var t := Target.new()
	t.target_type = TargetType.ALL_ALLIES
	t.filter = TargetFilter.DAMAGED
	t.max_targets = max_count
	return t


## Cible tous les ennemis.
static func all_enemies() -> Target:
	var t := Target.new()
	t.target_type = TargetType.ALL_ENEMIES
	return t


## Cible la base alliée.
static func ally_base() -> Target:
	var t := Target.new()
	t.target_type = TargetType.ALLY_BASE
	return t


## Cible la base ennemie.
static func enemy_base() -> Target:
	var t := Target.new()
	t.target_type = TargetType.ENEMY_BASE
	return t


## Cible le joueur (pour effets d'or, etc.).
static func player_target() -> Target:
	var t := Target.new()
	t.target_type = TargetType.PLAYER
	return t


## Cible une zone circulaire.
static func area_of_effect(center: Vector2, radius: float) -> Target:
	var t := Target.new()
	t.target_type = TargetType.AREA
	t.area_center = center
	t.area_radius = radius
	return t


## Cible personnalisée via fonction.
static func custom_target(filter_func: Callable) -> Target:
	var t := Target.new()
	t.target_type = TargetType.CUSTOM
	t.custom_filter = filter_func
	return t

# ========================================
# RÉSOLUTION DES CIBLES
# ========================================

## Résout et retourne les entités ciblées.
##
## @param source: Entité source (qui déclenche le ciblage)
## @param world: Node racine du monde (pour chercher les entités)
## @return: Array des entités ciblées
func resolve(source: Node, world: Node) -> Array:
	var targets: Array = []
	
	match target_type:
		TargetType.SELF:
			targets = [source]
		
		TargetType.ALL_ALLIES:
			targets = _find_all_allies(source, world)
		
		TargetType.ALL_ENEMIES:
			targets = _find_all_enemies(source, world)
		
		TargetType.ALLY_BASE:
			targets = _find_ally_base(source, world)
		
		TargetType.ENEMY_BASE:
			targets = _find_enemy_base(source, world)
		
		TargetType.PLAYER:
			targets = _find_player(source, world)
		
		TargetType.ALL_UNITS:
			targets = _find_all_units(world)
		
		TargetType.AREA:
			targets = _find_in_area(world)
		
		TargetType.CUSTOM:
			if custom_filter.is_valid():
				targets = custom_filter.call(source, world)
	
	# Applique les filtres
	if filter != TargetFilter.NONE:
		targets = _apply_filter(targets)
	
	# Limite le nombre de cibles
	if max_targets > 0 and targets.size() > max_targets:
		targets = targets.slice(0, max_targets)
	
	return targets

# ========================================
# FONCTIONS INTERNES DE RECHERCHE
# ========================================

func _find_all_allies(source: Node, world: Node) -> Array:
	## Trouve tous les alliés.
	var allies: Array = []
	
	if not source.has_method("get_side"):
		return allies
	
	var source_side: bool = source.get_side()
	
	for unit in world.get_tree().get_nodes_in_group("units"):
		if not is_instance_valid(unit):
			continue
		if not (unit is Unit):
			continue
		if unit.get_side() == source_side:
			allies.append(unit)
	
	return allies


func _find_all_enemies(source: Node, world: Node) -> Array:
	## Trouve tous les ennemis.
	var enemies: Array = []
	
	if not source.has_method("get_side"):
		return enemies
	
	var source_side: bool = source.get_side()
	
	for unit in world.get_tree().get_nodes_in_group("units"):
		if not is_instance_valid(unit):
			continue
		if not (unit is Unit):
			continue
		if unit.get_side() != source_side:
			enemies.append(unit)
	
	return enemies


func _find_ally_base(source: Node, world: Node) -> Array:
	## Trouve la base alliée.
	if not source.has_method("get_side"):
		return []
	
	var source_side: bool = source.get_side()
	
	for base in world.get_tree().get_nodes_in_group("bases"):
		if not is_instance_valid(base):
			continue
		if not (base is Base):
			continue
		if base.get_side() == source_side:
			return [base]
	
	return []


func _find_enemy_base(source: Node, world: Node) -> Array:
	## Trouve la base ennemie.
	if not source.has_method("get_side"):
		return []
	
	var source_side: bool = source.get_side()
	
	for base in world.get_tree().get_nodes_in_group("bases"):
		if not is_instance_valid(base):
			continue
		if not (base is Base):
			continue
		if base.get_side() != source_side:
			return [base]
	
	return []


func _find_player(source: Node, world: Node) -> Array:
	## Trouve le joueur.
	if not source.has_method("get_side"):
		return []
	
	var source_side: bool = source.get_side()
	
	for base in world.get_tree().get_nodes_in_group("bases"):
		if not is_instance_valid(base):
			continue
		if not (base is Base):
			continue
		if base.get_side() == source_side:
			if base.player:
				return [base.player]
			break
	
	return []


func _find_all_units(world: Node) -> Array:
	var units: Array = []
	for unit in world.get_tree().get_nodes_in_group("units"):
		if unit is Unit:
			units.append(unit)
	return units


func _find_in_area(world: Node) -> Array:
	var in_area: Array = []
	
	for unit in world.get_tree().get_nodes_in_group("units"):
		if unit is Unit:
			var distance: float = unit.global_position.distance_to(area_center)
			if distance <= area_radius:
				in_area.append(unit)
	
	return in_area

# ========================================
# FILTRES
# ========================================

func _apply_filter(targets_input: Array) -> Array:
	var filtered: Array = []
	
	match filter:
		TargetFilter.DAMAGED:
			for target in targets_input:
				if target is Unit and target.health_component:
					if target.health_component.get_missing_health() > 0:
						filtered.append(target)
		
		TargetFilter.LOW_HEALTH:
			for target in targets_input:
				if target is Unit and target.health_component:
					if target.health_component.get_health_percent() < health_threshold:
						filtered.append(target)
		
		TargetFilter.HIGH_HEALTH:
			for target in targets_input:
				if target is Unit and target.health_component:
					if target.health_component.get_health_percent() > health_threshold:
						filtered.append(target)
		
		TargetFilter.SIZE_S:
			for target in targets_input:
				if target is Unit and target.unit_size == "S":
					filtered.append(target)
		
		TargetFilter.SIZE_M:
			for target in targets_input:
				if target is Unit and target.unit_size == "M":
					filtered.append(target)
		
		TargetFilter.SIZE_L:
			for target in targets_input:
				if target is Unit and target.unit_size == "L":
					filtered.append(target)
		
		TargetFilter.IN_COMBAT:
			for target in targets_input:
				if target is Unit and target.combat_component:
					if target.combat_component.current_target != null:
						filtered.append(target)
		
		TargetFilter.IDLE:
			for target in targets_input:
				if target is Unit and target.combat_component:
					if target.combat_component.current_target == null:
						filtered.append(target)
		
		TargetFilter.CUSTOM:
			if custom_filter.is_valid():
				filtered = custom_filter.call(targets_input)
		
		_:
			filtered = targets_input
	
	return filtered
