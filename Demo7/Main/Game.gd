extends Node2D

# 三种子场景：玩家、岩石、敌人
export(PackedScene) var playerScene = null
export(PackedScene) var rockScene = null
export(PackedScene) var alienScene = null

onready var _ui = $UI
onready var _startPosition = $StartPosition.position
onready var _enemyContainer = $EnemyContainer
onready var _audioPlayer = $BackgroundMusic

var _isGameOver = false # 游戏是否结束
var _score = 0          # 分数
var _currentWave = 0    # 敌人波数
var _totalAliens = 0    # 敌人总数
var _totalRocks = 0     # 岩石总数
var _enemyCount = -1    # 计数：敌人+岩石

func _ready():
	randomize()

func _process(delta):
	# 如果计数为0，且所有敌人被移除则进入下一波
	if !_isGameOver && _enemyCount == 0 && _enemyContainer.get_child_count() == 0:
		_enemyCount = -1
		_nextLevel()
	# 如果游戏结束，且所有敌人被移除，显示开始按钮
	elif _isGameOver && _enemyContainer.get_child_count() == 0:
		_ui.showStartButton()

# （重新）开始游戏
func _restart():
	_isGameOver = false
	_score = 0
	_ui.updateScore(_score)
	_currentWave = 0
	_audioPlayer.play()
	
	# 添加玩家到当前场景
	if playerScene != null:
		var player = playerScene.instance()
		player.connect('game_over', self, '_on_Player_game_over')
		player.connect('score_updated', self, '_on_Player_score_updated')
		player.position = _startPosition
		self.add_child(player)
	
	# 开启第一关
	_nextLevel()

# 消灭（避开）所有敌人，进入下一关
func _nextLevel():
	_currentWave += 1
	_ui.updateWave(_currentWave)
	yield(self.get_tree().create_timer(3.0), 'timeout')
	_ui.hideMessage()
	_calculateEnemies()
	_enemyCount = _totalAliens + _totalRocks
	_generateRocks()
	_generateAliens()

# 每隔一定时间（随机）生成岩石
func _generateRocks():
	if rockScene == null:
		return
	for i in range(_totalRocks):
		if _isGameOver:
			return
		var rock = rockScene.instance()
		var yPosition = rand_range(-40, -100)
		rock.position = Vector2(80 * (randi() % 6) + 40, yPosition)
		_enemyContainer.add_child(rock)
		_enemyCount -= 1
		var nextTime = rand_range(0.5, 1.5)
		yield(self.get_tree().create_timer(nextTime, false), 'timeout')

# 每隔一定时间（随机）生成敌人
func _generateAliens():
	if alienScene == null:
		return
	for i in range(_totalAliens):
		if _isGameOver:
			return
		var alien = alienScene.instance()
		var yPosition = rand_range(-40, -100)
		alien.position = Vector2(60 * (randi() % 5) + 80, yPosition)
		_enemyContainer.add_child(alien)
		_enemyCount -= 1
		var nextTime = rand_range(1.0, 2.5)
		yield(self.get_tree().create_timer(nextTime, false), 'timeout')

# 根据当前关卡得出敌人数量
func _calculateEnemies():
	_totalAliens = _currentWave * 2 + 3
	_totalRocks = _currentWave * 3 + 5

# 游戏结束
func _on_Player_game_over():
	_isGameOver = true
	_enemyCount = -1
	_audioPlayer.stop()
	_ui.showGameOver()

# 更新分数
func _on_Player_score_updated():
	_score += 1
	_ui.updateScore(_score)

# 开始游戏
func _on_UI_start_game():
	_restart()
