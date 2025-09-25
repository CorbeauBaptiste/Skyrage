extends Area2D
class_name Base  

# Export pour Inspector (GDD: 2500 HP)
@export var max_hp: int = 2500
@export var hp: int = 2500 : set = _set_hp
@export var enemy_group: String = "enemy_units"  # Redéfini dans filles
@export var resource_rate: float = 1.0  # Or/s (double à 2.0 dernière min)

# Caching optimisé
@onready var health_bar: ProgressBar = $ProgressBar
@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer  # Pour VFX

signal base_destroyed(camp: String)  
signal unit_spawned(unit: Node2D)

var unit_types: Dictionary = {}  

var gold: int = 0
var gold_timer: Timer

func _ready():
	_setup_gold_timer()
	_update_health_bar()
	print("Base prête: ", hp, " PV, groupe ennemi: ", enemy_group)

func _setup_gold_timer():
	gold_timer = Timer.new()
	gold_timer.wait_time = 1.0 / resource_rate
	gold_timer.timeout.connect(_generate_gold)
	add_child(gold_timer)
	gold_timer.start()

func _generate_gold():
	gold += 1
	print("Or généré: ", gold)

func _set_hp(new_hp: int):
	hp = clamp(new_hp, 0, max_hp)
	_update_health_bar()
	if hp <= 0:
		_destroy_base()

func _update_health_bar():
	if health_bar:
		health_bar.value = (float(hp) / max_hp) * 100

func _destroy_base():
	if anim_player:
		anim_player.play("explosion") 
	emit_signal("base_destroyed", name)  
	sprite.visible = false
	set_physics_process(false)
	gold_timer.stop() 

func _on_body_entered(body: Node2D):
	if body.is_in_group(enemy_group) and hp > 0:
		var damage = body.damage if "damage" in body else 150
		take_damage(damage)
		body.queue_free() 

func take_damage(damage_amount: int):
	hp -= damage_amount
	print("Dégâts: ", damage_amount, " PV restants: ", hp)

func spawn_unit(type: String):
	if type not in unit_types:
		return
	var data = unit_types[type]
	if gold >= data.cost:
		gold -= data.cost
		var unit = data.scene.instantiate()
		unit.position = position + Vector2(50, 0)  # Spawn offset
		get_parent().add_child(unit)  # Ajoute à Level
		emit_signal("unit_spawned", unit)
		await get_tree().create_timer(data.charge).timeout  # Cooldown
		print("Unité spawn: ", type)
	else:
		print("Pas assez d'or!")

func double_resource_rate():
	resource_rate = 2.0
	gold_timer.wait_time = 1.0 / resource_rate
