extends Node
class_name BombPickupBase


var _parent : Bomb = null


func _ready() -> void:
	_parent = self.get_parent() as Bomb
	if _parent == null:
		self.queue_free()
		return
	_setup()


func _setup() -> void:
	pass
