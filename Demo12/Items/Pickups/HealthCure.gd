extends ActorPickupBase


export var healthAmount : float = 30.0
export var addPerSeconds : float = 3.0


func _process(delta: float) -> void:
	if ! _parent.is_network_master():
		return
	
	if _parent.health <= 0.0:
		return
	
	if healthAmount <= delta * addPerSeconds:
		_parent.health += healthAmount
		self.rpc('_remoteSet', clamp(_parent.health, 0.0, _parent.maxHealth))
		self.rpc('_deleteObject')
		return
	
	_parent.health += delta * addPerSeconds
	healthAmount -= delta * addPerSeconds
	self.rpc_unreliable('_remoteSet', clamp(_parent.health, 0.0, _parent.maxHealth))


remotesync func _remoteSet(health : float) -> void:
	_parent.health = health


remotesync func _deleteObject() -> void:
	self.queue_free()

