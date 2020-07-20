extends BombPickupBase


export var powerMultiplier : int = 2


func _setup() -> void:
	_parent.power *= powerMultiplier

