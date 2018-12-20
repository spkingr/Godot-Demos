extends Area2D

export(PackedScene) var explosionScene = null
export(int) var moveSpeed = 200
export(int) var rotationSpeed = 2

var _realRotationSpeed = 0

# 随机转速，随机尺寸缩放
func _ready():
	_realRotationSpeed = rotationSpeed + rand_range(-1, 1)
	var randScale = 1 + rand_range(-0.25, 0.25)
	self.scale = Vector2(randScale, randScale)

func _process(delta):
	self.position.y += moveSpeed * delta
	self.rotation += _realRotationSpeed * delta

func _on_Rock_area_entered(area):
	if area.is_in_group('player'):
		area.destroy()
		self.queue_free()

func _on_VisibilityNotifier2D_screen_exited():
	self.queue_free()

func destroy():
	if explosionScene != null:
		var explosion = explosionScene.instance()
		explosion.type = 'rock'
		explosion.position = self.global_position
		explosion.emitting = true
		self.get_tree().get_root().add_child(explosion)
	self.queue_free()
