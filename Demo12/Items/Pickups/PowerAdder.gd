extends ActorPickupBase


export var addition : int = 1


func _setup() -> void:
	_parent.power += addition
	self.queue_free()
