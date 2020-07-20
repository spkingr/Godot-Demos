extends StaticBody2D
class_name Bomb


signal explosion(ownerId, tilePos, bombPower)


export var damage : int = 80

onready var _sprite := $Sprite as Sprite
onready var _collisionShape := $CollisionShape2D as CollisionShape2D
onready var _explodeTimer := $ExplodeTimer as Timer
onready var _particles := $Particles2D as CPUParticles2D
onready var _animationPlayer := $AnimationPlayer as AnimationPlayer
onready var _audioPlayer := $AudioStreamPlayer as AudioStreamPlayer

var _ownerId := 0
var _tilePos := Vector2.ZERO
var _addons := []

var power := 1
var timeToExplode : float = 0.0 setget __setTimeToExplode__


func __setTimeToExplode__(value : float) -> void:
	if value > 0.0 && _explodeTimer:
		_explodeTimer.wait_time = value


func _ready() -> void:
	for node in _addons:
		self.add_child(node)


func _on_EnableCollisionTimer_timeout():
	_animationPlayer.stop()
	_sprite.self_modulate = Color.white
	_collisionShape.set_deferred('disabled', false)
	_particles.emitting = true
	
	if timeToExplode > 0.0:
		_explodeTimer.wait_time = timeToExplode
	_explodeTimer.start()


remotesync func _deleteObject() -> void:
	if GameConfig.isSoundOn:
		_collisionShape.set_deferred('disabled', true)
		self.hide()
		_audioPlayer.play()
		yield(_audioPlayer, 'finished')
	
	self.queue_free()


func _on_ExplodeTimer_timeout():
	if ! self.is_network_master():
		return
	
	bomb()


func setup(ownerId : int, tilePos : Vector2, bombPower : int, item : GameConfig.ItemData = null) -> void:
	_ownerId = ownerId
	_tilePos = tilePos
	power = bombPower
	if item:
		var node : Node = load(item.data).instance()
		_addons.append(node)


master func bomb(_id : int = -1, _damage : int = -1) -> void:
	self.emit_signal('explosion', _ownerId, _tilePos, power, damage)
	self.rpc('_deleteObject')


