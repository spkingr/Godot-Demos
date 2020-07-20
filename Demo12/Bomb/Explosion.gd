extends Area2D
class_name Explosion


onready var _sprite := $Sprite as Sprite
onready var _collisionshape := $CollisionShape2D as CollisionShape2D

var _damage := 0
var _tileFrame := 0
var _direction := Vector2.ZERO
var _ownerId := 0
var _isDisabled := false


func _ready():
	_sprite.frame = _tileFrame
	
	var shape := RectangleShape2D.new()
	match _direction:
		Vector2.LEFT:
			_sprite.rotation_degrees = 180
			shape.extents = Vector2(32, 20)
		Vector2.DOWN:
			_sprite.rotation_degrees = 90
			shape.extents = Vector2(20, 32)
		Vector2.UP:
			_sprite.rotation_degrees = -90
			shape.extents = Vector2(20, 32)
		Vector2.RIGHT:
			shape.extents = Vector2(32, 20)
		_:
			shape.extents = Vector2(32, 32)
	
	if !_isDisabled:
		_collisionshape.shape = shape


func _on_LifeTimer_timeout() -> void:
	self.queue_free()


func _on_Explosion_body_entered(body : CollisionObject2D) -> void:
	if ! self.is_network_master():
		return
	
	if body != null && is_instance_valid(body) && body.has_method('bomb'):
		body.rpc('bomb', _ownerId, _damage)


func _on_Explosion_area_entered(area: Area2D) -> void:
	if ! self.is_network_master():
		return
	
	if area != null && is_instance_valid(area) && area.has_method('bomb'):
		area.rpc('bomb')


func setup(ownerId : int, direction : Vector2 = Vector2.ZERO, tileFrame : int = 1, damage : int = 0, isDisabled : bool = false) -> void:
	_ownerId = ownerId
	_direction = direction
	_tileFrame = tileFrame
	_damage = damage
	_isDisabled = isDisabled

