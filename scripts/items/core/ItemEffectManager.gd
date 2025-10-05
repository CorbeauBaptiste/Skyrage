class_name ItemEffectManager
extends Node


signal effect_applied(item_name: String, team: bool)
signal effect_expired(item_name: String, team: bool)

var world_ref: Node

func _init() -> void:
	name = "ItemEffectManager"

func setup(world: Node) -> void:
	"""Configure la référence au monde"""
	world_ref = world
	print("ItemEffectManager setup complete")

func apply_item_effect(item: Item, collector_unit: Unit, world: Node) -> void:
	"""
	Point d'entrée principal pour appliquer un effet d'item
	Args:
		item: L'item collecté
		collector_unit: L'unité qui a ramassé l'item
		world: Référence au monde pour accéder aux autres nodes
	"""
	if not item or not collector_unit:
		push_error("ItemEffectManager: Item ou unité null")
		return
	
	world_ref = world
	var team: bool = collector_unit.get_side() # true = enfer, false = paradis
	
	print("=== APPLICATION EFFET ITEM ===")
	print("Item: ", item.name)
	print("Type: ", "BONUS" if item.type == Item.ItemType.BONUS else "MALUS")
	print("Camp collecteur: ", "Enfer" if team else "Paradis")
	print("Effect Type: ", _get_effect_type_name(item.effect_type))
	print("Duration: ", item.duration)
	
	match item.name:
		# BONUS
		"Le glaive de michaël":
			_apply_glaive_michael(collector_unit)
		"La bénédiction de Ploutos":
			_apply_benediction_ploutos(team, world)
		"La flèche de cupidon":
			_apply_fleche_cupidon(collector_unit)
		"Le remède divin":
			_apply_remede_divin(team, world)
		"La rage d'ares":
			_apply_rage_ares(team, world, item.duration)
		
		# MALUS
		"La pomme d'adam":
			_apply_pomme_adam(team, world, item.duration)
		"La rage fourbe":
			_apply_rage_fourbe(team, world, item.duration)
		"La fourberie de scapin":
			_apply_fourberie_scapin(team, world)
		"L'intervention de Chronos":
			_apply_intervention_chronos(team, world, item.duration)
		"La révolte sombre":
			_apply_revolte_sombre(collector_unit, item.duration)
		
		_:
			push_warning("Effet non implémenté pour: ", item.name)
	
	effect_applied.emit(item.name, team)
	print("================================\n")


func _get_base_for_team(team: bool, world: Node) -> Base:
	"""
	Trouve la base pour un camp donné
	Args:
		team: true pour Enfer, false pour Paradis
		world: Node monde
	Returns: Base correspondante ou null
	"""
	for base in world.get_tree().get_nodes_in_group("bases"):
		if base is Base and base.get_side() == team:
			return base
	push_error("Base non trouvée pour camp: ", "Enfer" if team else "Paradis")
	return null

func _get_units_for_team(team: bool, world: Node) -> Array:
	"""
	Trouve toutes les unités d'un camp
	Args:
		team: true pour Enfer, false pour Paradis
		world: Node monde
	Returns: Array des unités du camp
	"""
	var units: Array = []
	for unit in world.get_tree().get_nodes_in_group("units"):
		if unit is Unit and unit.get_side() == team:
			units.append(unit)
	return units

func _get_effect_type_name(effect_type: Item.EffectType) -> String:
	"""Helper pour debug"""
	match effect_type:
		Item.EffectType.IMMEDIATE: return "IMMEDIATE"
		Item.EffectType.DURATION: return "DURATION"
		Item.EffectType.COUNT: return "COUNT"
		_: return "UNKNOWN"


func _apply_glaive_michael(collector_unit: Unit) -> void:
	"""
	Le glaive de michaël (5% drop)
	Dégât de zone : one shot les S, 3/4 les M, midlife les L
	2 utilisations
	"""
	if not collector_unit:
		push_error("Impossible d'appliquer Glaive de Michaël : unité null")
		return
	
	print("⚔️ Glaive de Michaël appliqué !")
	print("   Unité: ", collector_unit.name)
	print("   Camp: ", "Enfer" if collector_unit.get_side() else "Paradis")
	print("   2 attaques légendaires ajoutées")
	print("   Dégâts adaptatifs:")
	print("     - S (Small, ~20 PV): One-shot (100%)")
	print("     - M (Medium, ~50 PV): 3/4 des PV (75%)")
	print("     - L (Large, ~80 PV): Moitié des PV (50%)")
	
	# Donner 2 charges du Glaive de Michaël
	if collector_unit.has("michael_charges"):
		collector_unit.michael_charges += 2
		print("   Total charges Glaive: ", collector_unit.michael_charges)
		
		# Effet visuel spectaculaire (aura divine dorée)
		if collector_unit.has_node("Sprite2D"):
			var sprite = collector_unit.get_node("Sprite2D")
			var original_color = sprite.modulate
			
			# Animation plus longue et impressionnante (1 sec)
			var tween = collector_unit.create_tween()
			tween.tween_property(sprite, "modulate", Color(2.0, 1.8, 0.5), 0.3)  # Or divin brillant
			tween.tween_property(sprite, "modulate", Color(1.5, 1.3, 0.3), 0.2)  # Pulsation
			tween.tween_property(sprite, "modulate", Color(2.0, 1.8, 0.5), 0.3)  # Repulse
			tween.tween_property(sprite, "modulate", original_color, 0.2)  # Retour
	else:
		push_warning("L'unité n'a pas la propriété michael_charges")


func _apply_benediction_ploutos(team: bool, world: Node) -> void:
	"""
	La bénédiction de Ploutos (40% drop)
	Multiplie l'or actuel par 1.5
	Effet immédiat
	"""
	var base = _get_base_for_team(team, world)
	if not base or not base.gold_manager:
		push_error("Impossible d'appliquer Ploutos : base ou gold_manager null")
		return
	
	var old_gold = base.gold_manager.current_gold
	var new_gold = min(old_gold * 1.5, base.gold_manager.max_gold)
	base.gold_manager.current_gold = new_gold
	
	print("💰 Bénédiction de Ploutos appliquée !")
	print("   Camp: ", "Enfer" if team else "Paradis")
	print("   Or avant: %.1f" % old_gold)
	print("   Or après: %.1f (+%.1f)" % [new_gold, new_gold - old_gold])
	
	# Émettre le signal de changement d'or pour mettre à jour l'UI
	base.gold_manager.gold_changed.emit(new_gold, base.gold_manager.max_gold)


func _apply_fleche_cupidon(collector_unit: Unit) -> void:
	"""
	La flèche de cupidon (15% drop)
	3 flèches avec dégâts de zone (-35 PV)
	"""
	if not collector_unit:
		push_error("Impossible d'appliquer Flèche de Cupidon : unité null")
		return
	
	print("💘 Flèche de Cupidon appliquée !")
	print("   Unité: ", collector_unit.name)
	print("   Camp: ", "Enfer" if collector_unit.get_side() else "Paradis")
	print("   3 flèches spéciales ajoutées (35 dégâts de zone chacune)")
	
	# Donner 3 flèches de Cupidon à l'unité
	if collector_unit.has("cupidon_arrows"):
		collector_unit.cupidon_arrows += 3
		print("   Total flèches Cupidon: ", collector_unit.cupidon_arrows)
		
		# Effet visuel sur l'unité (aura rose)
		if collector_unit.has_node("Sprite2D"):
			var sprite = collector_unit.get_node("Sprite2D")
			var original_color = sprite.modulate
			
			# Pulser en rose pendant 0.5 sec pour indiquer le bonus
			var tween = collector_unit.create_tween()
			tween.tween_property(sprite, "modulate", Color(1.5, 0.5, 1.0), 0.25)
			tween.tween_property(sprite, "modulate", original_color, 0.25)
	else:
		push_warning("L'unité n'a pas la propriété cupidon_arrows")


func _apply_remede_divin(team: bool, world: Node) -> void:
	"""
	Le remède divin (50% drop)
	Soigne 200 PV au total sur les unités alliées
	Effet immédiat
	"""
	var units = _get_units_for_team(team, world)
	if units.is_empty():
		print("⚠️ Aucune unité trouvée pour Remède Divin")
		return
	
	print("💊 Remède Divin appliqué !")
	print("   Camp: ", "Enfer" if team else "Paradis")
	print("   Unités totales: ", units.size())
	
	# Distribuer 200 PV de soin
	var total_heal = 200
	var actual_healed = _heal_units(units, total_heal)
	
	print("   Soin total: ", actual_healed, " / ", total_heal, " PV distribués")

func _heal_units(units: Array, total_heal: int) -> int:
	"""
	Distribue intelligemment des PV de soin sur plusieurs unités
	Priorité aux unités les plus blessées
	Args:
		units: Array des unités à potentiellement soigner
		total_heal: Montant total de PV à distribuer
	Returns: Montant réellement soigné
	"""
	# Filtrer uniquement les unités blessées
	var wounded_units: Array = []
	for unit in units:
		if unit and unit.has_method("is_wounded") and unit.is_wounded():
			wounded_units.append(unit)
	
	if wounded_units.is_empty():
		print("   Aucune unité blessée à soigner")
		return 0
	
	# Trier par PV manquants (les plus blessées en premier)
	wounded_units.sort_custom(func(a, b):
		return a.get_missing_health() > b.get_missing_health()
	)
	
	var remaining_heal = total_heal
	var total_healed = 0
	
	# Stratégie: Distribuer équitablement mais en priorisant les plus blessées
	for unit in wounded_units:
		if remaining_heal <= 0:
			break
		
		var missing = unit.get_missing_health()
		if missing > 0:
			# Donner au moins la moitié des PV restants ou ce qui manque
			var heal_amount = min(missing, max(1, remaining_heal / 2))
			var actual = unit.heal(heal_amount)
			remaining_heal -= actual
			total_healed += actual
	
	# S'il reste du soin, faire un second passage
	if remaining_heal > 0:
		for unit in wounded_units:
			if remaining_heal <= 0:
				break
			
			var missing = unit.get_missing_health()
			if missing > 0:
				var actual = unit.heal(min(missing, remaining_heal))
				remaining_heal -= actual
				total_healed += actual
	
	return total_healed

func _apply_rage_ares(team: bool, world: Node, duration: int) -> void:
	"""
	La rage d'ares (10% drop)
	Réduit le temps d'attaque de moitié
	Durée: 5 secondes
	"""
	var units = _get_units_for_team(team, world)
	if units.is_empty():
		print("⚠️ Aucune unité trouvée pour Rage d'Arès")
		return
	
	print("⚔️ Rage d'Arès appliquée !")
	print("   Camp: ", "Enfer" if team else "Paradis")
	print("   Unités boostées: ", units.size())
	print("   Cooldown réduit de 50% pendant ", duration, " secondes")
	
	# Appliquer le boost à toutes les unités
	for unit in units:
		if unit and unit.has("attack_cooldown_modifier"):
			# Réduire le cooldown de 50% (multiplicateur négatif)
			unit.attack_cooldown_modifier = -0.5
			
			# Si l'unité a un Timer d'attaque en cours, l'ajuster immédiatement
			if unit.has_node("Timer") and not unit.get_node("Timer").is_stopped():
				var timer = unit.get_node("Timer")
				var new_time = max(0.1, unit.attack_speed * 0.5)
				timer.wait_time = new_time
			
			# Effet visuel (aura rouge/dorée)
			if unit.has_node("Sprite2D"):
				var original_color = unit.get_node("Sprite2D").modulate
				unit.get_node("Sprite2D").modulate = Color(1.5, 1.2, 0.8)  # Teinte dorée/orange
	
	# Timer pour restaurer après durée
	var timer = Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(func():
		for unit in units:
			if unit and not unit.is_queued_for_deletion():
				unit.attack_cooldown_modifier = 0.0
				
				# Restaurer couleur
				if unit.has_node("Sprite2D"):
					unit.get_node("Sprite2D").modulate = Color.RED if unit.get_side() else Color.WHITE
		
		print("⚔️ Rage d'Arès expiré pour ", "Enfer" if team else "Paradis")
		effect_expired.emit("La rage d'ares", team)
		timer.queue_free()
	)
	world.add_child(timer)
	timer.start()


func _apply_pomme_adam(team: bool, world: Node, duration: int) -> void:
	"""
	La pomme d'adam (60% drop)
	Ralentit les unités de 50%
	Durée: 4 secondes
	"""
	var units = _get_units_for_team(team, world)
	if units.is_empty():
		print("⚠️ Aucune unité trouvée pour Pomme d'Adam")
		return
	
	print("🍎 Pomme d'Adam appliquée !")
	print("   Camp affecté: ", "Enfer" if team else "Paradis")
	print("   Unités affectées: ", units.size())
	print("   Réduction vitesse: -50% pendant ", duration, " secondes")
	
	# Appliquer le malus à toutes les unités
	for unit in units:
		if unit and unit.has("speed_multiplier"):
			unit.speed_multiplier = 0.5  # -50% vitesse
			# Effet visuel (teinte)
			if unit.has_node("Sprite2D"):
				unit.get_node("Sprite2D").modulate = Color(0.6, 0.4, 0.4)  # Teinte marron
	
	# Timer pour restaurer après durée
	var timer = Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(func():
		for unit in units:
			if unit and not unit.is_queued_for_deletion():
				unit.speed_multiplier = 1.0
				if unit.has_node("Sprite2D"):
					# Restaurer couleur selon camp
					unit.get_node("Sprite2D").modulate = Color.RED if unit.get_side() else Color.WHITE
		print("🍎 Pomme d'Adam expiré pour ", "Enfer" if team else "Paradis")
		effect_expired.emit("La pomme d'adam", team)
		timer.queue_free()
	)
	world.add_child(timer)
	timer.start()

func _apply_rage_fourbe(team: bool, world: Node, duration: int) -> void:
	"""
	La rage fourbe (40% drop)
	Réduit les dégâts de 10%
	Durée: 5 secondes
	"""
	var units = _get_units_for_team(team, world)
	if units.is_empty():
		print("⚠️ Aucune unité trouvée pour Rage Fourbe")
		return
	
	print("😠 Rage Fourbe appliquée !")
	print("   Camp affecté: ", "Enfer" if team else "Paradis")
	print("   Unités affectées: ", units.size())
	print("   Réduction dégâts: -10% pendant ", duration, " secondes")
	
	# Appliquer le malus à toutes les unités
	for unit in units:
		if unit and unit.has("damage_multiplier"):
			unit.damage_multiplier = 0.9  # -10% dégâts
	
	# Timer pour restaurer après durée
	var timer = Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(func():
		for unit in units:
			if unit and not unit.is_queued_for_deletion():
				unit.damage_multiplier = 1.0
		print("😠 Rage Fourbe expiré pour ", "Enfer" if team else "Paradis")
		effect_expired.emit("La rage fourbe", team)
		timer.queue_free()
	)
	world.add_child(timer)
	timer.start()

func _apply_fourberie_scapin(team: bool, world: Node) -> void:
	"""
	La fourberie de scapin (10% drop)
	La base perd 100 PV
	Effet immédiat
	"""
	var base = _get_base_for_team(team, world)
	if not base:
		push_error("Impossible d'appliquer Scapin : base null")
		return
	
	var old_health = base.current_health
	var damage = 100
	var destroyed = base.take_damage(damage)
	
	print("💀 Fourberie de Scapin appliquée !")
	print("   Camp affecté: ", "Enfer" if team else "Paradis")
	print("   PV avant: ", old_health)
	print("   PV après: ", base.current_health if not destroyed else 0, " (-", damage, ")")
	
	if destroyed:
		print("   ⚠️ LA BASE A ÉTÉ DÉTRUITE !")

func _apply_intervention_chronos(team: bool, world: Node, duration: int) -> void:
	"""
	L'intervention de Chronos (30% drop)
	Augmente le cooldown d'attaque de 1 seconde
	Durée: 6 secondes
	"""
	var units = _get_units_for_team(team, world)
	if units.is_empty():
		print("⚠️ Aucune unité trouvée pour Chronos")
		return
	
	print("⏰ Intervention de Chronos appliquée !")
	print("   Camp affecté: ", "Enfer" if team else "Paradis")
	print("   Unités affectées: ", units.size())
	print("   Augmentation cooldown: +1 sec pendant ", duration, " secondes")
	
	# Appliquer le malus à toutes les unités
	for unit in units:
		if unit and unit.has("attack_cooldown_modifier"):
			unit.attack_cooldown_modifier = 1.0  # +1 seconde de cooldown
	
	# Timer pour restaurer après durée
	var timer = Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(func():
		for unit in units:
			if unit and not unit.is_queued_for_deletion():
				unit.attack_cooldown_modifier = 0.0
		print("⏰ Chronos expiré pour ", "Enfer" if team else "Paradis")
		effect_expired.emit("L'intervention de Chronos", team)
		timer.queue_free()
	)
	world.add_child(timer)
	timer.start()

func _apply_revolte_sombre(collector_unit: Unit, duration: int) -> void:
	"""
	La révolte sombre (5% drop)
	Les attaques font 0 dégâts
	Durée: 4 secondes
	Target: SINGLE (unité qui ramasse)
	"""
	if not collector_unit or not collector_unit.has("damage_multiplier"):
		push_error("Impossible d'appliquer Révolte Sombre : unité invalide")
		return
	
	print("🌑 Révolte Sombre appliquée !")
	print("   Unité affectée: ", collector_unit.name)
	print("   Camp: ", "Enfer" if collector_unit.get_side() else "Paradis")
	print("   Dégâts annulés pendant ", duration, " secondes")
	
	# Appliquer le malus à l'unité (0 dégâts)
	collector_unit.damage_multiplier = 0.0
	
	# Effet visuel pour marquer l'unité
	if collector_unit.has_node("Sprite2D"):
		collector_unit.get_node("Sprite2D").modulate = Color(0.2, 0.2, 0.2)  # Très sombre
	
	# Timer pour restaurer après durée
	var timer = Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(func():
		if collector_unit and not collector_unit.is_queued_for_deletion():
			collector_unit.damage_multiplier = 1.0
			if collector_unit.has_node("Sprite2D"):
				# Restaurer couleur selon camp
				collector_unit.get_node("Sprite2D").modulate = Color.RED if collector_unit.get_side() else Color.WHITE
		print("🌑 Révolte Sombre expiré")
		effect_expired.emit("La révolte sombre", collector_unit.get_side())
		timer.queue_free()
	)
	world_ref.add_child(timer)
	timer.start()
