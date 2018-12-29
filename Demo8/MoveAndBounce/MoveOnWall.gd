extends Node2D

onready var _player = $Player
onready var _buttonCollide = $Control/ButtonCollide
onready var _buttonSlide = $Control/ButtonSlide
onready var _checkVelocity = $Control/UseVelocity

func _on_ButtonCollide_pressed():
	_player.useSlideMethod = false
	_checkVelocity.disabled = true
	_buttonCollide.add_color_override('font_color', Color(0, 1, 0))
	_buttonSlide.add_color_override('font_color', Color(1, 1, 1))

func _on_ButtonSlide_pressed():
	_player.useSlideMethod = true
	_checkVelocity.disabled = false
	_buttonSlide.add_color_override('font_color', Color(0, 1, 0))
	_buttonCollide.add_color_override('font_color', Color(1, 1, 1))

func _on_UseVelocity_toggled(button_pressed):
	_player.useRealVelocity = button_pressed
