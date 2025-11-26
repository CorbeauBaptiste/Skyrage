class_name ISelectable
extends RefCounted

## Interface pour toute entité pouvant être sélectionnée par le joueur.
##
## Implémente cette interface pour permettre :
## - La sélection/désélection visuelle
## - L'assignation de cibles
## - Le contrôle par le joueur
##
## @tutorial: Utilisé par SelectionManager

## Sélectionne ou désélectionne cette entité.
##
## @param is_selected: true pour sélectionner, false pour désélectionner
func set_selected(_is_selected: bool) -> void:
	push_error("set_selected() must be implemented")

## Retourne si l'entité est actuellement sélectionnée.
##
## @return: true si sélectionnée, false sinon
func is_selected() -> bool:
	push_error("is_selected() must be implemented")
	return false

## Assigne une cible ou une position à atteindre.
##
## @param target: Position Vector2 ou Node2D à atteindre
func set_target(_target: Variant) -> void:
	push_error("set_target() must be implemented")

## Retourne si l'entité peut être sélectionnée par ce camp.
##
## @param selecting_side: Camp qui tente la sélection (true = Enfer, false = Paradis)
## @return: true si sélectionnable, false sinon
func can_be_selected_by(_selecting_side: bool) -> bool:
	push_error("can_be_selected_by() must be implemented")
	return false
