extends Node

signal player_list_update(players, colors)
signal player_color_update(id, color)
signal player_ready_status_update(id, isReady)
signal player_disconnected(id)
signal connection_succeeded()
signal game_ended(why)
signal game_ready(isReady)
signal game_loaded()


const PORT := 34567
const MAX_PLAYERS := 4
const GAME_SCENE := 'res://World/Game.tscn'
const COLORS := [Color('#B0BEC5'), Color('#8D6E63'), Color('#FFAB91'), Color('#FFE082'), Color('#D4E157'), 
					Color('#AED581'), Color('#72D572'), Color('#4DB6AC'), Color('#29B6F6'), Color('#91A7FF'), 
					Color('#7E57C2'), Color('#9C27B0'), Color('#F06292'), Color('#FFFFFF'), Color('#FEF3C0')]

var myId := -1
var myName := ''
var myColor := Color.white
var otherPlayerNames := {}   # id-name
var otherPlayerColors := {}  # id-color
var isGameStarted := false

master var readyPlayers := []
master var availableColors := []


func _ready() -> void:
	self.get_tree().connect('network_peer_connected', self, '_onNewPlayerConnected')
	self.get_tree().connect('network_peer_disconnected', self, '_onPlayerDisconnected')
	self.get_tree().connect('server_disconnected', self, '_onServerDisconnected')
	self.get_tree().connect('connected_to_server', self, '_onConnectionSuccess')
	self.get_tree().connect('connection_failed', self, '_onConnectionFail')


# 每当新客户端链接，所有其他id都会调用该方法
func _onNewPlayerConnected(id : int) -> void:
	if isGameStarted:
		return

	var s = self.rpc_id(id, '_addMyNameToList', myName, myColor)
	
	# 服务端处理游戏准备事件、分配颜色
	if self.get_tree().is_network_server():
		self.emit_signal('game_ready', false)
		
		var color := _getRandomColor()
		self.rpc('_updateColor', id, color)


# 每当新客户端断开链接，所有其他id都会调用该方法，删除该id信息
func _onPlayerDisconnected(id : int) -> void:
	if isGameStarted:
		self.emit_signal('player_disconnected', id)
	else:
		_removeDisconnectedPlayer(id)


# 客服端链接成功，仅客户端调用
func _onConnectionSuccess() -> void:
	self.emit_signal('connection_succeeded')


# 服务器断开，仅客户端调用
func _onServerDisconnected() -> void:
	self.emit_signal('game_ended', 'Server disconnected.')


# 客服端链接失败，仅客户端调用
func _onConnectionFail() -> void:
	self.emit_signal('game_ended', 'Connection failed.')


func _getRandomColor() -> Color:
	var index := randi() % availableColors.size()
	var color = availableColors[index]
	availableColors.remove(index)
	return color


remote func _addMyNameToList(playerName : String, playerColor : Color) -> void:
	var id = self.get_tree().get_rpc_sender_id()
	otherPlayerNames[id] = playerName
	if ! otherPlayerColors.has(id):
		otherPlayerColors[id] = playerColor
	self.emit_signal('player_list_update', otherPlayerNames, otherPlayerColors)


remotesync func _updateColor(id : int, color : Color) -> void:
	if id == myId:
		myColor = color
	else:
		otherPlayerColors[id] = color
	
	self.emit_signal('player_color_update', id, color)


func _removeDisconnectedPlayer(id : int) -> void:
	var color = otherPlayerColors[id]
	otherPlayerNames.erase(id)
	otherPlayerColors.erase(id)
	self.emit_signal('player_list_update', otherPlayerNames, otherPlayerColors)

	if self.get_tree().is_network_server():
		availableColors.append(color) # color recycle
		readyPlayers.erase(id)
		self.emit_signal('game_ready', readyPlayers.empty())


remote func _readyGame(isReady : bool) -> void:
	var id := self.get_tree().get_rpc_sender_id()
	self.emit_signal('player_ready_status_update', id, isReady)
	if self.get_tree().is_network_server():
		if isReady:
			assert(! id in readyPlayers, 'Player %s is already in ready players!' % id)
			readyPlayers.append(id)
			self.emit_signal('game_ready', readyPlayers.size() == otherPlayerNames.size())
		else:
			readyPlayers.erase(id)
			self.emit_signal('game_ready', false)


# 开始游戏第一步：实例化游戏场景，并且暂停，通知服务器等待其他玩家
remotesync func _prestartGame() -> void:
	isGameStarted = true
	
	var game : Node2D = load(GAME_SCENE).instance()
	game.name = 'Game'
	game.set_network_master(1)
	self.get_parent().add_child(game)
	self.get_tree().paused = true
	
	if self.get_tree().is_network_server():
		_postStartGame(myId)
	else:
		self.rpc_id(1, '_postStartGame', myId)


# 开始游戏第二步：等待所有玩家全部加载、实例化游戏场景
remote func _postStartGame(id : int) -> void:
	readyPlayers.append(id)
	if readyPlayers.size() == otherPlayerNames.size() + 1:
		self.rpc('_startGame')


# 开始游戏第三步：全部进入游戏，开始
remotesync func _startGame() -> void:
	readyPlayers.clear()
	self.emit_signal('game_loaded')


# 创建服务器
func hostGame(playerName: String) -> bool:
	myName = playerName
	otherPlayerNames.clear()
	otherPlayerColors.clear()
	availableColors = COLORS.duplicate()
	readyPlayers.clear()
	
	var host := NetworkedMultiplayerENet.new()
	var error := host.create_server(PORT, MAX_PLAYERS)
	if error != OK:
		return false
	
	self.get_tree().network_peer = host
	self.get_tree().refuse_new_network_connections = true
	
	myId = self.get_tree().get_network_unique_id() # id = 1 is the server
	myColor = _getRandomColor()
	return true


# 创建客户端，加入游戏
func joinGame(address: String, playerName: String) -> bool:
	myName = playerName
	otherPlayerNames.clear()
	otherPlayerColors.clear()
	readyPlayers.clear()
	
	var host := NetworkedMultiplayerENet.new()
	var error := host.create_client(address, PORT)
	if error != OK:
		return false
	
	self.get_tree().network_peer = host
	
	myId = self.get_tree().get_network_unique_id()
	return true


func resetNetwork() -> void:
	isGameStarted = false
	otherPlayerNames.clear()
	otherPlayerColors.clear()
	
	yield(self.get_tree(), 'idle_frame')
	self.get_tree().network_peer = null


# 服务器端调用，开始游戏
func startGame() -> void:
	assert(myId == 1, 'Only server can start game!')
	
	self.get_tree().refuse_new_network_connections = true
	readyPlayers.clear()
	self.rpc('_prestartGame')


# 客户端调用，准备状态
func readyGame(isReady : bool) -> void:
	assert(myId != 1, 'Server cannot send info to server-self!')
	
	self.rpc('_readyGame', isReady)

