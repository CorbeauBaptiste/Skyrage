extends Control

signal fermer_parametres

@onready var slider: HSlider = $Background/VBoxContainer/HSlider

func _ready():
	slider.connect("value_changed", Callable(self, "_on_HSlider_value_changed"))

func _on_exit_button_down() -> void:
	# Si on est appelé depuis le menu pause (signal connecté), émettre le signal
	# Sinon, retourner au menu principal (comportement normal depuis le menu principal)
	if fermer_parametres.get_connections().size() > 0:
		emit_signal("fermer_parametres")
	else:
		get_tree().change_scene_to_file("res://scenes/ui/menus/menu_principal.tscn")

func _on_HSlider_value_changed(value: float) -> void:
	Globals.set_volume(value)
