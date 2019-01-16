extends Area2D

export(float) var speed = 100


func _physics_process(delta):
	self.position.x += self.scale.x * speed * delta
	

func _on_Swoosh_area_entered(area):
	if area.is_in_group('enemy') && area.has_method('die'):
		area.die()	


func _on_Swoosh_body_entered(body):
	if body.is_in_group('enemy') && body.has_method('die'):
		body.die()


func start(isFliped: bool, position: Vector2):
	self.scale.x = -1 if isFliped else 1
	self.position = position
	