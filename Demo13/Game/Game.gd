extends Navigation2D


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed('restart'):
		self.get_tree().reload_current_scene()
	elif event.is_action_pressed('quit'):
		self.get_tree().quit()
	elif event.is_action_pressed('toggle_fullscreen'):
		OS.window_fullscreen = ! OS.window_fullscreen
