extends Node

signal player_list_update(players)
signal connection_succeeded()
signal game_ended()


const PORT := 34567
const MAX_CLIENTS := 3

var myId := 0
var myName := 'test'
var myColor := Color.white
var otherPlayerNames : Dictionary = {}  # id-name
var isGameStarted := true # test


func _ready():
	self.get_tree().connect('network_peer_connected', self, '_onNewPlayerConnected')
	self.get_tree().connect('network_peer_disconnected', self, '_onPlayerDisconnected')
	self.get_tree().connect('server_disconnected', self, '_onServerDisconnected')
	self.get_tree().connect('connected_to_server', self, '_onConnectionSuccess')
	self.get_tree().connect('connection_failed', self, '_onConnectionFail')


# 每当新客户端链接，所有其他id都会调用该方法
func _onNewPlayerConnected(id : int) -> void:
	print('New network peer connected: ', id)
	self.rpc_id(id, '_addMyNameToList', myName)


func _onConnectionSuccess() -> void:
	self.emit_signal('connection_succeeded')


func _onPlayerDisconnected(id : int) -> void:
	if isGameStarted:
		_stopGame()
	else:
		_removeDisconnectedPlayer(id)


func _onServerDisconnected() -> void:
	pass


func _onConnectionFail() -> void:
	pass


func _removeDisconnectedPlayer(id : int) -> void:
	otherPlayerNames.erase(id)
	self.emit_signal('player_list_update', otherPlayerNames)


remote func _addMyNameToList(playerName : String) -> void:
	var id = self.get_tree().get_rpc_sender_id()
	
	# assert(id_param == get_tree().get_rpc_sender_id())
	
	otherPlayerNames[id] = playerName
	self.emit_signal('player_list_update', otherPlayerNames)


func _stopGame() -> void:
	otherPlayerNames.clear()
	self.get_tree().network_peer = null
	self.emit_signal('game_ended')


func hostGame(playerName: String) -> void:
	myName = playerName
	var host := NetworkedMultiplayerENet.new()
	host.create_server(PORT, MAX_CLIENTS)
	self.get_tree().network_peer = host
	
	myId = self.get_tree().get_network_unique_id() # id = 1 is the server


func joinGame(address: String, playerName: String) -> void:
	myName = playerName
	var host := NetworkedMultiplayerENet.new()
	host.create_client(address, PORT)
	self.get_tree().network_peer = host
	
	myId = self.get_tree().get_network_unique_id()


sync func startGame() -> void:
	self.get_tree().change_scene('res://World/World.tscn')
	self.isGameStarted = true
