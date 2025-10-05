class_name ItemEffectManager
extends Node


signal effect_applied(item_name: String, team: bool)
signal effect_expired(item_name: String, team: bool)


var active_effects: Array = []
var effect_registry: Dictionary = {}


class ItemEffect extends RefCounted:
	var item: Item
	var targets: Array = []
	var duration_remaining: float = 0.0
	var uses_remaining: int = 0
	
	signal effect_expired()
	
	func _init(effect_item: Item):
		item = effect_item
	
	func apply(target_nodes: Array) -> void:
		targets = target_nodes
		_on_apply()
	
	func _on_apply() -> void:
		pass
	
	func update(delta: float) -> bool:
		if item.effect_type == Item.EffectType.DURATION:
			duration_remaining -= delta
			if duration_remaining <= 0:
				_on_expire()
				effect_expired.emit()
				return true
		return false
	
	func _on_expire() -> void:
		pass



class GlaiveMichaelEffect extends ItemEffect:
	func _on_apply() -> void:
		uses_remaining = item.duration
		for target in targets:
			if target is Unit:
				target.michael_charges += uses_remaining
				
				if target.has_node("Sprite2D"):
					var sprite = target.get_node("Sprite2D")
					var tween = target.create_tween()
					tween.tween_property(sprite, "modulate", Color(2.0, 1.8, 0.5), 0.3)
					var final_color = Color.RED if target.get_side() else Color.WHITE
					tween.tween_property(sprite, "modulate", final_color, 0.3)
				
				print("⚔️ Glaive: %d charges ajoutées" % uses_remaining)

class BenedictionPloutosEffect extends ItemEffect:
	func _on_apply() -> void:
		for target in targets:
			if target is Player and target.base and target.base.gold_manager:
				var gm = target.base.gold_manager
				var old_gold = gm.current_gold
				var new_gold = min(old_gold * item.gold_multiplier, gm.max_gold)
				gm.current_gold = new_gold
				gm.gold_changed.emit(new_gold, gm.max_gold)
				print("💰 Ploutos: %.1f -> %.1f" % [old_gold, new_gold])

class FlecheCupidonEffect extends ItemEffect:
	func _on_apply() -> void:
		uses_remaining = item.duration
		for target in targets:
			if target is Unit:
				target.cupidon_arrows += uses_remaining
				
				if target.has_node("Sprite2D"):
					var sprite = target.get_node("Sprite2D")
					var tween = target.create_tween()
					tween.tween_property(sprite, "modulate", Color(1.5, 0.5, 1.0), 0.25)
					var final_color = Color.RED if target.get_side() else Color.WHITE
					tween.tween_property(sprite, "modulate", final_color, 0.25)
				
				print("💘 Cupidon: %d flèches ajoutées" % uses_remaining)

class RemedeDivinEffect extends ItemEffect:
	func _on_apply() -> void:
		var total_heal = item.heal_value
		var wounded_units = []
		
		for target in targets:
			if target is Unit and target.has_method("get_missing_health"):
				if target.get_missing_health() > 0:
					wounded_units.append(target)
		
		if wounded_units.is_empty():
			print("💊 Remède: Aucune unité blessée")
			return
		
		wounded_units.sort_custom(func(a, b):
			return a.get_missing_health() > b.get_missing_health()
		)
		
		var remaining = total_heal
		for unit in wounded_units:
			if remaining <= 0:
				break
			var missing = unit.get_missing_health()
			var heal_amount = min(missing, max(1, remaining / 2))
			var actual = unit.heal(heal_amount)
			remaining -= actual
		
		print("💊 Remède: %d PV distribués" % (total_heal - remaining))

class RageAresEffect extends ItemEffect:
	var original_cooldowns: Dictionary = {}
	
	func _on_apply() -> void:
		duration_remaining = item.duration
		for target in targets:
			if target is Unit:
				if not original_cooldowns.has(target):
					original_cooldowns[target] = target.attack_speed
				
				target.attack_cooldown_modifier = item.cooldown_modifier
				
				if target.has_node("Sprite2D"):
					target.get_node("Sprite2D").modulate = Color(1.5, 1.2, 0.8)
	
	func _on_expire() -> void:
		for target in targets:
			if is_instance_valid(target) and target is Unit:
				target.attack_cooldown_modifier = 0.0
				if target.has_node("Sprite2D"):
					var final_color = Color.RED if target.get_side() else Color.WHITE
					target.get_node("Sprite2D").modulate = final_color
		print("⚔️ Rage d'Arès expiré")



class PommeAdamEffect extends ItemEffect:
	var original_speeds: Dictionary = {}
	
	func _on_apply() -> void:
		duration_remaining = item.duration
		for target in targets:
			if target is Unit:
				original_speeds[target] = target.speed
				target.speed *= item.speed_multiplier
				
				if target.has_node("Sprite2D"):
					target.get_node("Sprite2D").modulate = Color(0.6, 0.4, 0.4)
	
	func _on_expire() -> void:
		for target in original_speeds.keys():
			if is_instance_valid(target) and target is Unit:
				target.speed = original_speeds[target]
				if target.has_node("Sprite2D"):
					var final_color = Color.RED if target.get_side() else Color.WHITE
					target.get_node("Sprite2D").modulate = final_color
		print("🍎 Pomme d'Adam expiré")

class RageFourbeEffect extends ItemEffect:
	func _on_apply() -> void:
		duration_remaining = item.duration
		for target in targets:
			if target is Unit:
				target.damage_multiplier = item.damage_multiplier
	
	func _on_expire() -> void:
		for target in targets:
			if is_instance_valid(target) and target is Unit:
				target.damage_multiplier = 1.0
		print("😠 Rage Fourbe expiré")

class FourberieScapinEffect extends ItemEffect:
	func _on_apply() -> void:
		for target in targets:
			if target is Base:
				var old_health = target.current_health
				target.take_damage(item.damage_value)
				print("💀 Scapin: Base %d -> %d PV" % [old_health, target.current_health])

class InterventionChronosEffect extends ItemEffect:
	func _on_apply() -> void:
		duration_remaining = item.duration
		for target in targets:
			if target is Unit:
				target.attack_cooldown_modifier = item.cooldown_modifier
	
	func _on_expire() -> void:
		for target in targets:
			if is_instance_valid(target) and target is Unit:
				target.attack_cooldown_modifier = 0.0
		print("⏰ Chronos expiré")

class RevolteSombreEffect extends ItemEffect:
	func _on_apply() -> void:
		duration_remaining = item.duration
		for target in targets:
			if target is Unit:
				target.damage_multiplier = 0.0
				if target.has_node("Sprite2D"):
					target.get_node("Sprite2D").modulate = Color(0.2, 0.2, 0.2)
	
	func _on_expire() -> void:
		for target in targets:
			if is_instance_valid(target) and target is Unit:
				target.damage_multiplier = 1.0
				if target.has_node("Sprite2D"):
					var final_color = Color.RED if target.get_side() else Color.WHITE
					target.get_node("Sprite2D").modulate = final_color
		print("🌑 Révolte Sombre expiré")



func _init() -> void:
	name = "ItemEffectManager"
	_register_all_effects()

func _register_all_effects() -> void:
	"""Enregistre tous les effets disponibles"""
	# BONUS
	effect_registry["Le glaive de michaël"] = GlaiveMichaelEffect
	effect_registry["La bénédiction de Ploutos"] = BenedictionPloutosEffect
	effect_registry["La flèche de cupidon"] = FlecheCupidonEffect
	effect_registry["Le remède divin"] = RemedeDivinEffect
	effect_registry["La rage d'ares"] = RageAresEffect
	
	# MALUS
	effect_registry["La pomme d'adam"] = PommeAdamEffect
	effect_registry["La rage fourbe"] = RageFourbeEffect
	effect_registry["La fourberie de scapin"] = FourberieScapinEffect
	effect_registry["L'intervention de Chronos"] = InterventionChronosEffect
	effect_registry["La révolte sombre"] = RevolteSombreEffect
	
	print("✅ %d effets enregistrés" % effect_registry.size())

func apply_item_effect(item: Item, collector_unit: Unit, world: Node) -> void:
	"""Applique l'effet d'un item collecté"""
	if not item or not collector_unit:
		push_error("ItemEffectManager: Item ou unité null")
		return
	
	# Vérifier si l'effet existe
	if not effect_registry.has(item.name):
		push_warning("Effet non enregistré: %s" % item.name)
		return
	
	# Créer l'effet
	var effect_class = effect_registry[item.name]
	var effect: ItemEffect = effect_class.new(item)
	
	# Trouver les cibles
	var targets = _find_targets(item, collector_unit, world)
	
	if targets.is_empty():
		print("⚠️ Aucune cible pour: %s" % item.name)
		return
	
	# Appliquer l'effet
	effect.apply(targets)
	
	# Gérer la durée/compteur
	match item.effect_type:
		Item.EffectType.DURATION, Item.EffectType.COUNT:
			active_effects.append(effect)
			effect.effect_expired.connect(_on_effect_expired.bind(effect, item.name, collector_unit.get_side()))
	
	effect_applied.emit(item.name, collector_unit.get_side())
	print("✨ Effet appliqué: %s" % item.name)

func _find_targets(item: Item, collector: Unit, world: Node) -> Array:
	"""Trouve les cibles selon le type de target de l'item"""
	var targets = []
	
	match item.target_type:
		Item.Target.SINGLE:
			targets = [collector]
		
		Item.Target.ALLY:
			# Selon l'effet, peut être le Player, la Base ou les unités
			if item.gold_multiplier != 1.0:  # Effet d'or = Player
				var base = world.base_enfer if collector.get_side() else world.base_paradis
				if base and base.player:
					targets = [base.player]
			elif item.heal_value > 0 or item.speed_multiplier != 1.0 or item.damage_multiplier != 1.0 or item.cooldown_modifier != 0.0:
				# Effet sur unités
				for u in world.get_tree().get_nodes_in_group("units"):
					if u is Unit and u.get_side() == collector.get_side():
						targets.append(u)
			elif item.damage_value > 0 and item.type == Item.ItemType.MALUS:
				# Dégâts à la base
				var base = world.base_enfer if collector.get_side() else world.base_paradis
				targets = [base]
	
	return targets

func _process(delta: float) -> void:
	"""Met à jour les effets actifs"""
	var to_remove = []
	
	for effect in active_effects:
		if effect.update(delta):
			to_remove.append(effect)
	
	for effect in to_remove:
		active_effects.erase(effect)

func _on_effect_expired(effect: ItemEffect, item_name: String, team: bool) -> void:
	"""Callback quand un effet expire"""
	effect_expired.emit(item_name, team)
	print("⏰ Effet expiré: %s" % item_name)
