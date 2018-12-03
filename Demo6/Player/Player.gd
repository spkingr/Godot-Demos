extends Area2D

# signal group
signal coin_collected(count)
signal power_collected(buffer)
signal game_over()

# export
export(int) var moveSpeed = 320
export(AudioStream) var coinSound = null
export(AudioStream) var hurtSound = null
export(AudioStream) var powerSound = null

# onready
onready var _animationPlayer = $AnimationPlayer
onready var _audioPlayer = $AudioStreamPlayer
onready var _sprite = $Sprite

# enum, constant

# variable
var isControllable = true setget _setIsControllable # 是否允许玩家被控制
var _coins = 0 # 当前关卡所收集金币的数量
var _boundary = {minX = 0, minY = 0, maxX = 0, maxY = 0} # 移动范围

# functions
func _ready():
	var scale = _sprite.scale
	var rect = _sprite.get_rect()
	
	# 设置玩家能移动的上下左右最大范围
	_boundary.minX = - rect.position.x * scale.x
	_boundary.minY = - rect.position.y * scale.y
	_boundary.maxX = ProjectSettings.get('display/window/size/width') - (rect.position.x + rect.size.x) * scale.x
	_boundary.maxY = ProjectSettings.get('display/window/size/height') - (rect.position.y + rect.size.y) * scale.y

func _process(delta):
	# 根据玩家键盘输入设置玩家的移动方向和速度
	var hDir = int(Input.is_action_pressed('right')) - int(Input.is_action_pressed('left'))
	var vDir = int(Input.is_action_pressed('down')) - int(Input.is_action_pressed('up'))
	var velocity = Vector2(hDir, vDir).normalized()
	self.position += velocity * moveSpeed * delta
	self.position.x = clamp(self.position.x, _boundary.minX, _boundary.maxX)
	self.position.y = clamp(self.position.y, _boundary.minY, _boundary.maxY)
	
	if hDir != 0:
		_sprite.flip_h = hDir < 0
	if hDir != 0 || vDir != 0:
		_animationPlayer.current_animation = 'run'
	else:
		_animationPlayer.current_animation = 'idle'

# isControllable属性的set方法
func _setIsControllable(value):
	if isControllable != value:
		isControllable = value
		self.set_process(isControllable)
		_animationPlayer.current_animation = 'idle' if ! isControllable else _animationPlayer.current_animation

# 重新开始的方法，传递一个玩家初始位置
func restart(pos):
	_coins = 0
	self.position = pos

# 收集金币方法，传递收集金币数量
func collectCoin(num = 1):
	_coins += num
	_audioPlayer.stream = coinSound
	_audioPlayer.play()
	self.emit_signal('coin_collected', _coins)

# 收集到能量调用的方法
func collectPower(buffer):
	_audioPlayer.stream = powerSound
	_audioPlayer.play()
	self.emit_signal('power_collected', buffer)

# 玩家受到伤害时用方法
func hurt():
	_animationPlayer.current_animation = 'hurt'
	_audioPlayer.stream = hurtSound
	_audioPlayer.play()
	self.set_process(false)
	self.emit_signal('game_over')
	