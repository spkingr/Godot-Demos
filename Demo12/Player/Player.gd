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
export var layBombAudio : AudioStream = null
export var hurtAudio : AudioStream = null
export var pickupAudio : AudioStream = null

onready var _sprite := $Sprite as Sprite
onready var _collisionshape := $CollisionShape2D as CollisionShape2D
onready var _animationPlayer := $AnimationPlayer as AnimationPlayer
onready var _cooldownTimer := $CooldownTimer as Timer
onready var _progressBar := $ProgressBar as ProgressBar
onready var _labelName := $LabelName as Label
onready var _stunTimer := $StunTimer as Timer
onready var _audioPlayer := $AudioStreamPlayer as AudioStreamPlayer

var _velocity := Vector2.ZERO
var _isStuning := false
var _isDead := false
var _canInput := true
var _killers := []
var _items := []           # item index in GameConfig.items
var _lastKillerId := 0

var playerId := 0
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
	self.health = maxHealth
	self.power = 1
	_labelName.text = playerName
	_labelName.hide()

	_sprite.material.set_shader_param('tint_color', playerColor)
	
	if self.is_network_master():
		GameConfig.connect('text_enter', self, '_on_GameConfig_text_enter')


func _on_GameConfig_text_enter(isEntering : bool) -> void:
	_canInput = ! isEntering


func _unhandled_input(event: InputEvent) -> void:
	# Important: master + puppet
	if event.is_action_pressed('show_name'):
		_labelName.show()
	elif event.is_action_released('show_name'):
		_labelName.hide()
	
	if ! self.is_network_master():
		return
	
	if _isStuning || _isDead:
		return
	
	if event.is_action_pressed('lay_bomb'):
		_layBomb()


func _process(delta):
	if ! self.is_network_master():
		return
	
	if _isStuning || _isDead:
		return
	
	var dirX := 0
	var dirY := 0
	if _canInput:
		dirX = int(Input.is_action_pressed('move_right')) - int(Input.is_action_pressed('move_left'))
		dirY = int(Input.is_action_pressed('move_down')) - int(Input.is_action_pressed('move_up'))
	
	var targetAnim := ''
	var flipH := _sprite.flip_h
	if dirX != 0 || dirY != 0:
		_velocity = Vector2(dirX, dirY).normalized() * moveSpeed
		targetAnim = 'move'
		flipH = dirX < 0
	else:
		_velocity = Vector2(0, 0)
		targetAnim = 'idle'
	
	# puppet
	if _animationPlayer.current_animation != targetAnim:
		self.rpc('_changeAnimation', targetAnim)
	if _sprite.flip_h != flipH:
		self.rpc('_changeFaceDir', flipH)
	

func _physics_process(delta):
	if ! self.is_network_master():
		return
	
	if _isStuning || _isDead:
		return
	
	self.move_and_slide(_velocity)
	
	# puppet
	self.rpc_unreliable('_updatePosition', self.position)


remote func _updatePosition(pos : Vector2) -> void:
	self.position = pos


remotesync func _changeFaceDir(flip : bool) -> void:
	_sprite.flip_h = flip


remotesync func _changeAnimation(anim : String) -> void:
	_animationPlayer.current_animation = anim


remotesync func _deleteObject() -> void:
	self.queue_free()


remote func _setHealth(health : float) -> void:
	self.health = health


remotesync func _addItem(id : int, data : String) -> void:
	var power : Node = load(data).instance()
	power.set_network_master(id)
	self.add_child(power)


# Bug：不能在同一地点丢两个炸弹
func _layBomb() -> void:
	if ! _cooldownTimer.is_stopped():
		return
	_cooldownTimer.start()
	
	var itemIndex = -1 if _items.size() <= 0 else _items.pop_back()
	var pos := self.global_position
	self.emit_signal('lay_bomb', playerId, pos, self.power, itemIndex)
	
	if layBombAudio && GameConfig.isSoundOn:
		_audioPlayer.stream = layBombAudio
		_audioPlayer.play()


func _on_StunTimer_timeout() -> void:
	_isStuning = false
	_lastKillerId = 0
	_velocity = Vector2.ZERO
	self.rpc('_changeAnimation', 'idle')


func _canTakeDamage(byId : int) -> bool:
	if _isDead:
		return false
	if _isStuning:
		if byId < 0:
			return false
		elif byId > 0 && byId == _lastKillerId:
			return false
	return true


master func bomb(byKiller : int, damage : int) -> void:
	damage(damage, Vector2.ZERO, byKiller)


master func damage(amount : float, direction : Vector2 = Vector2.ZERO, byId : int = -1) -> void:
	if ! _canTakeDamage(byId):
		return
	
	_isStuning = true
	_lastKillerId = byId
	self.health -= amount
	self.emit_signal('damaged', byId)
	self.rpc('_setHealth', self.health)
	
	if self.health <= 0.0:
		_isDead = true
		_stunTimer.stop()
		self.rpc('_changeAnimation', 'die')
		yield(_animationPlayer, 'animation_finished')
		
		self.emit_signal('dead', byId)
		self.rpc('_deleteObject')
		return
	
	_velocity = direction * stunForce
	self.rpc('_changeAnimation', 'stun')
	_stunTimer.start()
	
	if hurtAudio && GameConfig.isSoundOn:
		_audioPlayer.stream = hurtAudio
		_audioPlayer.play()


master func collect(itemIndex : int) -> void:
	var item = GameConfig.items[itemIndex]
	if item == null || item.data == '':
		return
	var type := ''
	match item.type:
		GameConfig.ItemType.ActorEffect:
			type = 'Player'
			self.rpc('_addItem', GameState.myId, item.data)
		GameConfig.ItemType.BombEffect:
			type = 'Bomb'
			_items.append(itemIndex)
		_:
			type = 'Empty'
	
	self.emit_signal('collect_item', item)
	
	if  pickupAudio && GameConfig.isSoundOn:
		_audioPlayer.stream = pickupAudio
		_audioPlayer.play()


