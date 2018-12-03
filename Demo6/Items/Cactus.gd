extends Area2D

export var playerName = 'Player'

func _on_Cactus_area_entered(area):
	# 与玩家相撞，调用玩家的hurt方法
	if area.name == playerName && area.has_method('hurt'):
		area.hurt()
