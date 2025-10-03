extends HSlider

func _ready() -> void:
	value = Globals.brightness 

func _on_value_changed(value: float) -> void:
	GlobalWorldEnvironment.environment.adjustment_brightness = value
	Globals.brightness = value
