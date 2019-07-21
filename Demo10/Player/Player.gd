extends RigidBody2D

signal health_updated(healthPercentage) # 生命值更新的信号，传出一个百分百参数
signal lifes_updated(lifes)             # 生命条数更新信号
signal game_over()                      # 游戏结束信号


export(int) var thrustForce : = 10      # 飞行前进的动力
export(int) var rotateSpeed : = 200     # 旋转方向的速度
export(float) var maxHealth : = 100.0   # 每条生命的最大生命值
export(float) var healthCure : = 1.5    # 生命值的恢复速度
export(PackedScene) var bulletScene : PackedScene = null

onready var _sprite : = $Sprite
onready var _collisionShape : = $CollisionShape2D
onready var _animationPlayer : = $AnimationPlayer
onready var _shootTimer : = $ShootTimer
onready var _invulnerabilityTimer : = $InvulnerabilityTimer
onready var _exhaustParticles : = $ExhaustParticles2D
onready var _explosion : = $Explosion
onready var _bulletPos : = $Position2D
onready var _shootAudio : = $ShootAudio
onready var _engineAudio : = $EngineAudio
onready var _explosionAudio : = $ExplosionAudio
onready var _screenSize : = self.get_viewport_rect().size

# 四中状态：初始化、正常生命状态、无敌状态、死亡
enum states {INIT, ALIVE, INVULNERABLE, DEAD}

var _state : int = -1                # 当前状态，-1表示无
var _rotateDirection : = 0           # 键盘输入下的旋转方向
var _thrustForceInput : = 0          # 键盘输入下的前进动力
var _canShoot : = true               # 是否能射击
var _health : = 0.0                  # 当前生命值
var _needReset : = false             # 是否需要重新设置玩家状态（位置和角度）
var _resetPosition : = Vector2.ZERO  # 重置后的玩家位置

var lifes : = 0 setget _set_lifes    # 玩家的生命条数

# 设置玩家的生命条数，同时判断否死亡，更新血条进度
func _set_lifes(value):
	lifes = value
	self.emit_signal('lifes_updated', lifes)
	if lifes <= 0:
		_die()
	else:
		_health = maxHealth
		self.emit_signal('health_updated', 1.0)


func _ready():
	# 设置初始状态，这里有一个 Bug 导致飞船不能正常旋转，可以改为 ALIVE 进行测试
	_changeState(states.INIT) # Test with [ALIVE], Shoudl be [INIT] in version 3.2
	yield(self.get_tree().create_timer(3), 'timeout')
	_changeState(states.ALIVE)


func _unhandled_input(event):
	# 飞船射击输入控制
	if event.is_action_pressed('shoot'):
		_shoot()


func _process(delta):
	# 首先把需要入的数值置零
	_rotateDirection = 0
	_thrustForceInput = 0
	
	# 如果是初始状态或者死亡状态则不继续
	if _state in [states.INIT, states.DEAD]:
		return
	_rotateDirection = int(Input.is_action_pressed('rotate_right')) - int(Input.is_action_pressed('rotate_left'))
	_thrustForceInput = int(Input.is_action_pressed('thrust'))
	
	# 生命值更新
	_health += healthCure * delta
	if _health > maxHealth:
		_health = maxHealth
	self.emit_signal('health_updated', self._health / maxHealth)
	
	# 粒子特效和声效
	_exhaustParticles.emitting = _thrustForceInput != 0
	if _thrustForceInput != 0 && ! _engineAudio.playing:
		_engineAudio.play()
	elif _thrustForceInput == 0:
		_engineAudio.stop()


func _integrate_forces(state):
	# 计算前进动力和旋转扭矩，并应用给飞船刚体（冲量）
	var force = Vector2(_thrustForceInput * thrustForce, 0).rotated(self.rotation)
	var torque = _rotateDirection * rotateSpeed
	state.apply_central_impulse(force)
	state.apply_torque_impulse(torque)
	
	# 设置飞船的位置，origin为飞船位置，xform.x为飞船主轴转向，不要直接设置position
	var xform = state.transform
	if _needReset:
		xform.origin = _resetPosition
		xform.x = Vector2(1, 0)
		_needReset = false
	
	# 控制飞船在窗口边缘的位置，形成一个闭合区间
	if xform.origin.x > _screenSize.x:
		xform.origin.x = 0
	elif xform.origin.x < 0:
		xform.origin.x = _screenSize.x
	if xform.origin.y > _screenSize.y:
		xform.origin.y = 0
	elif xform.origin.y < 0:
		xform.origin.y = _screenSize.y
	
    # 更新状态
	state.transform = xform


func _changeState(newState) -> void:
	if _state == newState:
		return
	
	# 更改飞船的状态，注意设置飞船的可见性
	match newState:
		states.INIT:
			# _collisionShape.disabled = true # 这在 Godot 3.1 版本中不能正常运行
			_collisionShape.set_deferred('disabled', true) # 新版本适用，禁用碰撞检测
			_sprite.hide()
		states.ALIVE:
			_collisionShape.set_deferred('disabled', false)
			_sprite.show()                        # 显示
		states.INVULNERABLE:
			_collisionShape.set_deferred('disabled', true)
			_animationPlayer.play('invulnerable') # 无敌状态动画
			_invulnerabilityTimer.start()         # 无敌状态计时器
		states.DEAD:
			_collisionShape.set_deferred('disabled', true)
			self.linear_velocity = Vector2.ZERO   # 线速度归零
			self.angular_velocity = 0.0           # 角速度归零
			_sprite.hide()                        # 隐藏
			_exhaustParticles.emitting = false    # 停止粒子播放
			_engineAudio.stop()                   # 停止声音播放
	_state = newState


func _shoot() -> void:
	if bulletScene == null || !_canShoot || ! _state in [states.ALIVE, states.INVULNERABLE]:
		return
	_canShoot = false
	
	# 发射子弹，注意子弹的旋转角度方向
	var bullet = bulletScene.instance()
	bullet.start(_bulletPos.global_position, self.rotation)
	self.get_parent().add_child(bullet)
	
	_shootAudio.play()
	_shootTimer.start()


func _die():
	# 切换死亡状态，关闭音乐和粒子特效
	_changeState(states.DEAD)
	_explosion.emitting = true
	_explosionAudio.play()
	var time = _explosion.lifetime
	# 粒子播放完后变非常态，并发出游戏结束信号
	yield(self.get_tree().create_timer(time), 'timeout')
	_changeState(states.INIT)
	self.emit_signal('game_over')


func _damage(size : int) -> void:
	# 伤害处理，更新生命值，根据传递的参数：太空岩石的尺寸而定
	_health -= size * size
	if _health <= 0.0:
		self.emit_signal('health_updated', 0.0)
		self.lifes -= 1
	else:
		self.emit_signal('health_updated', _health / maxHealth)
	
	if self.lifes > 0:
		_changeState(states.INVULNERABLE)


func _on_ShootTimer_timeout():
	_canShoot = true


func _on_InvulnerabilityTimer_timeout():
	_animationPlayer.stop()
	_changeState(states.ALIVE)


func _on_Player_body_entered(body):
	if body.is_in_group('rock') && body.has_method('explode'):
		# 与岩石碰撞，调用岩石的爆炸方法，传递飞船速度（也就是碰撞方向）
		body.explode(self.linear_velocity)
		# 计算伤害
		_damage(body.size)


func startGame(pos : Vector2) -> void:
	# 每次开始游戏重新设置飞船的位置，这里需要在_integrate_forces中设置，这是一个Bug引起
	_needReset = true
	_resetPosition = pos
	_changeState(states.ALIVE)

