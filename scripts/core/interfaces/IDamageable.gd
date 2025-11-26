class_name IDamageable
extends RefCounted

## Interface pour toute entité pouvant recevoir des dégâts.
##
## Implémente cette interface pour permettre à une entité de :
## - Recevoir des dégâts d'une source
## - Exposer son état de santé
## - Se soigner
##
## @tutorial: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html#interfaces

## Inflige des dégâts à cette entité.
##
## @param amount: Montant des dégâts à infliger (positif)
## @param attacker: Source des dégâts (peut être null)
func take_damage(_amount: int, _attacker: Node2D = null) -> void:
	push_error("take_damage() must be implemented")

## Retourne la santé actuelle de l'entité.
##
## @return: Points de vie actuels
func get_health() -> int:
	push_error("get_health() must be implemented")
	return 0

## Retourne la santé maximale de l'entité.
##
## @return: Points de vie maximum
func get_max_health() -> int:
	push_error("get_max_health() must be implemented")
	return 0

## Soigne l'entité d'un montant donné.
##
## @param amount: Montant de soin (positif)
## @return: Montant réellement soigné (peut être inférieur si déjà à max)
func heal(_amount: int) -> int:
	push_error("heal() must be implemented")
	return 0

## Retourne si l'entité est encore vivante.
##
## @return: true si vivante, false sinon
func is_alive() -> bool:
	return get_health() > 0
