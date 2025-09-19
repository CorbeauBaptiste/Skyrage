class_name Item
extends Resource

enum ItemType {BONUS, MALUS}
enum EffectType {IMMEDIATE, COUNT, DURATION}
enum Target {ALLY, SINGLE}

var type: ItemType
var pct_drop: float
var name: String
var effect_description: String
var effect_type: EffectType
var duration: int
var target_type: Target

var damage_value: int = 0
var heal_value: int = 0
var gold_multiplier: float = 1.0
var damage_multiplier: float = 1.0
var speed_multiplier: float = 1.0
var cooldown_modifier: float = 0.0

func _init(item_type: ItemType, 
			drop_chance: float, 
			item_name: String, 
			item_effect_description: String, 
			item_effect_type: EffectType, 
			item_duration: int,
			item_target_type: Target) -> void:
	type = item_type
	pct_drop = drop_chance
	name = item_name
	effect_description = item_effect_description
	effect_type = item_effect_type
	duration = item_duration
	target_type = item_target_type
