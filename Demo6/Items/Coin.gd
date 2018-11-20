extends Area2D

export var playerName = 'Player'
export var obstacleName = 'Cactus'

onready var _collisionShape = $CollisionShape2D

func _on_Coin_area_entered(area):
	if area.name == playerName && area.has_method('collectCoin'):
		_collisionShape.disabled = true
		area.collectCoin()
		self.queue_free()
	elif area.name == obstacleName:
		print('fuck!')
		self.queue_free()
