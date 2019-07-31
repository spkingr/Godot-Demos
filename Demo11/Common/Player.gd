extends KinematicBody2D


const FLOOR_NORMAL := Vector2(0, -1)

export var bulletScene : PackedScene = null
export var isTopDown := false
export var moveSpeed : float = 200
export var jumpSpeed : float = 500
export var gravity : float = 1000
export var bulletForce : float = 800

onready var _animationPlayer := $AnimationPlayer
onready var _sprite := $Sprite
onready var _timer := $ShootTimer
onready var _bulletPositionNode := $StartPosition
onready var _bulletPosition := $StartPosition/Position2D

var _velocity := Vector2.ZERO
var _isInfInertia := true
var _canShoot := true


func _unhandled_input(event):
	if self.is_on_floor() && event.is_action_pressed('ui_select'):
		_velocity.y = - jumpSpeed
	
	if event is InputEventMouseButton && event.button_index == BUTTON_LEFT && event.pressed:
		_shoot()


func _physics_process(delta):
	var hDir := int(Input.is_action_pressed('ui_right')) - int(Input.is_action_pressed('ui_left'))
	var vDir := int(Input.is_action_pressed('ui_down')) - int(Input.is_action_pressed('ui_up'))
	var velocity := Vector2(hDir, vDir if isTopDown else 0).normalized() * moveSpeed
	if !isTopDown:
		velocity.y = _velocity.y + gravity * delta
	_velocity = self.move_and_slide(velocity, FLOOR_NORMAL, true, 4, PI / 2, _isInfInertia)
	
	if hDir:
		_animationPlayer.current_animation = 'run'
		_sprite.flip_h = hDir < 0
		_bulletPositionNode.scale.x = -1 if _sprite.flip_h else 1
	else:
		_animationPlayer.current_animation = 'idle'


func _shoot() -> void:
	if ! bulletScene || ! _canShoot:
		return
	_canShoot = false
	_timer.start()
	var ball := bulletScene.instance() as RigidBody2D
	ball.position = _bulletPosition.global_position
	ball.apply_central_impulse(bulletForce * _bulletPosition.transform.x)
	self.get_parent().add_child(ball)


func _on_ShootTimer_timeout():
	_canShoot = true


# 设置玩家是否为无限惯性力
func setInfiniteInertia(value : bool) -> void:
	_isInfInertia = value
