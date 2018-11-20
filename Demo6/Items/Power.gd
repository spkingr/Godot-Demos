extends Area2D

export var playerName = 'Player'
export var power = 2

onready var _collisionShape = $CollisionShape2D
onready var _sprite = $Sprite
onready var _timer = $LifeTimer
onready var _tween = $DisappearTween

func _startTween():
	_tween.interpolate_property(_sprite, 'modulate', Color(1.0, 1.0, 1.0, 1.0), Color(1.0, 1.0, 1.0, 0.0), 0.25, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	_tween.interpolate_property(_sprite, 'scale', _sprite.scale, _sprite.scale * 4, 0.25, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	_tween.start()
	
func _on_Power_area_entered(area):
	if area.name == playerName && area.has_method('collectPower'):
		_collisionShape.disabled = true
		area.collectPower(power)
		_timer.stop()
		_startTween()

func _on_LiftTimer_timeout():
	self.queue_free()

func _on_Tween_tween_completed(object, key):
	self.queue_free()
