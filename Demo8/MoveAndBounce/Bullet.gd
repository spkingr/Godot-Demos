extends KinematicBody2D

export(float) var speed = 800

onready var _debugDraw = $DebugDraw

var velocity = Vector2()

# 设置子弹的位置和发射角度
func start(pos, angle):
	self.position = pos
	velocity = Vector2(speed, 0).rotated(angle)

func _physics_process(delta):
	var collision = self.move_and_collide(velocity * delta)
	if collision:
		velocity = velocity.bounce(collision.normal)
		if collision.collider.has_method('hit'):
			collision.collider.hit()

func _on_VisibilityNotifier2D_screen_exited():
	self.queue_free()
