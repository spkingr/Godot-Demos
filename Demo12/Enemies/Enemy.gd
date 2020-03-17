extends Actor


const DIRECTIONS := [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]

export var damageAmount : int = 30
export var raycastLength : int = 32

onready var _sprite := $Sprite as Sprite
onready var _animationPlayer := $AnimationPlayer as AnimationPlayer
onready var _raycast := $StaticRayCast2D as RayCast2D
onready var _pausedTimer := $PausedTimer as Timer
onready var _enableCheckTimer := $EnableCheckTimer as Timer
onready var _playerRaycasts := [$PlayerCheckers/RayCast2D1, $PlayerCheckers/RayCast2D2, $PlayerCheckers/RayCast2D3, $PlayerCheckers/RayCast2D4]

var _moveDirection := Vector2.ZERO
var _isPaused := false
var _isDead := false
var _nextPosition := Vector2.ZERO


func _ready() -> void:
	self.position = self.position.snapped(GameConfig.TILE_HALF_SIZE_VECTOR)
	yield(self.get_tree(), 'idle_frame')
	_checkAndMove()


func _setNextTargetPosition() -> void:
	_nextPosition = self.position + _moveDirection * GameConfig.TILE_SIZE
	_nextPosition = _nextPosition.snapped(GameConfig.TILE_HALF_SIZE_VECTOR)
	
	
func _checkAndMove() -> void:
	if _enableCheckTimer.is_stopped():
		var isPlayerChecked := _checkPlayer()
		_disableCheckers()
		if isPlayerChecked:
			return
	
	var canMoveOn := false
	if _moveDirection != Vector2.ZERO:
		_raycast.cast_to = _moveDirection * raycastLength
		_raycast.force_raycast_update()
		if ! _raycast.is_colliding():
			_setNextTargetPosition()
			canMoveOn = true
	
	if canMoveOn && randf() < 0.70: # 70% posibility move on
		return
	
	var availableDirections := [_moveDirection] if canMoveOn else []
	for dir in DIRECTIONS:
		if dir == _moveDirection:
			continue
		_raycast.cast_to = dir * raycastLength
		_raycast.force_raycast_update()
		if ! _raycast.is_colliding():
			availableDirections.append(dir)
	
	if availableDirections.empty():
		_isPaused = true
		_moveDirection = Vector2.ZERO
		_animationPlayer.current_animation = 'idle'
		_pausedTimer.start()
	else:
		var index := randi() % availableDirections.size()
		_moveDirection = availableDirections[index]
		_setNextTargetPosition()


func _checkPlayer() -> bool:
	_disableCheckers(false)
	for raycast in _playerRaycasts:
		raycast.force_raycast_update()
		if raycast.is_colliding():
			_moveDirection = raycast.cast_to.normalized()
			_setNextTargetPosition()
			_enableCheckTimer.start()
			return true
	return false


func _disableCheckers(disabled : bool = true) -> void:
	for raycast in _playerRaycasts:
		raycast.enabled = ! disabled


func _physics_process(delta):
	if _isDead || _isPaused:
		return
	
	if _moveDirection != Vector2.ZERO:
		_sprite.flip_h = _moveDirection.x > 0
		_animationPlayer.current_animation = 'move'
	
	if _nextPosition.distance_to(self.position) <= delta * self.moveSpeed:
		self.position = _nextPosition
		_checkAndMove()
		return
	
	var collision := self.move_and_collide(_moveDirection * delta * self.moveSpeed)
	if collision:
		_moveDirection = -_moveDirection
		_nextPosition = _nextPosition + _moveDirection * GameConfig.TILE_SIZE
		_nextPosition = _nextPosition.snapped(GameConfig.TILE_HALF_SIZE_VECTOR)


func _on_DamageArea_body_entered(body):
	if body != null && is_instance_valid(body) && body.has_method('damage'):
		var direction = (body.global_position - self.global_position).normalized()
		body.damage(damageAmount, direction)


func _on_PausedTimer_timeout() -> void:
	_isPaused = false


func _dead() -> void:
	_isDead = true
	_animationPlayer.current_animation = 'die'
	yield(_animationPlayer, 'animation_finished')
	
	var item = GameConfig.Item.instance()
	item.global_position = self.global_position
	self.get_parent().add_child(item)
	
	self.queue_free()


func bomb(byKiller : int, damage : int) -> void:
	if _isDead || self.isInvulnerable:
		return
	_dead()


func collect(item : GameConfig.ItemData) -> void:
	if item == null || item.data == '':
		return
	
	if item.type == GameConfig.ItemType.ActorEffect:
		var power : Node = load(item.data).instance()
		self.add_child(power)
