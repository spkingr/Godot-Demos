extends RigidBody2D


export var mouseSensitivity := 0.25
export var deadPosition := 800.0

var _isPicked := false



func _input_event(viewport, event, shape_idx):
	# 右键按下时拖拽箱子
	var e : InputEventMouseButton = event as InputEventMouseButton
	if e && e.button_index == BUTTON_RIGHT && e.pressed:
		pickup()


func _unhandled_input(event):
	# 右键松开时抛掉箱子
	var e : InputEventMouseButton = event as InputEventMouseButton
	if e && e.button_index == BUTTON_RIGHT && ! e.pressed:
		# 传入鼠标的移动速度
		var v := Input.get_last_mouse_speed() * mouseSensitivity
		drop(v)


func _physics_process(delta):
	# 更新拖拽盒子的位置，跟随鼠标移动
	if _isPicked:
		self.global_transform.origin = self.get_global_mouse_position()
	
	# 盒子掉出地图之外删除
	if self.position.y > deadPosition:
		self.queue_free()


func pickup() -> void:
	if _isPicked:
		return
	_isPicked = true
	self.mode = RigidBody2D.MODE_STATIC   # 拾起盒子，更改为静态模式


func drop(velocity: Vector2 = Vector2.ZERO) -> void:
	if ! _isPicked:
		return
	_isPicked = false
	self.mode = RigidBody2D.MODE_RIGID   # 抛掉盒子，更改为刚体模式
	# self.sleeping = false              # 防止刚体睡眠
	self.apply_central_impulse(velocity) # 给盒子一个抛力
