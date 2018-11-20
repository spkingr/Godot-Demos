extends Control

signal start_game()

onready var _labelScore = $MarginContainer/HBoxContainer/LabelScore
onready var _labelTime = $MarginContainer/HBoxContainer/LabelTime
onready var _labelMessage = $VBoxContainer/LabelMessage
onready var _labelReady = $VBoxContainer/LabelReady
onready var _buttonStart = $MarginContainer2/ButtonStart

var _isPaused = true

func _input(event):
	if event.is_action_pressed('start'):
		if self.get_tree().paused != _isPaused:
			self.emit_signal('start_game')
		
		_isPaused = ! _isPaused
		self.get_tree().paused = _isPaused
		if _isPaused:
			_labelMessage.visible = true
			_labelMessage.text = 'Paused'
		else:
			_labelMessage.visible = false
			_buttonStart.visible = false

func _on_ButtonStart_pressed():
	_isPaused = false
	_labelMessage.visible = false
	_buttonStart.visible = false
	self.emit_signal('start_game')

func displayReady(target = 0, display = false):
	_labelReady.text = '%d, Ready!' % target
	_labelReady.visible = display

func showGameOver():
	_isPaused = true
	_labelMessage.text = 'Game Over'
	_labelMessage.visible = true
	_buttonStart.text = 'Restart'
	_buttonStart.visible = true

func showScore(score):
	_labelScore.text = str(score)

func showTime(time):
	_labelTime.text = str(time)