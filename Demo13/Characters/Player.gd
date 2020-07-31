extends KinematicBody2D


export var moveSpeed := 200
export var fastMoveSpeed := 300

onready var _animationPlayer := $AnimationPlayer as AnimationPlayer

# 跟踪路径，记录玩家当前行走路径点，原博文作者采用的方式
# 本人已将其移植到了 AIWithPathTracker.gd 中，详细解释参考本人博客文章
# var _trackPoints := []
var _velocity := Vector2.ZERO


func _physics_process(delta: float) -> void:
	var dirX := int(Input.is_action_pressed('move_right')) - int(Input.is_action_pressed('move_left'))
	var dirY := int(Input.is_action_pressed('move_down')) - int(Input.is_action_pressed('move_up'))
	if dirX == 0 && dirY == 0:
		_animationPlayer.current_animation = 'idle'
		return
	
	_velocity = Vector2(dirX, dirY).normalized() * (fastMoveSpeed if Input.is_key_pressed(KEY_SHIFT) else moveSpeed)
	_velocity = self.move_and_slide(_velocity)
	
	_animationPlayer.current_animation = 'move'

