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
var isControllable = true setget _setIsControllable
var _coins = 0
var _boundary = {minX = 0, minY = 0, maxX = 0, maxY = 0}

# functions
func _ready():
	var scale = _sprite.scale
	var rect = _sprite.get_rect()
	
	_boundary.minX = - rect.position.x * scale.x
	_boundary.minY = - rect.position.y * scale.y
	_boundary.maxX = ProjectSettings.get('display/window/size/width') - (rect.position.x + rect.size.x) * scale.x
	_boundary.maxY = ProjectSettings.get('display/window/size/height') - (rect.position.y + rect.size.y) * scale.y

func _process(delta):
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

func _setIsControllable(value):
	if isControllable != value:
		isControllable = value
		self.set_process(isControllable)
		_animationPlayer.current_animation = 'idle' if ! isControllable else _animationPlayer.current_animation

func restart(pos):
	_coins = 0
	self.position = pos

func collectCoin(num = 1):
	_coins += num
	_audioPlayer.stream = coinSound
	_audioPlayer.play()
	self.emit_signal('coin_collected', _coins)

func collectPower(buffer):
	_audioPlayer.stream = powerSound
	_audioPlayer.play()
	self.emit_signal('power_collected', buffer)

func hurt():
	_animationPlayer.current_animation = 'hurt'
	_audioPlayer.stream = hurtSound
	_audioPlayer.play()
	self.set_process(false)
	self.emit_signal('game_over')
	