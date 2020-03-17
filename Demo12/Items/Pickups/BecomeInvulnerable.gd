extends ActorPickupBase


func _setup() -> void:
	_parent.isInvulnerable = true


func _on_Timer_timeout() -> void:
	_parent.isInvulnerable = false
	self.queue_free()
