extends Node

signal timer_started()

@onready var label: Label = $Label
@onready var timer: Timer = $Timer

func _ready():
	timer.start()
	timer_started.emit()

func time_left():
	var time_left = timer.time_left
	var minute = floor(time_left / 60)
	var second = int(time_left) % 60
	return [minute, second]

func _process(delta: float) -> void:
	label.text = "%02d:%02d" % time_left()
	if timer.is_stopped():
		timer.start()
		timer_started.emit()


func _on_button_pause_button_down() -> void:
	var pause_scene = load("res://scenes/ui/menus/menu_pause.tscn")
	var pause_control = pause_scene.instantiate()
	add_child(pause_control)
