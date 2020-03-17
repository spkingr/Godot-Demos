extends Actor
class_name Player


signal lay_bomb(ownerId, pos, power, item)
signal damaged(byId)
signal collect_item(item)
signal dead(byId)

const PLAYER_COLLISION_LAYER := 0
const INVUL_COLLISION_LAYER := 6
const ENEMY_COLLISION_MASK := 2

export(float, 0.0, 1.0) var healthTolerance : float = 0.25
export var stunForce : float = 200.0

onready var _sprite := $Sprite as Sprite
onready var _collisionshape := $CollisionShape2D as CollisionShape2D
onready var _animationPlayer := $AnimationPlayer as AnimationPlayer
onready var _cooldownTimer := $CooldownTimer as Timer
onready var _progressBar := $ProgressBar as ProgressBar
onready var _labelName := $LabelName as Label
onready var _stunTimer := $StunTimer as Timer

var _velocity := Vector2.ZERO
var _playerId := 0
var _isStuning := false
var _isDead := false
var _canInput := true
var _killers := []
var _items := []

var playerName := 'Player'
var playerColor := Color.white


func __setMaxHealth__(value : float) -> void:
	.__setMaxHealth__(value)
	_progressBar.max_value = value


func __setHealth__(value : float) -> void:
	var old := health
	.__setHealth__(value)
	
	_progressBar.visible = value > 0
	_progressBar.value = value
	if old / self.maxHealth > healthTolerance && value / self.maxHealth <= healthTolerance:
		_progressBar.get_stylebox('fg').bg_color = Color.yellow
	elif old / self.maxHealth <= healthTolerance && value / self.maxHealth > healthTolerance:
		_progressBar.get_stylebox('fg').bg_color =  Color.green


func __setIsInvulnerable__(value : bool) -> void:
	if isInvulnerable == value:
		return
	.__setIsInvulnerable__(value)
	self.set_collision_layer_bit(PLAYER_COLLISION_LAYER, ! value)
	self.set_collision_layer_bit(INVUL_COLLISION_LAYER, value)
	self.set_collision_mask_bit(ENEMY_COLLISION_MASK, ! value)


func _ready() -> void:
	GameConfig.connect('text_enter', self, '_on_GameConfig_text_enter')
	_sprite.material.set_shader_param('tint_color', playerColor)
	
	self.health = maxHealth
	self.power = 1
	_labelName.text = playerName
	_labelName.hide()


func _on_GameConfig_text_enter(isEntering : bool) -> void:
	_canInput = ! isEntering


func _unhandled_input(event: InputEvent) -> void:
	if _isStuning || _isDead:
		return
	
	if event.is_action_pressed('show_name'):
		_labelName.show()
	elif event.is_action_released('show_name'):
		_labelName.hide()
	
	if event.is_action_pressed('lay_bomb'):
		_layBomb()


func _process(delta):
	if _isStuning || _isDead:
		return
	
	var dirX := 0
	var dirY := 0
	if _canInput:
		dirX = int(Input.is_action_pressed('move_right')) - int(Input.is_action_pressed('move_left'))
		dirY = int(Input.is_action_pressed('move_down')) - int(Input.is_action_pressed('move_up'))
	
	if dirX != 0 || dirY != 0:
		_velocity = Vector2(dirX, dirY).normalized() * moveSpeed
		_animationPlayer.current_animation = 'move'
		_sprite.flip_h = dirX < 0
	else:
		_velocity = Vector2(0, 0)
		_animationPlayer.current_animation = 'idle'


func _physics_process(delta):
	if _isDead:
		return
	
	self.move_and_slide(_velocity)
#	self.rpc_unreliable('_updatePosition', self.position)


puppet func _updatePosition(pos : Vector2) -> void:
	self.position = pos


func _layBomb() -> void:
	if ! _cooldownTimer.is_stopped():
		return
	_cooldownTimer.start()
	
	var item = null if _items.size() <= 0 else _items.pop_back()
	var pos := self.global_position
	self.emit_signal('lay_bomb', _playerId, pos, self.power, item)


func bomb(byKiller : int, damage : int) -> void:
	damage(damage, Vector2.ZERO, byKiller)


func damage(amount : float, direction : Vector2 = Vector2.ZERO, byId : int = -1) -> void:
	if byId < 0 && (_isStuning || _isDead):
		return
	
	self.emit_signal('damaged', byId)
	
	self.health -= amount
	if self.health <= 0.0:
		_isDead = true
		_animationPlayer.current_animation = 'die'
		yield(_animationPlayer, 'animation_finished')
		
		self.emit_signal('dead', byId)
		self.queue_free()
		return
	
	_isStuning = true
	_velocity = direction * stunForce
	_animationPlayer.current_animation = 'stun'
	_stunTimer.start()
	
	yield(_stunTimer, 'timeout')
	_isStuning = false
	_velocity = Vector2.ZERO
	_animationPlayer.current_animation = 'idle'


func collect(item : GameConfig.ItemData) -> void:
	if item == null || item.data == '':
		return
	var power : Node = load(item.data).instance()
	var type := ''
	match item.type:
		GameConfig.ItemType.ActorEffect:
			type = 'Player'
			self.add_child(power)
		GameConfig.ItemType.BombEffect:
			type = 'Bomb'
			_items.append(item)
		_:
			type = 'Empty'
	
	self.emit_signal('collect_item', item)
