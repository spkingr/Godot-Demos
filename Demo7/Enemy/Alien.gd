extends Area2D

export(PackedScene) var bulletScene = null
export(PackedScene) var explosionScene = null
export(int) var bulletSpeed = 800
export(int) var fallSpeed = 200
export(int) var moveSpeed = 250

onready var _shootPoint = $ShootPoint
onready var _audioPlayer = $ShootSound
onready var _screenRect = self.get_viewport().get_visible_rect()

var _hMovement = 0 # 水平移动（速度）方向

func _ready():
	randomize()
	_moveAndShoot()

func _process(delta):
	self.position += Vector2(moveSpeed * _hMovement, fallSpeed) * delta

# 发射子弹，播放音效
func _shoot():
	var bullet = bulletScene.instance()
	bullet.position = _shootPoint.global_position
	bullet.start(Vector2(0, bulletSpeed))
	self.get_tree().get_root().add_child(bullet)
	_audioPlayer.play()

# 移动并发射，生命周期内无限循环
func _moveAndShoot():
	# 第一次移动，不发射子弹
	var nextMovement = rand_range(0.5, 1.5)
	yield(self.get_tree().create_timer(nextMovement), "timeout")
	# 2/3几率发生水平移动，否则只做垂直运动
	var shouldMove = randi() % 3 >= 1
	if shouldMove:
		_hMovement = randi() % 3 - 1
	nextMovement = rand_range(1.0, 1.5)
	yield(self.get_tree().create_timer(nextMovement, false), "timeout")
	_hMovement = 0
	# 如果在屏幕范围内，则发射子弹
	if _isInShootableArea():
		_shoot()
	# 继续下一轮操作
	_moveAndShoot()

# 判断是否在屏幕范围内，否则不能射击，防止内存泄漏
func _isInShootableArea():
	var rect = _screenRect.grow_individual(-10, -10, -10, -100)
	return rect.has_point(self.position)

func _on_Alien_area_entered(area):
	if area.is_in_group('player'):
		area.destroy()
		self.queue_free()

func _on_VisibilityNotifier2D_screen_exited():
	self.queue_free()

# 被消灭时调用的方法
func destroy():
	if explosionScene != null:
		var explosion = explosionScene.instance()
		explosion.type = 'alien'
		explosion.position = self.global_position
		explosion.emitting = true
		self.get_tree().get_root().add_child(explosion)
	self.queue_free()
