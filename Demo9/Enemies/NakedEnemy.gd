extends KinematicBody2D

const UNIT = 16
const FLOOR_NORMAL = Vector2(0, -1)

export(float) var patrolRange = 3 * UNIT # 巡逻范围

onready var _sprite = $Sprite
onready var _timer = $StandStillTimer
onready var _animator = $AnimationPlayer

var _animations = {idle='idle', die='die', walk='walk', attack='attack'}

var _walkSpeed: float = 3 * UNIT / 2.0   # 移动速度
var _gravity: float = 100                # 重力加速度
var _isStandingStill: bool = false       # 站立不动

var _startPosition: float = 0.0          # 巡逻开始位置
var _moveDirection: int = 1              # 移动方向
var velocity: Vector2 = Vector2()        # 速度
var _target = null                       # 攻击目标：玩家


func _ready():
	_startPosition = self.global_position.x


func _physics_process(delta):
	# 站着不动或者攻击对象不为空时，站立
	if _isStandingStill || _target != null:
		return
	
	velocity.y += _gravity
	velocity.x = _walkSpeed * _moveDirection
	velocity = self.move_and_slide(velocity, FLOOR_NORMAL)
	
	# 循环判断碰撞体是否有玩家（**这里不能检测到玩家在背后的情形**）
	for index in range(self.get_slide_count()):
		var collision = self.get_slide_collision(index)
		if collision.collider.is_in_group('player'):
			_target = collision.collider
			_attack()
			return
			
	_animator.current_animation = _animations.walk
	
	if self.is_on_wall():
		_moveDirection = - _moveDirection
		_sprite.flip_h = _moveDirection != 1
	elif self.global_position.x >= _startPosition + patrolRange:
		_standStill(-1)
	elif self.global_position.x <= _startPosition - patrolRange:
		_standStill(1)


# 攻击
func _attack():
	if 'isDead' in _target && _target.isDead:
		_target == null
		return
		
	if _target.has_method('attacked'):
		_target.attacked()
	_animator.current_animation = _animations.attack
	yield(_animator, 'animation_finished')
	_target = null


# 站立，nextDirection 表示站立时间过后转身
func _standStill(nextDirection: int):
	_isStandingStill = true
	_moveDirection = nextDirection
	_animator.current_animation = _animations.idle
	_timer.start()


# 站立时间超时
func _on_StandStillTimer_timeout():
	_isStandingStill = false
	_sprite.flip_h = _moveDirection != 1


# 死亡
func die():
	self.set_process(false)
	self.set_physics_process(false)
	_animator.current_animation = _animations.die
