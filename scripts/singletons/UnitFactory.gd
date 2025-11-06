class_name UnitFactory
extends Node

# Singleton
static var instance: UnitFactory

func _init():
	if instance == null:
		instance = self

## Crée une nouvelle unité avec tous ses composants
static func create_unit(unit_scene: PackedScene, position: Vector2, faction: String) -> Node2D:
	if !unit_scene:
		push_error("Unit scene is null!")
		return null
	
	# Instancie l'unité
	var unit = unit_scene.instantiate()
	if not unit is Node2D:
		push_error("Unit must be a Node2D!")
		return null
	
	# Configure les propriétés de base
	unit.global_position = position
	unit.is_hell_faction = (faction == "hell")
	
	# Ajoute les composants nécessaires
	_add_components(unit)
	
	return unit

## Ajoute les composants à une unité
static func _add_components(unit: Node2D) -> void:
	# Vérifie si les composants existent déjà
	if not unit.has_node("HealthComponent"):
		var health = Node.new()
		health.name = "HealthComponent"
		health.set_script(load("res://scripts/entities/units/components/UnitHealthComponent.gd"))
		unit.add_child(health)
		
	if not unit.has_node("MovementComponent"):
		var movement = Node.new()
		movement.name = "MovementComponent"
		movement.set_script(load("res://scripts/entities/units/components/UnitMovementComponent.gd"))
		unit.add_child(movement)
		
	if not unit.has_node("CombatComponent"):
		var combat = Node.new()
		combat.name = "CombatComponent"
		combat.set_script(load("res://scripts/entities/units/components/UnitCombatComponent.gd"))
		unit.add_child(combat)
		
	if not unit.has_node("TargetingComponent"):
		var targeting = Node.new()
		targeting.name = "TargetingComponent"
		targeting.set_script(load("res://scripts/entities/units/components/UnitTargetingComponent.gd"))
		unit.add_child(targeting)
