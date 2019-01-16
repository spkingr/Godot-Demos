extends Area2D

onready var _animationPlayer = $AnimationPlayer


func _on_GoldBox_body_entered(body):
	if body.is_in_group('player') && body.has_method('openBox'):
		_animationPlayer.current_animation = 'open'
		body.openBox()

