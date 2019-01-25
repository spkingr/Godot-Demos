extends KinematicBody2D

signal health_update(health)


const UNIT = 16
const FLOOR_NORMAL = Vector2(0, -1)

export(PackedScene) var slashScene = null

onready var _sprite = $Sprite
onready var _slashPositionRight = $SwooshPositionRight
onready var _slashPositionLeft = $SwooshPositionLeft
onready var _animationPlayer = $AnimationPlayer
onready var _audioPlayer = $AudioStreamPlayer
onready var _camera = $Camera2D
onready var _screenShake = $Camera2D/ScreenShake

# 所有的动画，部分并没有使用
var _animations = {idle='idle', run='run', hit='hit', jump='jump', 
					climb='climb', die='die', slash='slash'}
var _audios = {'run': preload('res://Assets/Auido/sound_walk.wav'), 
				'jump': preload('res://Assets/Auido/sound_jump.wav'),
				'shoot': preload('res://Assets/Auido/sound_shoot.wav'),
				'climb': preload('res://Assets/Auido/sound_climb.wav'),
				'gameover': preload('res://Assets/Auido/sound_gameover.wav')}

var _gravity = 0.0                  # 重力加速度，计算获得
var _moveSpeed = 0.0                 # 水平移动速度，计算获得
var _maxJumpSpeed = 0.0             # 最大跳跃度，计算获得
var _minJumpSpeed = 0.0             # 最小跳跃速度，计算获得
var _maxJumpHeight = 4.25 * UNIT    # 最大跳跃高度
var _minJumpHeight = 1.75 * UNIT    # 最小跳跃高度
var _maxRunWidth = 5.25 * UNIT      # 最大跨越宽度（飞跃）
var _jumpDuration = 1.0             # 空中跳跃时间，上升、降落各占一半

var _isSecondJumping = false        # 是否为二次跳跃
var _secondJumpHeight = 1.25 * UNIT # 二次跳跃最大高度
var _secondJumpSpeed = 0.0          # 二次跳跃最大速度，计算获得

var velocity = Vector2()            # 玩家当前度包括x和y方向，计算获得

var _isOnLadder = false             # 玩家是否在子上
var _climbSpeed = 0.0               # 爬梯子速度，根据移动速度计算获得
var _nextSoundPlayTime = 0.5        # 水平移动和爬梯子脚步声播放最小时间间隔

var _isAttacked = false             # 玩家当前是否被攻击了
var _isSlashing = false             # 玩家是否在放冲击波
var _currentHealth = 3              # 当前玩家的生命值


var isDead: bool setget ,_get_isDead
func _get_isDead():
	return _currentHealth <= 0


# 计算所有应该计算的数值
func _ready():
	_gravity = 2 * _maxJumpHeight / (_jumpDuration / 2 * _jumpDuration / 2)
	_moveSpeed = _maxRunWidth / _jumpDuration
	_maxJumpSpeed = - _gravity * _jumpDuration / 2
	_minJumpSpeed = - sqrt(2 * _gravity * _minJumpHeight)
	_secondJumpSpeed = - sqrt(2 * _gravity * _secondJumpHeight)
	
	_climbSpeed = _moveSpeed * 0.75
	
	self.emit_signal('health_update', 3)


# 处理键盘输入
func _input(event):
	# 如果被攻击了，不能继续操作
	if _isAttacked:
		return
	
	# 按下跳跃键
	if event.is_action_pressed('jump_up'):
		if self.is_on_floor():
			# 第一次跳跃，在地面上的时候
			velocity.y = _maxJumpSpeed
			_playAudioEffect('jump')
		else:
			# 第二次跳跃，方法内部还有判断
			_secondJump()
	# 松开跳跃键
	elif event.is_action_released('jump_up'):
		if velocity.y < _minJumpSpeed && ! _isSecondJumping:
			velocity.y = _minJumpSpeed
		elif velocity.y < 0.0 && _isSecondJumping:
			velocity.y = 0.0
	
	# 攻击键，函数内还有判断
	if event.is_action_pressed('shoot'):
		_slash()


func _physics_process(delta):
	# 被攻击的情况下依然移动玩家，但是不受键盘控制
	if _isAttacked:
		velocity.y += _gravity * delta
		self.move_and_slide(velocity, FLOOR_NORMAL)
		return
	
	# 在梯子上且不是二次跳跃过程中可以上下移动玩家，同时不会产生重力加速度
	var vertical = 0
	if !_isSecondJumping && _isOnLadder:
		vertical = int(Input.is_action_pressed('climb_down')) - int(Input.is_action_pressed('climb_up'))
		velocity.y = vertical * _climbSpeed
		if _nextSoundPlayTime <= 0.0 && vertical != 0:
			_nextSoundPlayTime = 0.5
			_playAudioEffect('climb')
	# 不在梯子上则受重力加速度影响，注意即使在梯子上但是是二次跳跃依然会受重力影响而下落
	else:
		velocity.y += _gravity * delta
	
	# 水平移动控制
	var horizontal = int(Input.is_action_pressed('move_right')) - int(Input.is_action_pressed('move_left'))
	velocity.x = lerp(velocity.x, horizontal * _moveSpeed, _getRunWeight())

	velocity = self.move_and_slide(velocity, FLOOR_NORMAL)
	if _isSecondJumping && self.is_on_floor():
		_isSecondJumping = false
	
	# 图片方向控制和声效制
	_sprite.flip_h = true if horizontal == -1 else (false if horizontal == 1 else _sprite.flip_h)
	_nextSoundPlayTime -= delta
	if _nextSoundPlayTime <= 0.0 && horizontal != 0 && self.is_on_floor():
		_nextSoundPlayTime = 0.5
		_playAudioEffect('run')
	
	# 动画效果1
	if self.isDead || _isAttacked || _isSlashing:
		return
	
	# 动画效果2
	if ! self.is_on_floor() && ! _isOnLadder:
		_animationPlayer.current_animation = _animations.jump
	elif _isOnLadder && vertical != 0 && ! _isAttacked:
		_animationPlayer.current_animation = _animations.climb
	elif horizontal != 0:
		_animationPlayer.current_animation = _animations.run
	else:
		_animationPlayer.current_animation = _animations.idle


# 插值权重：水平移动（0.25）和垂直跳跃（0.2）
func _getRunWeight() -> float:
	return 0.25 if self.is_on_floor() else 0.2


# 播放音效
func _playAudioEffect(name):
	if _audios[name]:
		_audioPlayer.stream = _audios[name]
		_audioPlayer.play()


# 攻击特效
func _slash():
	if _isSlashing || slashScene == null:
		return
	_isSlashing = true
	
	# 攻击特效
	var slash = slashScene.instance()
	var position = (_slashPositionLeft if _sprite.flip_h else _slashPositionRight).global_position
	slash.start(_sprite.flip_h, position)
	self.get_parent().add_child(slash)
	
	# 播放动画
	_animationPlayer.current_animation = _animations.slash
	yield(_animationPlayer, 'animation_finished')
	_isSlashing = false
	

# 下一关
func _nextLevel():
	self.set_process(false)
	self.set_process_input(false)
	self.set_physics_process(false)
	
	# 1秒之后进入下一关卡
	yield(self.get_tree().create_timer(1.0), 'timeout')
	
	# 这里改成你自己设计的关卡吧！比如 "Level+i" ，i 为下一关卡
	self.get_tree().change_scene('res://Levels/Level1.tscn')


# 玩家死亡
func _die():
	self.set_process_input(false)
	self.set_physics_process(false)
	
	_camera.zoom = Vector2(0.2, 0.2)
	_animationPlayer.current_animation = _animations.die
	_playAudioEffect('gameover')
	
	# 3 秒后返回主界面
	yield(self.get_tree().create_timer(3.0), 'timeout')
	self.get_tree().change_scene('res://Game.tscn')
	

# 二次跳跃
func _secondJump():
	if _isSecondJumping:
		return
	_isSecondJumping = true
	velocity.y = _secondJumpSpeed


# 掉入水池，直接结束游戏
func fallPool():
	self.emit_signal('health_update', 0)
	_die()
	

# 是否在梯子上
func onLadder(exited = false):
	if !exited:
		_isOnLadder = true
	else:
		_isOnLadder = false


# 打开宝盒，生命值恢复为3
func openBox():
	_currentHealth = 3
	self.emit_signal('health_update', _currentHealth)


# 打开木门，进入下一关
func openDoor():
	_nextLevel()


# 收到敌人攻击
func attacked():
	if _currentHealth == 0:
		return
	
	_isAttacked = true
	_currentHealth -= 1
	self.emit_signal('health_update', _currentHealth)
	
	if _currentHealth <= 0:
		_die()
	else:
		velocity.y = _secondJumpSpeed
		velocity.x = _moveSpeed * (1 if _sprite.flip_h else -1)
		_screenShake.start(_camera)
		
		# 动画
		_animationPlayer.current_animation = _animations.hit
		yield(_animationPlayer, 'animation_finished')
		_isAttacked = false
