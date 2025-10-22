class_name ItemEffect
extends RefCounted

## Classe de base pour tous les effets d'items.
##
## Gère le cycle de vie d'un effet (application, update, expiration).
## Les effets concrets doivent hériter de cette classe.

## Item source de l'effet.
var item: Item

## Entités ciblées par l'effet.
var targets: Array = []

## Temps restant pour les effets à durée.
var duration_remaining: float = 0.0

## Utilisations restantes pour les effets à compteur.
var uses_remaining: int = 0

## Émis quand l'effet expire.
signal effect_expired()


func _init(effect_item: Item):
	item = effect_item


## Applique l'effet aux cibles spécifiées.
##
## @param target_nodes: Entités à cibler
func apply(target_nodes: Array) -> void:
	targets = target_nodes
	_on_apply()


## Méthode virtuelle à override pour appliquer l'effet.
func _on_apply() -> void:
	pass


## Met à jour l'effet chaque frame.
##
## @param delta: Temps écoulé
## @return: true si l'effet expire
func update(delta: float) -> bool:
	if item.effect_type == Item.EffectType.DURATION:
		duration_remaining -= delta
		if duration_remaining <= 0:
			_on_expire()
			effect_expired.emit()
			return true
	return false


## Méthode virtuelle à override pour nettoyer l'effet.
func _on_expire() -> void:
	pass


## Applique une animation de couleur au sprite d'une unité.
##
## @param target: Unité à animer
## @param flash_color: Couleur du flash
## @param duration_val: Durée de l'animation
func _animate_sprite(target: Unit, flash_color: Color, duration_val: float = 0.3) -> void:
	if not target.has_node("Sprite2D"):
		return
	
	var sprite: Sprite2D = target.get_node("Sprite2D")
	var tween: Tween = target.create_tween()
	tween.tween_property(sprite, "modulate", flash_color, duration_val)
	var final_color: Color = Color.RED if target.get_side() else Color.WHITE
	tween.tween_property(sprite, "modulate", final_color, duration_val)
