extends Control

signal start_game() # 游戏开始信号

onready var _scoreLabel = $HBoxContainer/ScoreLabel
onready var _waveLabel = $HBoxContainer/WaveLabel
onready var _messageLabel = $VBoxContainer/MessageLabel
onready var _startButton = $VBoxContainer/CenterContainer/StartButton

var _isStarted = false # 游戏是否已经开始
var _isPaused = false  # 游戏是否被暂停

func _input(event):
	if event.is_action_pressed('pause') && _isStarted:
		_isPaused = !_isPaused
		self.get_tree().paused = _isPaused
		if _isPaused:
			_messageLabel.text = 'Paused'
			_messageLabel.visible = true
		else:
			_messageLabel.visible = false
	elif event.is_action_pressed('shoot') && ! _isStarted:
		_on_StartButton_pressed()

# 按下开始按钮
func _on_StartButton_pressed():
	_isStarted = true
	_startButton.visible = false
	_messageLabel.visible = false
	self.emit_signal('start_game')

# 显示游戏结束
func showGameOver():
	_messageLabel.text = 'Game Over'
	_messageLabel.visible = true
	
# 显示开始按钮
func showStartButton():
	_isStarted = false
	_startButton.visible = true

# 显示分数
func updateScore(score):
	_scoreLabel.text = 'Score: %s' % score
	
# 显示敌人波数
func updateWave(wave):
	_waveLabel.text = 'Current Wave: %s' % wave
	_messageLabel.text = 'Wave %s' % wave
	_messageLabel.visible = true

# 隐藏信息
func hideMessage():
	_messageLabel.visible = false
	