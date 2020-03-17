extends ActorPickupBase


export var healthAmount : float = 30.0
export var addPerSeconds : float = 3.0


func _process(delta: float) -> void:
	if healthAmount <= delta * addPerSeconds:
		var old := _parent.health / 100
		_parent.health += healthAmount
		_parent.health = clamp(_parent.health, 0.0, 100.0)
		self.queue_free()
		return
	
	var old := _parent.health / 100
	_parent.health += delta * addPerSeconds
	_parent.health = clamp(_parent.health, 0.0, 100.0)
	healthAmount -= delta * addPerSeconds
