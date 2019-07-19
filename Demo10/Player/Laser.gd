extends Area2D


export(int) var speed = 800

var _velocity : = Vector2.ZERO


func _process(delta):
	self.position += _velocity * delta


func _on_VisibilityNotifier2D_screen_exited():
	self.queue_free()


func _on_Laser_body_entered(body):
	if body.is_in_group('rock') && body.has_method('explode'):
		body.explode(_velocity)
		self.queue_free()


func start(pos:Vector2, rot:float) -> void:
	self.position = pos
	self.rotation = rot
	_velocity = Vector2(speed, 0).rotated(rot)
