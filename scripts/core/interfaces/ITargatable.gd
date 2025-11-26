class_name ITargetable
extends RefCounted

## Interface pour toute entité pouvant être ciblée.
##
## Implémente cette interface pour qu'une entité puisse :
## - Être ciblée par des unités ou projectiles
## - Exposer sa position
## - Indiquer son camp
##
## @tutorial: Utilisé par le système de ciblage et de combat

## Retourne la position globale de l'entité.
##
## @return: Position dans le monde
func get_global_position() -> Vector2:
	push_error("get_global_position() must be implemented")
	return Vector2.ZERO

## Retourne le camp de l'entité.
##
## @return: true si Enfer, false si Paradis
func get_side() -> bool:
	push_error("get_side() must be implemented")
	return false

## Vérifie si l'entité est un ennemi pour une autre entité.
##
## @param other_side: Camp à comparer (true = Enfer, false = Paradis)
## @return: true si ennemi, false sinon
func is_enemy_of(other_side: bool) -> bool:
	return get_side() != other_side

## Retourne si l'entité est toujours valide et ciblable.
##
## @return: true si peut être ciblée, false sinon
func is_valid_target() -> bool:
	push_error("is_valid_target() must be implemented")
	return false
