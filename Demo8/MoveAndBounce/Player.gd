extends KinematicBody2D

export(float) var moveSpeed = 300
export(float) var fallSpeed = 0
export(PackedScene) var bulletScene = null

onready var _debugDraw = $DebugDraw

var velocity = Vector2()
var useSlideMethod = false setget _set_useSlideMethod
var useRealVelocity = false setget _set_useRealVelocity

func _process(delta):
	self.position.y += fallSpeed * delta

# 未处理的输入才有效，防止点击UI控件的时候也发射子弹
func _unhandled_input(event):
	if Input.is_action_just_pressed('shoot') && bulletScene != null:
		_shoot()

func _physics_process(delta):
	var hDir = int(Input.is_action_pressed('ui_right')) - int(Input.is_action_pressed('ui_left'))
	var vDir = int(Input.is_action_pressed('ui_down')) - int(Input.is_action_pressed('ui_up'))
	velocity = Vector2(hDir, vDir).normalized() * moveSpeed
	if useSlideMethod:
		if useRealVelocity:
			# 更新速度为碰撞后速度，DebugDraw画图更准确
			velocity = self.move_and_slide(velocity)
		else:
			# 碰撞后速度没有更新，DebugDraw画图为原始速度
			self.move_and_slide(velocity)
	else:
		self.move_and_collide(velocity * delta)

func _shoot():
	var direction = self.get_global_mouse_position() - self.position
	if direction.length() == 0:
		return
	var bullet = bulletScene.instance()
	bullet.start(self.position, direction.angle())
	self.get_parent().add_child(bullet)

func _set_useSlideMethod(value):
	if useSlideMethod != value:
		useSlideMethod = value
		if useSlideMethod:
			_debugDraw.color = 'GREEN' if useRealVelocity else 'RED'
		else:
			_debugDraw.color = 'RED'
	
func _set_useRealVelocity(value):
	if useRealVelocity != value:
		useRealVelocity = value
		_debugDraw.color = 'GREEN' if useRealVelocity else 'RED'
