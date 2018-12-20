extends Area2D

signal game_over()     # 游戏结束信号
signal score_updated() # 分数更新信号

export(PackedScene) var bulletScene = null
export(PackedScene) var explosionScene = null
export(int) var bulletSpeed = 800
export(int) var shipSpeed = 10

onready var _fireRateTimer = $FireRateTimer
onready var _shootSound = $ShootSound
onready var _shootPoint = $ShootPoint
onready var _screenSize = self.get_viewport().get_visible_rect().size

var _isShootable = true # 是否可以进行下一次射击

func _process(delta):
	var hDir = int(Input.is_action_pressed('right')) - int(Input.is_action_pressed('left'))
	var vDir = int(Input.is_action_pressed('backward')) - int(Input.is_action_pressed('forward'))
	var velocity = Vector2(hDir, vDir).normalized() * shipSpeed
	self.position += velocity
	self.position.x = clamp(self.position.x, 0, _screenSize.x)
	self.position.y = clamp(self.position.y, 0, _screenSize.y)

func _input(event):
	if event.is_action_pressed('shoot') && _isShootable:
		_isShootable = false
		_fireRateTimer.start()
		_shoot()

# 射击函数
func _shoot():
	if bulletScene == null:
		return
	# 生成一个子弹对象
	var bullet = bulletScene.instance()
	# 设置子弹的全局位置
	bullet.position = _shootPoint.global_position
	# 调用子弹的公开方法，设置速度
	bullet.start(Vector2(0, - bulletSpeed))
	# 连接子弹的信号
	bullet.connect('destroy_object', self, '_on_Bullet_destroy_object')
	# 把子弹添加到游戏root根节点
	self.get_tree().get_root().add_child(bullet)
	# 音效
	_shootSound.play()

func _on_FireRateTimer_timeout():
	_isShootable = true

func _on_Bullet_destroy_object(type):
	match type:
		'enemy', 'rock':
			self.emit_signal('score_updated')

# 玩家被消灭，游戏结束
func destroy():
	if explosionScene != null:
		var explosion = explosionScene.instance()
		explosion.type = 'player'
		explosion.position = self.global_position
		explosion.emitting = true
		self.get_tree().get_root().add_child(explosion)
	self.emit_signal('game_over')
	self.queue_free()
