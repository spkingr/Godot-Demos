extends Node2D

onready var _player = $Player

func _ready():
	_player.useSlideMethod = true

func _on_UseVelocity_toggled(button_pressed):
	_player.useRealVelocity = button_pressed
