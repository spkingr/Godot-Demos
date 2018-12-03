extends Control

# 开始游戏的信号
signal start_game()

onready var _labelScore = $MarginContainer/HBoxContainer/LabelScore
onready var _labelTime = $MarginContainer/HBoxContainer/LabelTime
onready var _labelMessage = $VBoxContainer/LabelMessage
onready var _labelReady = $VBoxContainer/LabelReady
onready var _buttonStart = $MarginContainer2/ButtonStart

# 当前游戏是否被暂停，初始为“是”
var _isPaused = true

# 监听用户的输入
func _input(event):
	if event.is_action_pressed('start'):
		# 这个if条件语句只会在游戏开始时运行一次！
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

# 开始游戏按钮被按下
func _on_ButtonStart_pressed():
	_isPaused = false
	_labelMessage.visible = false
	_buttonStart.visible = false
	self.emit_signal('start_game')

# 显示Ready和目标金币数文本
func displayReady(target = 0, display = false):
	_labelReady.text = '%d, Ready!' % target
	_labelReady.visible = display

# 游戏结束显示的信息
func showGameOver():
	_isPaused = true
	_labelMessage.text = 'Game Over'
	_labelMessage.visible = true
	_buttonStart.text = 'Restart'
	_buttonStart.visible = true

# 显示分数（金币个数）
func showScore(score):
	_labelScore.text = str(score)

# 显示时间（剩余时间）
func showTime(time):
	_labelTime.text = str(time)
