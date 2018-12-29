extends Node2D

onready var _player = $Player
onready var _playerLabel = $Player/Label
onready var _labelEnemy1 = $Control/LabelEnemy1
onready var _labelEnemy2 = $Control/LabelEnemy2
onready var _labelCoin1 = $Control/LabelCoin1
onready var _labelCoin2 = $Control/LabelCoin2
onready var _playerAnimator = $Player/AnimationPlayer
onready var _enemyAnimator1 = $Enemy1/AnimationPlayer
onready var _enemyAnimator2 = $Enemy2/AnimationPlayer
onready var _coinAnimator1 = $Coin1/AnimationPlayer
onready var _coinAnimator2 = $Coin2/AnimationPlayer

export(float) var speed = 8

func _ready():
	_labelEnemy1.text = ''
	_labelEnemy2.text = ''
	_labelCoin1.text = ''
	_labelCoin2.text = ''

func _process(delta):
	var hDir = int(Input.is_action_pressed('ui_right')) - int(Input.is_action_pressed('ui_left'))
	var vDir = int(Input.is_action_pressed('ui_down')) - int(Input.is_action_pressed('ui_up'))
	var velocity = Vector2(hDir, vDir).normalized() * speed
	_player.position += velocity

func _on_Player_area_entered(area):
	_playerAnimator.current_animation = 'flash'
	_playerLabel.text = area.name

func _on_Player_area_exited(area):
	_playerLabel.text = ''
	_playerAnimator.current_animation = 'normal'

func _on_Enemy1_area_entered(area):
	_enemyAnimator1.current_animation = 'flash'
	_labelEnemy1.text = area.name

func _on_Enemy1_area_exited(area):
	_labelEnemy1.text = ''
	_enemyAnimator1.stop()

func _on_Enemy2_area_entered(area):
	_enemyAnimator2.current_animation = 'flash'
	_labelEnemy2.text = area.name

func _on_Enemy2_area_exited(area):
	_labelEnemy2.text = ''
	_enemyAnimator2.stop()

func _on_Coin1_area_entered(area):
	_coinAnimator1.current_animation = 'flash'
	_labelCoin1.text = area.name

func _on_Coin1_area_exited(area):
	_labelCoin1.text = ''
	_coinAnimator1.stop()

func _on_Coin2_area_entered(area):
	_coinAnimator2.current_animation = 'flash'
	_labelCoin2.text = area.name

func _on_Coin2_area_exited(area):
	_labelCoin2.text = ''
	_coinAnimator2.stop()
