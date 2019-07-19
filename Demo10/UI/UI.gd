extends CanvasLayer

signal start_game()


export(StreamTexture) var redBar : = preload("res://Assets/images/bar_red_200.png")
export(StreamTexture) var yellowBar : = preload("res://Assets/images/bar_yellow_200.png")
export(StreamTexture) var greenBar : = preload("res://Assets/images/bar_green_200.png")

onready var _labelMessage : = $LabelMessage
onready var _buttonStart : = $ButtonStart
onready var _labelScore : = $MarginContainer/HBoxContainer/LabelScore
onready var _lifes : = [$MarginContainer/HBoxContainer/Life3, $MarginContainer/HBoxContainer/Life2, $MarginContainer/HBoxContainer/Life1]
onready var _healthBar : = $MarginContainer/CenterContainer/HealthBar


func _ready():
	showMessage('')


func _input(event):
	if event.is_action_pressed('pause'):
		self.get_tree().paused = ! self.get_tree().paused
		if self.get_tree().paused:
			showMessage('Paused!')
			_buttonStart.hide()
		else:
			showMessage('')
			_buttonStart.show()


func _on_ButtonStart_pressed():
	_buttonStart.hide()
	self.emit_signal('start_game')


# 初始化
func init():
	showMessage('')
	_buttonStart.show()
	updateScores(0)


# 显示信息
func showMessage(message : String) -> void:
	_labelMessage.text = message
	_labelMessage.visible = message != ''


# 更新生命条数，通过控制图片显示
func updateLifes(count : int) -> void:
	for i in range(_lifes.size()):
		_lifes[i].visible = count > i


# 更新生命值
func updateHealth(percentage : float) -> void:
	if percentage < 0:
		percentage = 0
	if percentage < 0.3:
		_healthBar.texture_progress = redBar
	elif percentage < 0.6:
		_healthBar.texture_progress = yellowBar
	else:
		_healthBar.texture_progress = greenBar
	_healthBar.value = percentage * _healthBar.max_value


# 更新分数
func updateScores(score : int) -> void:
	_labelScore.text = 'Score %s' % score


func _on_TextureButton_pressed():
	$NoticePanel.queue_free()

