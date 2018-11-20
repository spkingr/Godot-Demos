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
onready var _gameOverAuidoPlayer = $GameOverAudio
onready var _levelAudioPlayer = $LevelUpAuido

var _level = 0
var _timeLeft = 0
var _totalCoins = 0
var _collectedCoins = 0

func _ready():
	randomize()
	_player.isControllable = false

func _gameOver():
	_level = 0
	_countTimer.stop()
	_ui.showGameOver()
	for coin in _coinContainer.get_children():
		coin.queue_free()

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

func _nextLevel():
	_level += 1
	_restartGame()

func _on_Player_coin_collected(count):
	_ui.showScore(count)
	if count >= _totalCoins:
		_countTimer.stop()
		_levelAudioPlayer.play()
		_nextLevel()

func _on_Player_game_over():
	_gameOver()

func _on_Player_power_collected(buffer):
	_timeLeft += buffer
	_ui.showTime(_timeLeft)

func _on_Timer_timeout():
	_timeLeft -= 1
	_ui.showTime(_timeLeft)
	if _timeLeft <= 0:
		_player.isControllable = false
		_gameOverAuidoPlayer.play()
		_gameOver()

func _on_PowerTimer_timeout():
	var power = powerScene.instance()
	var pos = _makeRandomPosition()
	power.position = pos
	self.add_child(power)

func _on_UI_start_game():
	_nextLevel()

func _spawnCoins():
	if coinScene == null:
		return
	var playerPos = _player.position
	var obstaclePos = _cactus.position
	for i in range(_totalCoins):
		var coin = coinScene.instance()
		var pos = _makeRandomPosition()
		while pos.distance_to(playerPos) < minPlayerDist || pos.distance_to(obstaclePos) < minObstacleDist:
			pos = _makeRandomPosition()
		coin.position = pos
		_coinContainer.add_child(coin)

func _spawnObstacles():
	var index = randi() % _pointsCurve.get_point_count()
	var position = _pointsCurve.get_point_position(index)
	_cactus.position = position
	
func _spawnPowerup():
	var powerTime = _makeRandomPowerAppearTime(_timeLeft)
	_powerTimer.wait_time = powerTime
	_powerTimer.start()

func _calculateTotal(level):
	return level + 5

func _calculateDuration(level):
	return level + 5

func _makeRandomPowerAppearTime(timeLeft):
	return rand_range(0, timeLeft)

func _makeRandomPosition():
	var x = rand_range(0, ProjectSettings.get('display/window/size/width'))
	var y = rand_range(0, ProjectSettings.get('display/window/size/height'))
	return Vector2(x, y)
