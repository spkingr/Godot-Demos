extends KinematicBody2D


export var playerData : Resource = null
export var messageEvent : Resource = null
export var triggerEvent : Resource = null

var _colliders := []

var target := Vector2.ZERO
var velocity := Vector2.ZERO


func _ready() -> void:
	target = self.global_position
	
	if playerData != null:
		assert(playerData is DataResource, 'Player data must be the instance of DataResource.')
	
	if playerData:
		$Label.text = playerData.name
		$Sprite.texture = load(playerData.imageSrc)
	
	if triggerEvent && triggerEvent is EventResource:
		triggerEvent.connect('custom_event', self, '_onTriggerEventHandler')


func _physics_process(_delta: float) -> void:
	if playerData == null:
		return
	
	var colliders := []
	if self.global_position.distance_to(target) > playerData.minStopDistance:
		var desiredVelocity = (target - self.global_position).normalized()
		velocity += desiredVelocity * playerData.turningSpeed
		velocity = velocity.normalized() * playerData.moveSpeed
		velocity = self.move_and_slide(velocity)
		colliders = _handleSlideCollision()
	else:
		velocity = Vector2.ZERO
	_updateColliders(colliders)


func _process(delta: float) -> void:
	if velocity != Vector2.ZERO:
		self.rotation = velocity.angle()
	$Label.rect_rotation = 0.0


func _handleSlideCollision() -> Array:
	var colliders := []
	var count := self.get_slide_count()
	for i in range(count):
		var collision := self.get_slide_collision(i)
		var name : String = collision.collider.name
		if ! name in colliders:
			colliders.append(collision.collider.name)
	colliders.sort()
	return colliders


func _updateColliders(colliders : Array) -> void:
	if _colliders == colliders:
		return
	_colliders = colliders
	
	if messageEvent && messageEvent is EventResource:
		var info := '[color=yellow]%s[/color] -> ' % self.name
		if _colliders.empty():
			info += 'no collision'
		else:
			for name in _colliders:
				info += name + ', '
			info = info.trim_suffix(', ')
		messageEvent.emitSignal(info)


func _onTriggerEventHandler(type : String, name : String) -> void:
	assert(type == 'triggerEvent', 'Only receive trigger events.')
	$Tween.stop_all()
	$Tween.interpolate_property($Sprite, 'modulate', Color.white, Color.yellow, 0.5, Tween.TRANS_BOUNCE, Tween.EASE_OUT)
	$Tween.interpolate_property($Sprite, 'modulate', Color.yellow, Color.white, 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN, 0.5)
	$Tween.start()

