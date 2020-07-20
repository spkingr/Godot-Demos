extends Area2D
class_name Item


onready var _animationPlayer := $AnimationPlayer as AnimationPlayer
onready var _sprite := $Sprite as Sprite

var _isPicked := false

var type : int = 0 # items index(in GameConfig)


func _ready() -> void:
	var data = GameConfig.items[type]
	_sprite.texture = load(data.icon)


func _on_Item_body_entered(body: Node) -> void:
	if ! self.is_network_master():
		return
	
	if ! _isPicked && is_instance_valid(body) && body.has_method('collect'):
		_isPicked = true
		body.rpc('collect', type)
		self.rpc('_setPicked')


remotesync func _setPicked() -> void:
	_animationPlayer.play('picked')


func _on_LifeTimer_timeout() -> void:
	_animationPlayer.current_animation = 'disappear'


remotesync func bomb():
	_animationPlayer.playback_speed = 2.0
	_animationPlayer.current_animation = 'disappear'

