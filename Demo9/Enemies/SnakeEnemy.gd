extends Area2D

const UNIT = 16

export(float) var patrolRange = 1 * UNIT

onready var _sprite = $Sprite
onready var _animator = $AnimationPlayer

var _walkSpeed: float = 2 * UNIT / 2.0
var _startPosition: float = 0.0


func _ready():
	_startPosition = self.global_position.x


func _process(delta):
	self.position.x += _walkSpeed * delta
	
	if self.global_position.x >= _startPosition + patrolRange || self.global_position.x <= _startPosition - patrolRange:
		_walkSpeed = - _walkSpeed
		_sprite.flip_h = ! _sprite.flip_h


func _on_SnakeEnemy_body_entered(body):
	if body.is_in_group('player') && body.has_method('attacked'):
		body.attacked()


func die():
	self.set_process(false)
	_animator.current_animation = 'die'
	