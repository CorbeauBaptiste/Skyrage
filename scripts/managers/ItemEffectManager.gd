class_name ItemEffectManager
extends Node

# Signaux pour notifier l'application et l'expiration des effets
signal effect_applied(item_name: String, team: bool)
signal effect_expired(item_name: String, team: bool)

# Liste des effets actuellement actifs dans le jeu
var active_effects: Array = []
# Registre qui mappe les noms d'items aux classes d'effets
var effect_registry: Dictionary = {}

# Couleurs pour les feedbacks visuels
const COLOR_GOLD: Color = Color(2.0, 1.8, 0.5)
const COLOR_PINK: Color = Color(1.5, 0.5, 1.0)
const COLOR_ORANGE: Color = Color(1.5, 1.2, 0.8)
const COLOR_DARK: Color = Color(0.6, 0.4, 0.4)
const COLOR_BLACK: Color = Color(0.2, 0.2, 0.2)

## Classe de base pour tous les effets d'items
class ItemEffect extends RefCounted:
	var item: Item
	var targets: Array = []
	var duration_remaining: float = 0.0
	var uses_remaining: int = 0
	
	signal effect_expired()
	
	func _init(effect_item: Item):
		item = effect_item
	
	## Applique l'effet aux cibles spécifiées
	func apply(target_nodes: Array) -> void:
		targets = target_nodes
		_on_apply()
	
	## Méthode virtuelle à surcharger pour appliquer l'effet
	func _on_apply() -> void:
		pass
	
	## Met à jour l'effet (durée, etc.). Retourne true si l'effet expire
	func update(delta: float) -> bool:
		if item.effect_type == Item.EffectType.DURATION:
			duration_remaining -= delta
			if duration_remaining <= 0:
				_on_expire()
				effect_expired.emit()
				return true
		return false
	
	## Méthode virtuelle à surcharger pour nettoyer l'effet
	func _on_expire() -> void:
		pass
	
	## Applique une animation de couleur au sprite d'une unité
	func _animate_sprite(target: Unit, flash_color: Color, duration: float = 0.3) -> void:
		if not target.has_node("Sprite2D"):
			return
		
		var sprite = target.get_node("Sprite2D")
		var tween = target.create_tween()
		tween.tween_property(sprite, "modulate", flash_color, duration)
		var final_color = Color.RED if target.get_side() else Color.WHITE
		tween.tween_property(sprite, "modulate", final_color, duration)


## BONUS: Glaive de Michaël - Ajoute des charges d'attaque aux unités
class GlaiveMichaelEffect extends ItemEffect:
	func _on_apply() -> void:
		uses_remaining = item.duration
		for target in targets:
			if target is Unit:
				target.michael_charges += uses_remaining
				_animate_sprite(target, COLOR_GOLD)
				print("⚔️ Glaive: %d charges ajoutées à %s" % [uses_remaining, target.unit_name])

## BONUS: Bénédiction de Ploutos - Multiplie l'or du joueur
class BenedictionPloutosEffect extends ItemEffect:
	func _on_apply() -> void:
		for target in targets:
			if target is Player and target.base and target.base.gold_manager:
				var gm = target.base.gold_manager
				var old_gold = gm.current_gold
				var new_gold = min(old_gold * item.gold_multiplier, gm.max_gold)
				gm.current_gold = new_gold
				gm.gold_changed.emit(new_gold, gm.max_gold)
				print("💰 Ploutos: %.1f -> %.1f (joueur %s)" % [old_gold, new_gold, target.nom])

## BONUS: Flèche de Cupidon - Ajoute des flèches spéciales aux unités
class FlecheCupidonEffect extends ItemEffect:
	func _on_apply() -> void:
		uses_remaining = item.duration
		for target in targets:
			if target is Unit:
				target.cupidon_arrows += uses_remaining
				_animate_sprite(target, COLOR_PINK, 0.25)
				print("💘 Cupidon: %d flèches ajoutées à %s" % [uses_remaining, target.unit_name])

## BONUS: Remède Divin - Soigne les unités blessées (priorité aux plus blessées)
class RemedeDivinEffect extends ItemEffect:
	func _on_apply() -> void:
		var total_heal = item.heal_value
		var wounded_units = []
		
		# Collecte toutes les unités blessées
		for target in targets:
			if target is Unit and target.has_method("get_missing_health"):
				if target.get_missing_health() > 0:
					wounded_units.append(target)
		
		if wounded_units.is_empty():
			print("💊 Remède: Aucune unité blessée")
			return
		
		# Trie par PV manquants (du plus blessé au moins blessé)
		wounded_units.sort_custom(func(a, b):
			return a.get_missing_health() > b.get_missing_health()
		)
		
		# Distribue les soins de manière intelligente
		var remaining = total_heal
		for unit in wounded_units:
			if remaining <= 0:
				break
			var missing = unit.get_missing_health()
			var heal_amount = min(missing, max(1, remaining / 2))
			var actual = unit.heal(heal_amount)
			remaining -= actual
		
		print("💊 Remède: %d PV distribués sur %d unités" % [total_heal - remaining, wounded_units.size()])

## BONUS: Rage d'Arès - Réduit le cooldown d'attaque (boost de vitesse d'attaque)
class RageAresEffect extends ItemEffect:
	var original_cooldowns: Dictionary = {}
	
	func _on_apply() -> void:
		duration_remaining = item.duration
		for target in targets:
			if target is Unit:
				# Sauvegarde le cooldown original
				if not original_cooldowns.has(target):
					original_cooldowns[target] = target.attack_cooldown
				
				target.attack_cooldown_modifier = item.cooldown_modifier
				
				if target.has_node("Sprite2D"):
					target.get_node("Sprite2D").modulate = COLOR_ORANGE
				
				print("⚔️ Rage d'Arès: Cooldown de %s réduit de %.1fs" % [target.unit_name, -item.cooldown_modifier])
	
	func _on_expire() -> void:
		# Restaure l'état normal de toutes les cibles
		for target in targets:
			if is_instance_valid(target) and target is Unit:
				target.attack_cooldown_modifier = 0.0
				if target.has_node("Sprite2D"):
					var final_color = Color.RED if target.get_side() else Color.WHITE
					target.get_node("Sprite2D").modulate = final_color
		print("⚔️ Rage d'Arès expiré")


## MALUS: Pomme d'Adam - Ralentit la vitesse de déplacement
class PommeAdamEffect extends ItemEffect:
	var original_speeds: Dictionary = {}
	
	func _on_apply() -> void:
		duration_remaining = item.duration
		for target in targets:
			if target is Unit:
				# ✅ FIX: Utilise current_speed au lieu de speed
				original_speeds[target] = target.current_speed
				target.current_speed *= item.speed_multiplier
				target.speed_multiplier = item.speed_multiplier
				
				if target.has_node("Sprite2D"):
					target.get_node("Sprite2D").modulate = COLOR_DARK
				
				print("🍎 Pomme d'Adam: Vitesse de %s réduite à %.1f%%" % [target.unit_name, item.speed_multiplier * 100])
	
	func _on_expire() -> void:
		# Restaure les vitesses originales
		for target in original_speeds.keys():
			if is_instance_valid(target) and target is Unit:
				target.current_speed = original_speeds[target]
				target.speed_multiplier = 1.0
				if target.has_node("Sprite2D"):
					var final_color = Color.RED if target.get_side() else Color.WHITE
					target.get_node("Sprite2D").modulate = final_color
		print("🍎 Pomme d'Adam expiré")

## MALUS: Rage Fourbe - Réduit les dégâts infligés
class RageFourbeEffect extends ItemEffect:
	func _on_apply() -> void:
		duration_remaining = item.duration
		for target in targets:
			if target is Unit:
				target.damage_multiplier = item.damage_multiplier
				print("😠 Rage Fourbe: Dégâts de %s réduits à %.0f%%" % [target.unit_name, item.damage_multiplier * 100])
	
	func _on_expire() -> void:
		# Remet le multiplicateur de dégâts à 1.0
		for target in targets:
			if is_instance_valid(target) and target is Unit:
				target.damage_multiplier = 1.0
		print("😠 Rage Fourbe expiré")

## MALUS: Fourberie de Scapin - Inflige des dégâts directs à la base
class FourberieScapinEffect extends ItemEffect:
	func _on_apply() -> void:
		for target in targets:
			if target is Base:
				var old_health = target.current_health
				target.take_damage(item.damage_value)
				print("💀 Scapin: Base %s %d -> %d PV" % [target.team, old_health, target.current_health])

## MALUS: Intervention de Chronos - Augmente le cooldown d'attaque (ralentit les attaques)
class InterventionChronosEffect extends ItemEffect:
	func _on_apply() -> void:
		duration_remaining = item.duration
		for target in targets:
			if target is Unit:
				target.attack_cooldown_modifier = item.cooldown_modifier
				print("⏰ Chronos: Cooldown de %s augmenté de +%.1fs" % [target.unit_name, item.cooldown_modifier])
	
	func _on_expire() -> void:
		# Restaure le cooldown normal
		for target in targets:
			if is_instance_valid(target) and target is Unit:
				target.attack_cooldown_modifier = 0.0
		print("⏰ Chronos expiré")

## MALUS: Révolte Sombre - Annule complètement les dégâts (dégâts à 0)
class RevolteSombreEffect extends ItemEffect:
	func _on_apply() -> void:
		duration_remaining = item.duration
		for target in targets:
			if target is Unit:
				target.damage_multiplier = 0.0
				if target.has_node("Sprite2D"):
					target.get_node("Sprite2D").modulate = COLOR_BLACK
				print("🌑 Révolte Sombre: %s ne fait plus de dégâts" % target.unit_name)
	
	func _on_expire() -> void:
		# Restaure les dégâts normaux
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

## Enregistre tous les effets d'items disponibles dans le registre
func _register_all_effects() -> void:
	# BONUS - Effets positifs
	effect_registry["Le glaive de michaël"] = GlaiveMichaelEffect
	effect_registry["La bénédiction de Ploutos"] = BenedictionPloutosEffect
	effect_registry["La flèche de cupidon"] = FlecheCupidonEffect
	effect_registry["Le remède divin"] = RemedeDivinEffect
	effect_registry["La rage d'ares"] = RageAresEffect
	
	# MALUS - Effets négatifs
	effect_registry["La pomme d'adam"] = PommeAdamEffect
	effect_registry["La rage fourbe"] = RageFourbeEffect
	effect_registry["La fourberie de scapin"] = FourberieScapinEffect
	effect_registry["L'intervention de Chronos"] = InterventionChronosEffect
	effect_registry["La révolte sombre"] = RevolteSombreEffect
	
	print("✅ %d effets d'items enregistrés" % effect_registry.size())

## Point d'entrée principal - Applique l'effet d'un item collecté
func apply_item_effect(item: Item, collector_unit: Unit, world: Node) -> void:
	# Validation des paramètres
	if not item or not collector_unit:
		push_error("ItemEffectManager: Item ou unité null")
		return
	
	# Vérifie que l'effet existe dans le registre
	if not effect_registry.has(item.name):
		push_warning("Effet non enregistré: %s" % item.name)
		return
	
	# Instancie l'effet à partir de sa classe
	var effect_class = effect_registry[item.name]
	var effect: ItemEffect = effect_class.new(item)
	
	# Détermine les cibles selon le type d'effet
	var targets = _find_targets(item, collector_unit, world)
	
	if targets.is_empty():
		print("⚠️ Aucune cible pour: %s" % item.name)
		return
	
	# Active l'effet sur les cibles
	effect.apply(targets)
	
	# Gère les effets temporaires (durée ou compteur d'utilisations)
	match item.effect_type:
		Item.EffectType.DURATION, Item.EffectType.COUNT:
			active_effects.append(effect)
			effect.effect_expired.connect(_on_effect_expired.bind(effect, item.name, collector_unit.get_side()))
	
	effect_applied.emit(item.name, collector_unit.get_side())
	print("✨ Effet appliqué: %s (type: %s)" % [item.name, Item.ItemType.keys()[item.type]])

## Détermine les cibles selon le type de ciblage de l'item
func _find_targets(item: Item, collector: Unit, world: Node) -> Array:
	var targets = []
	
	match item.target_type:
		Item.Target.SINGLE:
			# Cible uniquement l'unité qui a collecté l'item
			targets = [collector]
		
		Item.Target.ALLY:
			# La cible dépend du type d'effet
			if item.gold_multiplier != 1.0:
				# Effet d'or -> cible le joueur
				var base = world.base_enfer if collector.get_side() else world.base_paradis
				if base and base.player:
					targets = [base.player]
			
			elif item.heal_value > 0 or item.speed_multiplier != 1.0 or item.damage_multiplier != 1.0 or item.cooldown_modifier != 0.0:
				# Effet sur stats -> cible toutes les unités alliées
				for u in world.get_tree().get_nodes_in_group("units"):
					if u is Unit and u.get_side() == collector.get_side():
						targets.append(u)
			
			elif item.damage_value > 0 and item.type == Item.ItemType.MALUS:
				# Dégâts directs -> cible la base alliée
				var base = world.base_enfer if collector.get_side() else world.base_paradis
				targets = [base]
	
	return targets

## Tick principal - Met à jour tous les effets actifs chaque frame
func _process(delta: float) -> void:
	var to_remove = []
	
	# Met à jour chaque effet et collecte ceux qui ont expiré
	for effect in active_effects:
		if effect.update(delta):
			to_remove.append(effect)
	
	# Retire les effets expirés de la liste
	for effect in to_remove:
		active_effects.erase(effect)

## Callback appelé quand un effet expire
func _on_effect_expired(effect: ItemEffect, item_name: String, team: bool) -> void:
	effect_expired.emit(item_name, team)
	print("⏰ Effet expiré: %s" % item_name)
