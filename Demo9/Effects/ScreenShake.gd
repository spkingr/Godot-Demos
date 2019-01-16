extends Node


onready var _tween = $ShakeTween
onready var _frequencyTimer = $Frequency
onready var _durationTimer = $Duration

var _amplitude: int = 0
var _priority: int = 0
var _camera: Camera2D = null


func _newShake():
	var random = Vector2()
	random.x = rand_range(-_amplitude, _amplitude)
	random.y = rand_range(-_amplitude, _amplitude)
	
	var duration = _frequencyTimer.wait_time
	_tween.interpolate_property(_camera, 'offset', _camera.offset, random, duration, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	_tween.start()


func _reset():
	var duration = _frequencyTimer.wait_time
	_tween.interpolate_property(_camera, 'offset', _camera.offset, Vector2(), duration, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	_tween.start()
	
	_priority = 0


func _on_Frequency_timeout():
	_newShake()


func _on_Duration_timeout():
	_frequencyTimer.stop()
	_reset()


func start(camera: Camera2D = null, duration: float = 0.2, frequency: float = 16, amplitude = 16, priority: int = 0):
	if camera == null:
		return
	
	_camera = camera
	
	if priority >= _priority:
		_priority = priority
		
		_amplitude = amplitude
		
		_frequencyTimer.wait_time = 1.0 / frequency
		_durationTimer.wait_time = duration
		_frequencyTimer.start()
		_durationTimer.start()
		
		_newShake()
