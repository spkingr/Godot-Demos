extends Navigation2D


const PlayerNode : PackedScene = preload('res://Player/Player.tscn')

export var bombScene : PackedScene = null
export var explosionScene : PackedScene = null
export var enemyScene : PackedScene = null
export var maxEnemyCount : int = 10 # debug

onready var _tileMap : TileMap = $WorldMap
onready var _tileSet : TileSet = $WorldMap.tile_set
onready var _bombContainer : Node2D = $BombContainer
onready var _enemiesContainer : Node2D = $Enemies
onready var _playerPositions := [$Players/Position1.position, $Players/Position2.position, $Players/Position3.position, $Players/Position4.position]
onready var _resultPopup := $CanvasLayer/HUD/ResultPopup as ResultPopup
onready var _infoPanel := $CanvasLayer/HUD/InfoPanelUI as InfoPanel


func _ready() -> void:
#	OS.window_maximized = true

	var i := 0
	var player := PlayerNode.instance()
	player.connect('lay_bomb', self, '_on_Player_lay_bomb')
	player.connect('dead', self, '_on_Player_dead')
	player.connect('damaged', self, '_on_Player_damaged')
	player.connect('collect_item', self, '_on_Player_collect_item')
	player.name = str(GameState.myId)
	player.playerName = GameState.myName
	player.global_position = _playerPositions[i]
	player.set_network_master(GameState.myId)
	self.add_child(player)
	
	for id in GameState.otherPlayerNames:
		i += 1
		player = PlayerNode.instance()
#		player.connect('lay_bomb', self, '_on_Player_lay_bomb') # ????? need? no need?
#		player.connect('dead', self, '_on_Player_dead')
		player.name = str(id)
		player.playerName = str(GameState.otherPlayerNames[id])
		player.global_position = _playerPositions[i]
		player.set_network_master(id)
		self.add_child(player)
	
	GameConfig.sendMessage(GameConfig.MessageType.System, GameState.myId, 'enters the game!')


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed('quit'):
		if GameState.isGameStarted:
			_resultPopup.showPopup('Quit Game?', 'WARNING')
		else:
			self.get_tree().quit()


func _on_Player_damaged(byKiller : int) -> void:
	if byKiller > 0:
		var msg := 'damaged by other killer: %s.' % 'Test' if byKiller != GameState.myId else 'damaged by self?!'
		GameConfig.sendMessage(GameConfig.MessageType.Information, GameState.myId, msg)


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


func _on_Player_dead(byKiller : int) -> void:
	_resultPopup.showPopup('You lost!\nThe killer: %s' % byKiller, 'Game Over', true)
	
	if byKiller > 0:
		var msg := '%s is killed by %s, and lost the game.' % [GameState.myName, byKiller]
		GameConfig.sendMessage(GameConfig.MessageType.Information, GameState.myId, msg)


func _on_Player_lay_bomb(ownerId, pos, power, item) -> void:
	if bombScene == null:
		return
	
	var tile = _tileMap.world_to_map(pos)
	if ! _tileMap.removeBrokenTile(tile): # 1 ------- this tile layed a bomb
		return
	
	var bomb = bombScene.instance()
	bomb.setup(ownerId, tile, power)
	bomb.position = _tileMap.map_to_world(tile) + _tileMap.cell_size / 2
	bomb.connect('explosion', self, '_on_bomb_explosion')
	
	_bombContainer.add_child(bomb)
	if item && item.data:
		var effect : Node = load(item.data).instance()
		bomb.add_child(effect)


func _on_bomb_explosion(owerId : int, pos : Vector2, power : int, damage : int) -> void:
	_tileMap.addBrokenTile(pos)           # 2 ------- this tile with bomb is exploded
	_explodeAndGoOn(owerId, pos, damage)
	for dir in [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]:
		var count := power
		while count > 0:
			count -= 1
			var frame := GameConfig.EXPLOSION_CENTER if count != 0 else GameConfig.EXPLOSION_END
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
			_tileMap.set_cellv(mapPos, GameConfig.GRASS_TILE_ID)
			_tileMap.addBrokenTile(mapPos) # add broken tile in explosion
		_:
			assert(id == GameConfig.GRASS_TILE_ID, 'Other tile not named Grass!')
	
	var explosion := explosionScene.instance() as Explosion
	explosion.setup(owerId, direction, tileFrame, damage)
	explosion.position = _tileMap.map_to_world(mapPos) + _tileMap.cell_size / 2
	_bombContainer.add_child(explosion)
	
	return id != GameConfig.BRICK_TILE_ID


func _spawnEnemies() -> void:
	if enemyScene == null:
		return
	
	var count := _enemiesContainer.get_child_count() # contains items --TO-DO
	if count <= maxEnemyCount:
		_spawnEnemy()
		if randf() > 0.8: # probabilities for another enemy spawn
			_spawnEnemy()


func _spawnEnemy() -> void:
	var tile : Vector2 = _tileMap.getRandomTile()
	if tile == Vector2(-1, -1):
		return
	
	var enemy = enemyScene.instance()
	_enemiesContainer.add_child(enemy)
	enemy.global_position = _tileMap.map_to_world(tile) + _tileMap.cell_size / 2


func _on_EnemySpawnTimer_timeout() -> void:
	_spawnEnemies()
