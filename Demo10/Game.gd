extends Node2D

const MAX_LIFES : = 3
const MIN_ROCK_SIZE : = 1


export(PackedScene) var RockScene : PackedScene = null
export(float) var timeToStart : = 3.0
export(float) var maxVelocity : = 200
export(float) var minVelocity : = 20
export(int, 1, 5) var initialRadius : = 3
export(int) var rockAmount : = 3

onready var _rocks : = $Rocks
onready var _player : = $Player
onready var _ui : = $UI
onready var _randomPoint : = $Path2D/RandomPoint
onready var _audio : = $AudioStreamPlayer
onready var _playerPosition : Vector2 = $Player.position

var _currentLevel : = 0
var _scores : = 0


func _ready():
	if RockScene == null:
		return
	randomize()
	for i in range(rockAmount):
		_spawnRock(initialRadius)


func _on_Rock_explode(radius, pos, velocity, laserVelocity):
	# 判断当前爆炸的岩石是不是最小尺寸，并更新分数，如果这是最后一个岩石进入下一关
	if radius <= MIN_ROCK_SIZE:
		_scores += MIN_ROCK_SIZE
		_ui.updateScores(_scores)
		if _rocks.get_child_count() <= 1: # 这里为1不是0，是因为岩石爆炸没有马上消失（见Rock.gd源码）
			_newLevel()
		return
	
	# 岩石分裂，分裂成比自己少 1 的半径的两颗岩石，速度变大，方向为垂直于碰撞体的方向
	var speedScale = 1.2
	var dir = laserVelocity.rotated(PI / 2).normalized()
	_spawnRock(radius - 1, pos + dir * radius, velocity.length() * dir * speedScale, false)
	_spawnRock(radius - 1, pos - dir * radius, - velocity.length() * dir * speedScale, false)


func _spawnRock(radius : float, pos : Vector2 = Vector2.ZERO, velocity : Vector2 = Vector2.ZERO, isGenerated : bool = true) -> void :
	# isGenerated为true表示随机生成速度
	if isGenerated:
		_randomPoint.offset = randi()
		pos = _randomPoint.position
		var speed = rand_range(minVelocity, maxVelocity)
		velocity = Vector2(speed, speed).rotated(rand_range(0, 2 * PI))
	
	# 创建岩石并添加
	var rock = RockScene.instance()
	rock.init(radius, pos, velocity)
	rock.connect('explode', self, '_on_Rock_explode')
	_rocks.add_child(rock)


func _newLevel() -> void:
	_currentLevel += 1
	_ui.showMessage('Level %s, Ready...' % _currentLevel)
	yield(self.get_tree().create_timer(timeToStart, false), 'timeout')
	_ui.showMessage('')	
	for i in range(_currentLevel - 1 + rockAmount):
		_spawnRock(initialRadius)


func startGame() -> void:
	for rock in _rocks.get_children():
		rock.queue_free()
	
	_player.lifes = MAX_LIFES
	_player.startGame(_playerPosition)
	
	_currentLevel = 0
	_newLevel()
	
	_audio.play()


func gameOver() -> void:
	_ui.showMessage('Game Over')
	_audio.stop()
	yield(self.get_tree().create_timer(timeToStart, false), 'timeout')
	_ui.init()

