extends Node
class_name ActorPickupBase


var _parent : Actor = null


func _ready() -> void:
	_parent = self.get_parent() as Actor
	if _parent == null:
		self.queue_free()
		return
	_setup()


func _setup() -> void:
	pass
