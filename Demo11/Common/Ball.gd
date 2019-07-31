extends RigidBody2D


onready var _animationPlayer := $AnimationPlayer


func _on_LifeTimer_timeout():
	_animationPlayer.play('disappear')
