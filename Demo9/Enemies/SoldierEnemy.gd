extends KinematicBody2D

const UNIT = 16
const FLOOR_NORMAL = Vector2(0, -1)

export(PackedScene) var bulletScene = null # 子弹场景
export(float) var patrolRange = 2 * UNIT   # 巡逻范围
export(int) var shootCount = 2             # 每次射击次数

onready var _sprite = $Sprite
onready var _animator = $AnimationPlayer
onready var _timer = $NextShootTimer

var _animations = {idle='idle', die='die', walk='walk', shoot='shoot'}

var _walkSpeed: float = 2 * UNIT / 2.0     # 移动速度
var _gravity: float = 100                  # 重力加速度

var _startPosition: float = 0.0            # 巡逻开始位置
var _moveDirection: int = 1                # 移动方向
var velocity: Vector2 = Vector2()          # 速度

var _canShoot: bool = false                # 能否射击
var _isShooting: bool = false              # 是否正在发射
var _isDead: bool = false                  # 是否死亡


func _ready():
	randomize()
	_startPosition = self.global_position.x
	_timer.start()
	

func _physics_process(delta):
	if _isShooting:
		return
	
	velocity.y += _gravity
	velocity.x = _walkSpeed * _moveDirection
	velocity = self.move_and_slide(velocity, FLOOR_NORMAL)
	
	# 玩家是否被攻击到
	var isPlayerCollided = false
	for index in range(self.get_slide_count()):
		var collider = self.get_slide_collision(index).collider
		if collider.is_in_group('player') && collider.has_method('attacked'):
			isPlayerCollided = true
			collider.attacked()
			break
	
	if ! isPlayerCollided && self.is_on_wall():
		_moveDirection = - _moveDirection
		_sprite.flip_h = _moveDirection != 1
	elif self.global_position.x >= _startPosition + patrolRange || self.global_position.x <= _startPosition - patrolRange:
		_moveDirection = - _moveDirection
		_sprite.flip_h = _moveDirection != 1
	
	_animator.current_animation = _animations.walk


# 射击
func _shoot():
	_isShooting = true
	for i in range(shootCount):
		# 死亡后不能射击
		if _isDead:
			return
		
		if bulletScene != null:
			var bullet = bulletScene.instance()
			bullet.start(_moveDirection, self.global_position)
			self.get_parent().add_child(bullet)
		
		_animator.current_animation = _animations.shoot
		yield(_animator, 'animation_finished')
	
	_isShooting = false
	_timer.start()


func _on_VisibilityNotifier2D_viewport_entered(viewport):
	if ! _canShoot:
		_timer.start()
	_canShoot = true


func _on_VisibilityNotifier2D_viewport_exited(viewport):
	_canShoot = false


func _on_NextShootTimer_timeout():
	if _canShoot:
		_shoot()


func die():
	_isDead = true
	_timer.stop()
	
	self.set_process(false)
	self.set_physics_process(false)
	
	_animator.current_animation = 'die'
