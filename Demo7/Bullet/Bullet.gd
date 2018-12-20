extends Area2D

signal destroy_object(type)

# 子弹种类：玩家、敌人
export(String, 'player', 'enemy') var type = 'player'

var _velocity = Vector2() # 子弹速度

func _process(delta):
	self.position += _velocity * delta

func _on_Bullet_area_entered(area):
	# 敌人的子弹击中玩家
	if area.is_in_group('player') && type == 'enemy':
		area.destroy()
		self.queue_free()
	# 子弹击中敌人，对玩家子弹和敌人子弹处理不同
	elif area.is_in_group('enemy') || area.is_in_group('rock'):
		if type == 'player':
			area.destroy()
			var objectType = 'enemy' if area.is_in_group('enemy') else 'rock'
			self.emit_signal('destroy_object', objectType)
		if ! (area.is_in_group('enemy') && type == 'enemy'):
			self.queue_free()
	# 敌人的子弹和玩家子弹相撞
	elif area.is_in_group('bullet') && area.type != type:
		area.queue_free()
		self.queue_free()

# 子弹飞出屏幕
func _on_VisibilityNotifier2D_screen_exited():
	self.queue_free()

# 设置子弹速度
func start(velocity):
	_velocity = velocity
