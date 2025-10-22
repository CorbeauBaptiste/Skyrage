class_name UnitSelectionComponent
extends Node

## Component gérant la sélection visuelle d'une unité.
##
## Responsabilités :
## - Gérer l'état sélectionné/non sélectionné
## - Appliquer un feedback visuel
## - Vérifier si l'unité peut être sélectionnée
##
## @tutorial: Utilisé par SelectionManager et ISelectable

## Émis quand l'état de sélection change.
## @param is_selected: Nouvel état
signal selection_changed(is_selected: bool)

## Couleur quand sélectionné.
@export var selected_color: Color = Color.AQUA

## Couleur par défaut (dépend du camp).
@export var default_color: Color = Color.WHITE

## Si l'unité est actuellement sélectionnée.
var is_selected: bool = false

## Nodes requis.
var _sprite: Sprite2D = null
var _parent_unit: Node2D = null


func _ready() -> void:
	_parent_unit = get_parent()
	_sprite = _parent_unit.get_node_or_null("Sprite2D")
	
	if _sprite:
		_update_visual()


## Définit l'état de sélection.
##
## @param selected: true pour sélectionner, false pour désélectionner
func set_selected(selected: bool) -> void:
	if is_selected == selected:
		return
	
	is_selected = selected
	_update_visual()
	selection_changed.emit(is_selected)


## Met à jour l'apparence visuelle selon l'état.
func _update_visual() -> void:
	if not _sprite:
		return
	
	if is_selected:
		_sprite.self_modulate = selected_color
	else:
		_sprite.self_modulate = default_color


## Vérifie si l'unité peut être sélectionnée par un camp.
##
## @param selecting_side: Camp qui tente la sélection (true = Enfer, false = Paradis)
## @return: true si sélectionnable
func can_be_selected_by(selecting_side: bool) -> bool:
	if not _parent_unit.has("is_hell_faction"):
		return false
	
	return _parent_unit.is_hell_faction == selecting_side


## Réinitialise la couleur par défaut selon le camp.
func reset_default_color() -> void:
	if not _parent_unit.has("is_hell_faction"):
		return
	
	default_color = Color.RED if _parent_unit.is_hell_faction else Color.WHITE
	
	if not is_selected:
		_update_visual()
