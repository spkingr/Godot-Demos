extends Node2D


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed('move'):
		var position := self.get_global_mouse_position()
		$CanvasLayer/Cross.rect_position = position - $CanvasLayer/Cross.rect_size * 0.5
		self.get_tree().set_group('player', 'target', position)

