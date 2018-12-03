extends Area2D

# 玩家名字，根据玩家名字判断金币否被收集
export var playerName = 'Player'
# 障碍物名字，如果金币与障碍物重叠则重新生成
export var obstacleName = 'Cactus'

onready var _collisionShape = $CollisionShape2D

func _on_Coin_area_entered(area):
	# 判断碰撞体是否为玩家
	if area.name == playerName && area.has_method('collectCoin'):
		_collisionShape.disabled = true
		area.collectCoin()
		self.queue_free()
	# 如果是障碍物则删除该金币
	elif area.name == obstacleName:
		self.queue_free()
