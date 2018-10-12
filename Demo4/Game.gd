extends Node2D

onready var player = $Player
onready var animationPlayer = $Player/AnimationPlayer # 修改后
onready var camera = $Camera2D
var currentAnimation = 'start'
var speed = 200

func _ready():
	camera.position = player.position

func _process(delta):
	var velocity = Vector2(0, 0) # 速度变量
	var isMoving = false # 是否按键移动
	var newAnimation = currentAnimation # 动画变量

	if Input.is_action_pressed('left'):
		velocity.x += -1
		newAnimation = 'left'
		isMoving = true
	if Input.is_action_pressed('right'):
		velocity.x += 1
		newAnimation = 'right'
		isMoving = true
	if Input.is_action_pressed('up'):
		velocity.y += -1
		newAnimation = 'up'
		isMoving = true
	if Input.is_action_pressed('down'):
		velocity.y += 1
		newAnimation = 'down'
		isMoving = true
	
	player.linear_velocity = velocity # 添加部分，设置线速度，速度为0时有用
	player.angular_velocity = 0 # 添加部分，设置角速度，防止player打转
	# 速度不为0，移动玩家位置，同时更新摄像机
	if velocity.length() > 0:
		# 注意这里normalize速度矢量
		# player.position += velocity.normalized() * speed * delta # 删除
		player.linear_velocity = velocity.normalized() * speed # 添加，更新速度
		# 更新摄像机，玩家始终在视窗内活动
		updateCameraPosition()
	
	# 根据是否有按键按下和新动作更新动画
	updateAnimation(isMoving, newAnimation)

func updateAnimation(isMoving, newAnimation):
	# 如果有移动按键按下，并且改变方向，则切换动画
	if isMoving and currentAnimation != newAnimation:
		animationPlayer.current_animation = newAnimation
		animationPlayer.play(newAnimation)
		currentAnimation = newAnimation
	# 未移动，但又非开始的情况，那么止移动动画
	elif ! isMoving and currentAnimation != 'start':
			animationPlayer.stop()
			currentAnimation = 'start'
	# 其他情况比如同方向继续移动，或者在开始的时候都不用处理

func updateCameraPosition():
	camera.position = player.position
