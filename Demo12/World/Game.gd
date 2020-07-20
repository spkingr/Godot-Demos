extends Navigation2D


const PlayerNode : PackedScene = preload('res://Player/Player.tscn')

export var bombScene : PackedScene = null
export var explosionScene : PackedScene = null
export var enemyScene : PackedScene = null
export var maxEnemyCount : int = 5

onready var _tileMap : TileMap = $WorldMap
onready var _tileSet : TileSet = $WorldMap.tile_set
onready var _bombContainer : Node2D = $BombContainer
onready var _enemiesContainer : Node2D = $Enemies
onready var _playersContainer : Node2D = $Players
onready var _playerPositions := [$Players/Position1.position, $Players/Position2.position, $Players/Position3.position, $Players/Position4.position]
onready var _resultPopup := $CanvasLayer/HUD/ResultPopup as ResultPopup
onready var _infoPanel := $CanvasLayer/HUD/InfoPanelUI as InfoPanel
onready var _frequencyTimer := $SpawnFrequencyTimer as Timer
onready var _spawnTimer := $EnemySpawnTimer as Timer
onready var _audioPlayer := $AudioStreamPlayer as AudioStreamPlayer

var _allPlayers := []
var _enemyNameIndex := 0
var _bombNameIndex := 0
var _explosionNameIndex := 0
var _bombExtraDamage := 0


func _ready() -> void:
	if GameConfig.isSoundOn:
		_audioPlayer.play()
	
	_resultPopup.showPopup('Waiting for other players...', 'Waiting', true, _resultPopup.BUTTON_BACK_BIT + _resultPopup.BUTTON_STAY_BIT)
	
	GameState.connect('game_loaded', self, '_onGameLoaded')
	GameState.connect('game_ended', self, '_onGameEnded')
	GameState.connect('player_disconnected', self, '_onPlayerQuit')
	
	_setDifficulties()
	_addPlayers()
	
	GameConfig.sendMessage(GameConfig.MessageType.System, GameState.myId, 'enters the game!')
	GameConfig.rpc('sendMessage', GameConfig.MessageType.System, GameState.myId, 'enters the game!')


func _setDifficulties() -> void:
	var playerCount := GameState.otherPlayerNames.size() + 1
	maxEnemyCount = max(10 - playerCount * playerCount + playerCount, 5)
	_bombExtraDamage = 5 - playerCount * 10


func _addPlayers() -> void:
	var positions := [GameState.myId] + GameState.otherPlayerNames.keys()
	positions.sort()

	var player := PlayerNode.instance()
	player.connect('lay_bomb', self, '_on_Player_lay_bomb')
	player.connect('dead', self, '_on_Player_dead')
	player.connect('damaged', self, '_on_Player_damaged')
	player.connect('collect_item', self, '_on_Player_collect_item')
	player.name = str(GameState.myId)
	player.playerId = GameState.myId
	player.playerName = GameState.myName
	player.playerColor = GameState.myColor
	player.global_position = _playerPositions[positions.find(GameState.myId)]
	player.set_network_master(GameState.myId)
	_playersContainer.add_child(player)
	
	_allPlayers.append(GameState.myId)
	
	for id in GameState.otherPlayerNames:
		player = PlayerNode.instance()
		player.name = str(id)
		player.playerId = id
		player.playerName = str(GameState.otherPlayerNames[id])
		player.playerColor = GameState.otherPlayerColors[id]
		player.global_position = _playerPositions[positions.find(id)]
		player.set_network_master(id)
		_playersContainer.add_child(player)
		
		_allPlayers.append(id)


func _onGameLoaded() -> void:
	OS.window_maximized = true
	GameState.disconnect('game_loaded', self, '_onGameLoaded')
	
	var waitTime := GameConfig.WALL_TILE_ID
	_resultPopup.showPopup('Get ready!\n%s second(s) later to go!' % waitTime, 'Ready', true, _resultPopup.BUTTON_STAY_BIT + _resultPopup.BUTTON_BACK_BIT)
	
	yield(self.get_tree().create_timer(waitTime), 'timeout')
	self.get_tree().paused = false
	_resultPopup.hidePopup()


func _onGameEnded(why : String) -> void:
	self.set_process_unhandled_input(false)
	self.set_process_input(false)
	self.get_tree().paused = true
	_resultPopup.showPopup('Game is ended for:\n%s' % why, 'GAME OVER', true, 1)


func _onPlayerQuit(id : int) -> void:
	if id in _allPlayers:
		_allPlayers.erase(id)
		GameConfig.sendMessage(GameConfig.MessageType.System, id, 'quit the game!')
		_resultPopup.showPopup('Some player(s) quit, continue?', 'WARNING')
	
	var containers := [_playersContainer, _bombContainer]
	for node in containers:
		for child in node.get_children():
			if child.get_network_master() == id:
				child.queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed('quit'):
		_resultPopup.showPopup('Quit Game?', 'WARNING')


func _on_Player_damaged(byKiller : int) -> void:
	if byKiller <= 0:
		return
	
	if GameState.myId == byKiller:
		GameConfig.sendMessage(GameConfig.MessageType.Information, GameState.myId, 'damaged by youself?!')
		GameConfig.rpc('sendMessage', GameConfig.MessageType.Information, GameState.myId, 'damaged by himself!!!')
	else:
		var msg = 'damaged by other killer: %s.' % GameState.otherPlayerNames[byKiller]
		GameConfig.sendMessage(GameConfig.MessageType.Information, GameState.myId, msg)
		GameConfig.rpc('sendMessage', GameConfig.MessageType.Information, GameState.myId, msg)


func _on_Player_collect_item(item : GameConfig.ItemData) -> void:
	var type := 'Unknown'
	match item.type:
		GameConfig.ItemType.ActorEffect:
			type = 'Player'
		GameConfig.ItemType.BombEffect:
			type = 'Bomb'
		_:
			type = 'Empty'
	var msg := 'collects a %s item (%s Addon).' % [item.name, type]
	GameConfig.sendMessage(GameConfig.MessageType.Information, GameState.myId, msg)
	GameConfig.rpc('sendMessage', GameConfig.MessageType.Information, GameState.myId, msg)


func _on_Player_dead(byKiller : int) -> void:
	var killer := 'Monsters!'
	if byKiller > 0:
		if GameState.myId == byKiller:
			killer = 'yourself?!'
			GameConfig.sendMessage(GameConfig.MessageType.Information, GameState.myId, 'are killed by yourself, and lost the game.')
			GameConfig.rpc('sendMessage', GameConfig.MessageType.Information, GameState.myId, 'is killed by himself, and lost the game.')
		else:
			killer = GameState.otherPlayerNames[byKiller] + '.'
			GameConfig.sendMessage(GameConfig.MessageType.Information, GameState.myId, 'are killed by %s, and lost the game.' % GameState.otherPlayerNames[byKiller])
			GameConfig.rpc('sendMessage', GameConfig.MessageType.Information, GameState.myId, 'is killed by %s, and lost the game.' % GameState.otherPlayerNames[byKiller])
	else:
		GameConfig.sendMessage(GameConfig.MessageType.Information, GameState.myId, 'are killed by the enemies, and lost the game.')
		GameConfig.rpc('sendMessage', GameConfig.MessageType.Information, GameState.myId, 'is killed by the crazy enemies, and lost the game.')
	
	self.rpc('_playerDead')
	_resultPopup.showPopup('You lost!\nThe killer: %s' % killer, 'Game Over', true)


remote func _playerDead() -> void:
	var id := self.get_tree().get_rpc_sender_id()
	_allPlayers.erase(id)
	if GameState.myId in _allPlayers && _allPlayers.size() == 1:
		GameConfig.sendMessage(GameConfig.MessageType.System, GameState.myId, 'win the game at last!')
		_resultPopup.showPopup('You win the game!\nCongratulations!', 'Congratulations', true)
		self.rpc('_showWinner', GameState.myName)
		_showWinnerEffect()
	
	GameConfig.sendMessage(GameConfig.MessageType.System, id, 'lost the game...')


func _showWinnerEffect() -> void:
	$CPUParticles2D.emitting = true
	if GameConfig.isSoundOn:
		_audioPlayer.stream = load('res://World/Assets/Winner.wav')
		_audioPlayer.play()


remote func _showWinner(playerName : String) -> void:
	_resultPopup.showPopup('%s win the game!\nCongratulations!' % playerName, 'Game Over', true)


func _on_Player_lay_bomb(ownerId : int, pos : Vector2, power : int, itemIndex : int) -> void:
	if bombScene == null:
		return
	
	var tile := _tileMap.world_to_map(pos)
	if ! _tileMap.removeBrokenTile(tile): # 1 ------- this tile layed a bomb
		return
	
	_bombNameIndex += 1
	pos = _tileMap.map_to_world(tile) + _tileMap.cell_size / 2
	var name = 'Bomb' + str(GameState.myId) + str(_bombNameIndex)
	self.rpc('_layBomb', GameState.myId, pos, ownerId, tile, power, itemIndex, name)


remotesync func _layBomb(id : int, position : Vector2, ownerId : int, tile : Vector2, power : int, itemIndex : int, name : String) -> void:
	var item : GameConfig.ItemData = null
	if itemIndex >= 0: # index = -1 is valid in Python and GDScript!!!
		item = GameConfig.items[itemIndex]
	
	var bomb = bombScene.instance()
	bomb.name = name
	bomb.damage += _bombExtraDamage
	bomb.set_network_master(id)
	bomb.setup(ownerId, tile, power, item)
	bomb.position = _tileMap.map_to_world(tile) + _tileMap.cell_size / 2
	bomb.connect('explosion', self, '_on_bomb_explosion')
	_bombContainer.add_child(bomb)


func _on_bomb_explosion(owerId : int, pos : Vector2, power : int, damage : int) -> void:
	_tileMap.addBrokenTile(pos)           # 2 ------- this tile with bomb is exploded
	_explodeAndGoOn(owerId, pos, damage)
	for dir in [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]:
		var count := power
		while count > 0:
			count -= 1
			var frame : int = GameConfig.EXPLOSION_CENTER if count != 0 else GameConfig.EXPLOSION_END
			var mapPos : Vector2 = pos + dir * (power - count)
			if ! _explodeAndGoOn(owerId, mapPos, damage, dir, frame):
				break


func _explodeAndGoOn(owerId : int, mapPos : Vector2, damage : int, direction : Vector2 = Vector2.ZERO, tileFrame : int = GameConfig.EXPLOSION_START) -> bool:
	if explosionScene == null:
		return false
	
	var id = _tileMap.get_cellv(mapPos)
	match id:
		GameConfig.WALL_TILE_ID:
			return false
		GameConfig.BRICK_TILE_ID:
			self.rpc('_tileMapChangeTileAt', mapPos, GameConfig.GRASS_TILE_ID)
			_tileMap.addBrokenTile(mapPos) # add broken tile in explosion
		_:
			assert(id == GameConfig.GRASS_TILE_ID, 'Other tile not named Grass!')
	
	_explosionNameIndex += 1
	var pos := _tileMap.map_to_world(mapPos) + _tileMap.cell_size / 2
	var isDisabled : bool = id == GameConfig.BRICK_TILE_ID
	var name := 'Explosion' + str(GameState.myId) + str(_explosionNameIndex)
	self.rpc('_addExplosion', GameState.myId, pos, owerId, direction, tileFrame, damage, isDisabled, name)
	
	return id == GameConfig.GRASS_TILE_ID


remotesync func _tileMapChangeTileAt(mapPos : Vector2, tileId : int) -> void:
	_tileMap.set_cellv(mapPos, tileId)


remotesync func _addExplosion(id : int, pos : Vector2, owerId : int, direction : Vector2, tileFrame : int, damage : int, isDisabled : bool, name : String) -> void:
	var explosion := explosionScene.instance() as Explosion
	explosion.name = name
	explosion.set_network_master(id)
	explosion.setup(owerId, direction, tileFrame, damage, isDisabled)
	explosion.position = pos
	_bombContainer.add_child(explosion)


func _spawnEnemies() -> void:
	if ! self.get_tree().is_network_server():  # Not master, only server spawns enemies.
		return
	
	if enemyScene == null:
		return
	
	var count := _enemiesContainer.get_child_count() # contains items!!! But they will disappear.
	if count <= maxEnemyCount:
		_spawnEnemy()


func _spawnEnemy() -> void:
	var tile : Vector2 = _tileMap.getRandomTile()
	if tile == Vector2(-1, -1):
		return
	
	_enemyNameIndex += 1
	var pos := _tileMap.map_to_world(tile) + _tileMap.cell_size / 2
	var name := 'Enemy' + str(_enemyNameIndex)
	self.rpc('_addEnemy', pos, name)


remotesync func _addEnemy(pos : Vector2, name : String) -> void:
	var enemy = enemyScene.instance()
	enemy.name = name
	enemy.set_network_master(1)
	enemy.global_position = pos
	_enemiesContainer.add_child(enemy)


func _on_SpawnFrequencyTimer_timeout() -> void:
	_spawnTimer.wait_time -= 0.5
	if _spawnTimer.wait_time <= 0.5:
		_frequencyTimer.queue_free()


func _on_EnemySpawnTimer_timeout() -> void:
	_spawnEnemies()
