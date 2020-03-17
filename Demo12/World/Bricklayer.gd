extends Area2D


signal brick_repaire_done()
signal request_new_path()
signal dead()


export var moveSpeed : float = 100.0

onready var _makingTimer := $MakingTimer as Timer
onready var _readyTimer := $ReadyTimer as Timer
onready var _animationPlayer := $AnimationPlayer as AnimationPlayer
onready var _enableRaycastTimer := $EnableRaycastTimer as Timer
onready var _raycast := $RayCast2D as RayCast2D
onready var _bombChecker := [$BombChecker/RayCast2D1, $BombChecker/RayCast2D2, $BombChecker/RayCast2D3, $BombChecker/RayCast2D4]

var _moveDirection := Vector2(1, 0)
var _isRepairing := false
var _isSuccessful := true
var _hasPath := false
var _isPaused := false

var canSuccess := true
var path := [] setget __setPath__


func __setPath__(value : Array) -> void:
	_hasPath = true
	path = value


func _ready() -> void:
	yield(_readyTimer, 'timeout')
	_requestPath()


func _physics_process(delta: float) -> void:
	if _isRepairing:
		_checkBomb()
		return
	
	if _isPaused:
		return
	
	_raycast.cast_to = _moveDirection * GameConfig.TILE_SIZE / 2
	if _raycast.enabled:
		_raycast.force_raycast_update()
	if _raycast.enabled && _raycast.is_colliding():
		_animationPlayer.current_animation = 'idle'
		var collider = _raycast.get_collider()
		if collider.is_in_group('bomb'):
			_moveDirection = - _moveDirection
			_requestPath()
		else:
			_isPaused = true
			_raycast.enabled = false
			_enableRaycastTimer.start()
		return
	
	if _hasPath:
		_animationPlayer.current_animation = 'move'
		_followPath(delta)


func _requestPath() -> void:
	self.emit_signal('request_new_path')


func _checkBomb() -> void:
	for raycast in _bombChecker:
		if raycast.is_colliding() && raycast.get_collider().is_in_group('bomb'):
			_cancelWork()
			return


func _cancelWork() -> void:
	_resetMoving()
	_makingTimer.stop()
	_requestPath()


func _followPath(delta : float) -> void:
	# arrive at the end point in path following
	var target := path[path.size() - 1] as Vector2
	if target.distance_to(self.position) <= delta * moveSpeed:
		_getToTarget()
		return
	
	# the path is not in line
	target = path[0]
	var distance : = target - self.position
	if distance.length_squared() < 1.0: # the error of path to current position
		self.position = target
		path.pop_front()
		if path.empty():
			_getToTarget()
			return
		target = path[0]
	
	# the point is in slope
	distance = target - self.position
	if distance.x != 0 && distance.y != 0:
		var newPoint : Vector2 = self.position + distance.dot(_moveDirection) * _moveDirection
		path.push_front(newPoint)
		target = newPoint
	
	# move to the target
	_moveDirection = (path[0] - self.position).normalized()
	if target.distance_to(self.position) <= delta * moveSpeed:
		self.position = target
		path.pop_front()
		if path.empty():
			_getToTarget()
	else:
		self.position += _moveDirection * delta * moveSpeed


func _getToTarget() -> void:
	_hasPath = false
	if canSuccess:	
		_startWorking()
	else:
		_requestPath()


func _startWorking() -> void:
	_isRepairing = true
	_animationPlayer.current_animation = 'work'
	for raycast in _bombChecker:
		raycast.enabled = true
	_makingTimer.start()


func _resetMoving() -> void:
	_isRepairing = false
	_isPaused = false
	_hasPath = false
	path.clear()
	
	for raycast in _bombChecker:
		raycast.enabled = false


func _on_MakingTimer_timeout() -> void:
	_resetMoving()
	_raycast.enabled = false
	_enableRaycastTimer.start()
	
	# first emit then request path! order is important!
	self.emit_signal('brick_repaire_done')
	_requestPath()


func _on_EnableRaycastTimer_timeout() -> void:
	_isPaused = false
	_raycast.enabled = true


func _dead() -> void:
	_resetMoving()
	self.set_physics_process(false)
	_raycast.enabled = false
	_animationPlayer.current_animation = 'die'
	yield(_animationPlayer, 'animation_finished')
	
	self.emit_signal('dead')


func bomb() -> void:
	_dead()


func respawn() -> void:
	_hasPath = false
	_isSuccessful = true
	_moveDirection = Vector2(1, 0)
	_raycast.enabled = true
	_raycast.cast_to = _moveDirection * GameConfig.TILE_SIZE / 2
	_animationPlayer.current_animation = 'idle'
	_makingTimer.stop()
	_enableRaycastTimer.stop()
	
	_readyTimer.start()
	yield(_readyTimer, 'timeout')
	self.set_physics_process(true)
	_requestPath()

