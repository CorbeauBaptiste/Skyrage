extends Control

@onready var slider: HSlider = $Background/VBoxContainer/HSlider

func _ready():
	
	slider.connect("value_changed", Callable(self, "_on_HSlider_value_changed"))

func _on_exit_button_down() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/menus/menu_principal.tscn")

func _on_HSlider_value_changed(value: float) -> void:
	Globals.set_volume(value)
