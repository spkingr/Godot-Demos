extends ActorPickupBase


export var acceleration : float = 1.5


func _setup() -> void:
	_parent.moveSpeed *= acceleration


func _on_Timer_timeout() -> void:
	if ! _parent.is_network_master():
		return
	
	self.rpc('_remoteSet')


remotesync func _remoteSet() -> void:
	_parent.moveSpeed /= acceleration
	self.queue_free()

