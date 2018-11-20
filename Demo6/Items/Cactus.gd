extends Area2D

export var playerName = 'Player'

func _on_Cactus_area_entered(area):
	if area.name == playerName && area.has_method('hurt'):
		area.hurt()
