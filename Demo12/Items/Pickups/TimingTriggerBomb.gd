extends BombPickupBase


export var maxWaitTime : float = 10.0


func _setup() -> void:
	_parent.timeToExplode = maxWaitTime


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed('detonate_bomb'):
		self.set_process_unhandled_input(false)
		self.set_process_input(false)
		_parent.bomb()
