extends Node2D

export(PackedScene) var coinScene = null
export(PackedScene) var powerScene = null
export(float) var minPlayerDist = 80
export(float) var minObstacleDist = 120

onready var _player = $Player
onready var _startPosition = _player.position
onready var _ui = $HUD/UI
onready var _pointsCurve = $CactusPoints.curve
onready var _cactus = $CactusPoints/Cactus
onready var _coinContainer = $CoinContainer
onready var _countTimer = $CountTimer
onready var _powerTimer = $PowerTimer
onready var _gameOverAudioPlayer = $GameOverAudio
onready var _levelAudioPlayer = $LevelUpAuido

var _level = 0 # 当前关卡
var _timeLeft = 0 # 剩余时间
var _totalCoins = 0 # 金币总数
var _collectedCoins = 0 # 收集金币数

func _ready():
	randomize() # 保证每次游戏都随机
	_player.isControllable = false

# 游戏结束初始化某些变量
func _gameOver():
	_level = 0
	_countTimer.stop()
	_ui.showGameOver()
	for coin in _coinContainer.get_children():
		coin.queue_free()

# 重新开始游戏调用方法
func _restartGame():
	_player.isControllable = false
	_totalCoins = _calculateTotal(_level)
	_timeLeft = _calculateDuration(_level)
	_collectedCoins = 0
	_ui.showScore(_collectedCoins)
	_ui.showTime(_timeLeft)
	_spawnObstacles()
	_spawnCoins()
	_player.restart(_startPosition)
	
	_ui.displayReady(_totalCoins, true)
	yield(self.get_tree().create_timer(1.5, false), "timeout")
	_ui.displayReady()
	_player.isControllable = true
	_countTimer.start()
	_spawnPowerup()

# 进入下一关卡
func _nextLevel():
	_level += 1
	_restartGame()

# 玩家收集金币发出的信号处理
func _on_Player_coin_collected(count):
	_ui.showScore(count)
	if count >= _totalCoins:
		_countTimer.stop()
		_levelAudioPlayer.play()
		_nextLevel()

# 玩家受到伤害，游戏结束信号处理
func _on_Player_game_over():
	_gameOver()

# 玩家收集到能量币发出的信号处理
func _on_Player_power_collected(buffer):
	_timeLeft += buffer
	_ui.showTime(_timeLeft)

# 游戏时间超时，游戏结束
func _on_Timer_timeout():
	_timeLeft -= 1
	_ui.showTime(_timeLeft)
	if _timeLeft <= 0:
		_player.isControllable = false
		_gameOverAudioPlayer.play()
		_gameOver()

# 能量币定时生产
func _on_PowerTimer_timeout():
	var power = powerScene.instance()
	var pos = _makeRandomPosition()
	power.position = pos
	self.add_child(power)

# UI界面点击开始按钮触发开始信号
func _on_UI_start_game():
	_nextLevel()

# 创建当前关卡的所有金币
func _spawnCoins():
	if coinScene == null:
		return
	var playerPos = _player.position
	var obstaclePos = _cactus.position
	for i in range(_totalCoins):
		var coin = coinScene.instance()
		var pos = _makeRandomPosition()
		# 如果金币产生位置在玩家或者障碍物内，则重新生成一个位置
		while pos.distance_to(playerPos) < minPlayerDist || pos.distance_to(obstaclePos) < minObstacleDist:
			pos = _makeRandomPosition()
		coin.position = pos
		_coinContainer.add_child(coin)

# 设置当前关卡的障碍物置
func _spawnObstacles():
	var index = randi() % _pointsCurve.get_point_count()
	var position = _pointsCurve.get_point_position(index)
	_cactus.position = position

# 设置能量币出现的时间并计时
func _spawnPowerup():
	var powerTime = _makeRandomPowerAppearTime(_timeLeft)
	_powerTimer.wait_time = powerTime
	_powerTimer.start()

# 根据当前关卡设计金币总数
func _calculateTotal(level):
	return level + 5

# 根据当前关卡设计超时时长
func _calculateDuration(level):
	return level + 5

# 当前时间下设计随机能量出现时间
func _makeRandomPowerAppearTime(timeLeft):
	return rand_range(0, timeLeft)

# 根据窗口尺寸设计随机金币位置
func _makeRandomPosition():
	var x = rand_range(0, ProjectSettings.get('display/window/size/width'))
	var y = rand_range(0, ProjectSettings.get('display/window/size/height'))
	return Vector2(x, y)
