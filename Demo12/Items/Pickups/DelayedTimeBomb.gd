extends BombPickupBase


export var maxWaitTime : float = 10.0


func _setup() -> void:
	_parent.timeToExplode = maxWaitTime
