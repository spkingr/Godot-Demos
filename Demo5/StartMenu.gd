extends Control

# 游戏场景资源路径
var gameScene = 'res://Game.tscn'

func _input(event):
	if event.is_action_released('ui_accept'):
		# 当按下空格或者回车时切换场景到Game
		self.get_tree().change_scene(gameScene)