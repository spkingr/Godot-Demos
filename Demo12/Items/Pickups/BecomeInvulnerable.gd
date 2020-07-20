extends ActorPickupBase


func _setup() -> void:
	_parent.isInvulnerable = true


func _on_Timer_timeout() -> void:
	if ! _parent.is_network_master():
		return
	
	self.rpc('_remoteSet')


remotesync func _remoteSet() -> void:
	_parent.isInvulnerable = false
	self.queue_free()

