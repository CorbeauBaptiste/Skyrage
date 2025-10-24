extends HSlider


func _ready() -> void:
	value = Globals.brightness

func _on_value_changed(new_value: float) -> void:
	GlobalWorldEnvironment.environment.adjustment_brightness = new_value
	Globals.brightness = new_value
