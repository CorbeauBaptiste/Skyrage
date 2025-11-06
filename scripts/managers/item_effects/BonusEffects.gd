## Effets d'items bonus (positifs).
##
## Contient tous les effets qui aident le joueur.

extends RefCounted

# Couleurs pour les animations
const COLOR_GOLD: Color = Color(2.0, 1.8, 0.5)
const COLOR_PINK: Color = Color(1.5, 0.5, 1.0)
const COLOR_ORANGE: Color = Color(1.5, 1.2, 0.8)

# ========================================
# GLAIVE DE MICHAËL
# ========================================

## Glaive de Michaël - Ajoute des charges d'attaque spéciales.
class GlaiveMichaelEffect extends ItemEffect:
	func _on_apply() -> void:
		uses_remaining = item.duration
		for target in targets:
			if target is Unit and target.item_effect_component:
				target.item_effect_component.add_michael_charges(uses_remaining)
				_animate_sprite(target, COLOR_GOLD)
				print("⚔️ Glaive: %d charges → %s" % [uses_remaining, target.unit_name])

# ========================================
# BÉNÉDICTION DE PLOUTOS
# ========================================

## Bénédiction de Ploutos - Multiplie l'or du joueur.
class BenedictionPloutosEffect extends ItemEffect:
	func _on_apply() -> void:
		for target in targets:
			if target is Player and target.base and target.base.gold_component:
				var gold_comp: BaseGoldComponent = target.base.gold_component
				var old_gold: float = gold_comp.get_current_gold()
				var new_gold: float = min(old_gold * item.gold_multiplier, gold_comp.max_gold)
				gold_comp.gold_manager.current_gold = new_gold
				gold_comp.gold_manager.gold_changed.emit(new_gold, gold_comp.max_gold)
				print("💰 Ploutos: %.1f → %.1f (%s)" % [old_gold, new_gold, target.nom])

# ========================================
# FLÈCHE DE CUPIDON
# ========================================

## Flèche de Cupidon - Ajoute des flèches AoE.
class FlecheCupidonEffect extends ItemEffect:
	func _on_apply() -> void:
		uses_remaining = item.duration
		for target in targets:
			if target is Unit and target.item_effect_component:
				target.item_effect_component.add_cupidon_arrows(uses_remaining)
				_animate_sprite(target, COLOR_PINK, 0.25)
				print("💘 Cupidon: %d flèches → %s" % [uses_remaining, target.unit_name])

# ========================================
# REMÈDE DIVIN
# ========================================

## Remède Divin - Soigne les unités blessées avec priorité.
class RemedeDivinEffect extends ItemEffect:
	func _on_apply() -> void:
		var total_heal: int = item.heal_value
		var wounded_units: Array = []
		
		# Collecte les unités blessées
		for target in targets:
			if target is Unit and target.health_component:
				if target.health_component.get_missing_health() > 0:
					wounded_units.append(target)
		
		if wounded_units.is_empty():
			print("💊 Remède: Aucune unité blessée")
			return
		
		# Trie par PV manquants
		wounded_units.sort_custom(func(a, b):
			return a.health_component.get_missing_health() > b.health_component.get_missing_health()
		)
		
		# Distribue les soins
		var remaining: int = total_heal
		for unit in wounded_units:
			if remaining <= 0:
				break
			var missing: int = unit.health_component.get_missing_health()
			var heal_amount: int = min(missing, max(1, remaining / 2))
			var actual: int = unit.health_component.heal(heal_amount)
			remaining -= actual
		
		print("💊 Remède: %d PV sur %d unités" % [total_heal - remaining, wounded_units.size()])

# ========================================
# RAGE D'ARÈS
# ========================================

## Rage d'Arès - Réduit le cooldown d'attaque.
class RageAresEffect extends ItemEffect:
	var original_cooldowns: Dictionary = {}
	
	func _on_apply() -> void:
		duration_remaining = item.duration
		for target in targets:
			if target is Unit and target.item_effect_component:
				target.item_effect_component.apply_cooldown_modifier(item.cooldown_modifier, "Rage d'Arès")
				
				if target.has_node("Sprite2D"):
					target.get_node("Sprite2D").modulate = COLOR_ORANGE
				
				print("⚔️ Rage d'Arès: Cooldown de %s modifié (%.1fs)" % [target.unit_name, item.cooldown_modifier])
	
	func _on_expire() -> void:
		for target in targets:
			if is_instance_valid(target) and target is Unit and target.item_effect_component:
				target.item_effect_component.remove_effect("Rage d'Arès")
				target.item_effect_component.attack_cooldown_modifier = 0.0
				if target.combat_component:
					target.combat_component.cooldown_modifier = 0.0
				
				if target.has_node("Sprite2D"):
					var final_color: Color = Color.RED if target.get_side() else Color.WHITE
					target.get_node("Sprite2D").modulate = final_color
		
		print("⚔️ Rage d'Arès expiré")
