extends CanvasLayer

var pause = false

func pause_unpause():
	pause = !pause
	
	if pause : 
		get_tree().paused = true
		show()
	
	else : 
		get_tree().paused = false
		hide()

		
	
func _input(event):
	if event.is_action_pressed("pause"):
		pause_unpause()
