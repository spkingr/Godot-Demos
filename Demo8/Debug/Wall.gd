extends StaticBody2D

onready var animator = $AnimationPlayer

func hit():
	animator.play('flash')
