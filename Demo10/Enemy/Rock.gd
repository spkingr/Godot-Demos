extends RigidBody2D

# 爆炸信号，传递参数：岩石半径、位置、线速度、碰撞体速度（包括子弹和飞船）
signal explode(radius, position, velocity, colliderVelocity)


export var density : = 4         # 密度
export var scaleFactor : = 0.1   # 缩放系数，比如半径4，直径则为8，乘以0.1即0.8倍图片的大小
export var angularVelocity : = 2 # 随机角速度的范围（0-2），分正负


onready var _collisionShape : = $CollisionShape2D
onready var _sprite : = $Sprite
onready var _explosion : = $Explosion
onready var _audio : = $AudioStreamPlayer
onready var _screenSize : = self.get_viewport_rect().size

var _position : = Vector2.ZERO   # 位置
var _velocity : = Vector2.ZERO   # 初始线速度
var _radius : int = 0            # 半径

var size : int = 0 setget ,_getSize # 岩石的尺寸，实际上就是直径，半径乘以2

func _getSize() -> int:
	return _radius * 2


func _ready():
	randomize()
	
	# 设置位置和质量（在Player.gd中设置位置是在_integrate_forces方法中）
	self.position = _position
	self.mass = _radius * density
	
	# 设置图片尺寸和爆炸粒子尺寸与传递的参数相匹配
	_sprite.scale = Vector2(1, 1) * self.size * scaleFactor
	_explosion.scale = Vector2(1, 1) * self.size * scaleFactor 
	
	# 给飞船一个碰撞体形状，和传递的参数半径相匹配
	var shape = CircleShape2D.new()
	var textureSize = _sprite.texture.get_size()
	shape.radius = (textureSize.x + textureSize.y) / 2.0 * _radius * scaleFactor
	_collisionShape.shape = shape
	
	# 线速度和角度苏
	self.linear_velocity = _velocity
	self.angular_velocity = rand_range(-angularVelocity, angularVelocity)


func _integrate_forces(state):
	# 控制岩石的运动范围不超边界
	var xform = state.transform
	if xform.origin.x > _screenSize.x + _radius:
		xform.origin.x = 0 - _radius
	elif xform.origin.x < 0 - _radius:
		xform.origin.x = _screenSize.x + _radius
	if xform.origin.y > _screenSize.y + _radius:
		xform.origin.y = 0 - _radius
	elif xform.origin.y < 0 - _radius:
		xform.origin.y = _screenSize.y + _radius
	state.transform = xform


func init(radius: int, pos: Vector2, velocity: Vector2) -> void:
	# 调用该方法，配置相关参数
	_position = pos
	_radius = radius
	_velocity = velocity


func explode(colliderVelocity : Vector2) -> void:
	# 保证爆炸发生在最顶层
	self.layers = 0
	
	# 禁用碰撞图形，隐藏图片，爆炸粒子播放，声效播放
	_collisionShape.set_deferred('disabled', true)
	_sprite.hide()
	_explosion.emitting = true
	_audio.play()
	self.emit_signal('explode', _radius, self.position, self.linear_velocity, colliderVelocity)
	
	# 线速度和角速度置为0
	self.linear_velocity = Vector2.ZERO
	self.angular_velocity = 0.0
	
	# 删除引用（注意：岩石爆炸没有马上消失，见Game.gd源码）
	var time = _explosion.lifetime
	yield(self.get_tree().create_timer(time), 'timeout')
	self.queue_free()

