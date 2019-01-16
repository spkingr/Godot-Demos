extends Area2D


func _on_WaterPool_body_entered(body):
	if body.is_in_group('enemy'):
		body.queue_free()
	elif body.is_in_group('player') && body.has_method('fallPool'):
		body.fallPool()
