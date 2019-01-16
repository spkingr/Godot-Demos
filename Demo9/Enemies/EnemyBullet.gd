extends Area2D


export(float) var speed = 100

onready var _sprite = $Sprite

var _direction = 1


func _ready():
	_sprite.flip_h = _direction == 1


func _physics_process(delta):
	self.position.x += speed * delta


func _on_VisibilityNotifier2D_screen_exited():
	self.queue_free()


func _on_EnemyBullet_body_entered(body):
	if body.is_in_group('player') || body.has_method('attacked'):
		body.attacked()
	# 注释下面两行，取消勾选 Monitorable 让子弹可以穿透墙壁
#	elif ! body.is_in_group('enemy'):
#		self.queue_free()


func start(direction: int = 1, position: Vector2 = Vector2()):
	_direction = direction
	speed *= direction
	self.global_position = position
