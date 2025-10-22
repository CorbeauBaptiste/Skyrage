## Effets d'items malus (négatifs).
##
## Contient tous les effets qui pénalisent le joueur.

extends RefCounted

# Couleurs pour les animations
const COLOR_DARK: Color = Color(0.6, 0.4, 0.4)
const COLOR_BLACK: Color = Color(0.2, 0.2, 0.2)

# ========================================
# POMME D'ADAM
# ========================================

## Pomme d'Adam - Ralentit la vitesse de déplacement.
class PommeAdamEffect extends ItemEffect:
	var original_speeds: Dictionary = {}
	
	func _on_apply() -> void:
		duration_remaining = item.duration
		for target in targets:
			if target is Unit and target.movement_component:
				original_speeds[target] = target.movement_component.current_speed
				target.movement_component.current_speed *= item.speed_multiplier
				target.movement_component.speed_multiplier = item.speed_multiplier
				
				if target.has_node("Sprite2D"):
					target.get_node("Sprite2D").modulate = COLOR_DARK
				
				print("🍎 Pomme: Vitesse de %s → %.1f%%" % [target.unit_name, item.speed_multiplier * 100])
	
	func _on_expire() -> void:
		for target in original_speeds.keys():
			if is_instance_valid(target) and target is Unit and target.movement_component:
				target.movement_component.current_speed = original_speeds[target]
				target.movement_component.speed_multiplier = 1.0
				
				if target.has_node("Sprite2D"):
					var final_color: Color = Color.RED if target.get_side() else Color.WHITE
					target.get_node("Sprite2D").modulate = final_color
		
		print("🍎 Pomme d'Adam expiré")

# ========================================
# RAGE FOURBE
# ========================================

## Rage Fourbe - Réduit les dégâts infligés.
class RageFourbeEffect extends ItemEffect:
	func _on_apply() -> void:
		duration_remaining = item.duration
		for target in targets:
			if target is Unit and target.item_effect_component:
				target.item_effect_component.apply_damage_modifier(item.damage_multiplier, "Rage Fourbe")
				print("😠 Rage Fourbe: Dégâts de %s → %.0f%%" % [target.unit_name, item.damage_multiplier * 100])
	
	func _on_expire() -> void:
		for target in targets:
			if is_instance_valid(target) and target is Unit and target.item_effect_component:
				target.item_effect_component.remove_effect("Rage Fourbe")
				target.item_effect_component.damage_multiplier = 1.0
				if target.combat_component:
					target.combat_component.damage_multiplier = 1.0
		
		print("😠 Rage Fourbe expiré")

# ========================================
# FOURBERIE DE SCAPIN
# ========================================

## Fourberie de Scapin - Inflige des dégâts directs à la base.
class FourberieScapinEffect extends ItemEffect:
	func _on_apply() -> void:
		for target in targets:
			if target is Base and target.health_component:
				var old_health: int = target.health_component.current_health
				target.health_component.take_damage(item.damage_value)
				print("💀 Scapin: Base %s %d → %d PV" % [target.team, old_health, target.health_component.current_health])

# ========================================
# INTERVENTION DE CHRONOS
# ========================================

## Intervention de Chronos - Augmente le cooldown d'attaque.
class InterventionChronosEffect extends ItemEffect:
	func _on_apply() -> void:
		duration_remaining = item.duration
		for target in targets:
			if target is Unit and target.item_effect_component:
				target.item_effect_component.apply_cooldown_modifier(item.cooldown_modifier, "Chronos")
				print("⏰ Chronos: Cooldown de %s +%.1fs" % [target.unit_name, item.cooldown_modifier])
	
	func _on_expire() -> void:
		for target in targets:
			if is_instance_valid(target) and target is Unit and target.item_effect_component:
				target.item_effect_component.remove_effect("Chronos")
				target.item_effect_component.attack_cooldown_modifier = 0.0
				if target.combat_component:
					target.combat_component.cooldown_modifier = 0.0
		
		print("⏰ Chronos expiré")

# ========================================
# RÉVOLTE SOMBRE
# ========================================

## Révolte Sombre - Annule complètement les dégâts.
class RevolteSombreEffect extends ItemEffect:
	func _on_apply() -> void:
		duration_remaining = item.duration
		for target in targets:
			if target is Unit and target.item_effect_component:
				target.item_effect_component.apply_damage_modifier(0.0, "Révolte Sombre")
				
				if target.has_node("Sprite2D"):
					target.get_node("Sprite2D").modulate = COLOR_BLACK
				
				print("🌑 Révolte: %s ne fait plus de dégâts" % target.unit_name)
	
	func _on_expire() -> void:
		for target in targets:
			if is_instance_valid(target) and target is Unit and target.item_effect_component:
				target.item_effect_component.remove_effect("Révolte Sombre")
				target.item_effect_component.damage_multiplier = 1.0
				if target.combat_component:
					target.combat_component.damage_multiplier = 1.0
				
				if target.has_node("Sprite2D"):
					var final_color: Color = Color.RED if target.get_side() else Color.WHITE
					target.get_node("Sprite2D").modulate = final_color
		
		print("🌑 Révolte Sombre expiré")
