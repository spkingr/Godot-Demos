extends Control


const ListPlayerItem := preload('res://GUI/ListPlayerItem.tscn')

onready var _panelTitle := $TitleScreen as Control
onready var _buttonHost := $TitleScreen/VBoxContainer/HBoxContainer2/ButtonHost as Button
onready var _buttonJoin := $TitleScreen/VBoxContainer/HBoxContainer2/ButtonJoin as Button
onready var _textName := $TitleScreen/VBoxContainer/HBoxContainer1/VBoxContainer2/TextName as LineEdit
onready var _textIp := $TitleScreen/VBoxContainer/HBoxContainer1/VBoxContainer2/TextIP as LineEdit

onready var _panelStart := $StartScreen as Control
onready var _buttonStart := $StartScreen/VBoxContainer/HBoxContainer/ButtonStart as Button
onready var _buttonCancel := $StartScreen/VBoxContainer/HBoxContainer/ButtonCancel as Button
onready var _listPlayerNames := $StartScreen/VBoxContainer/ScrollContainer/ListPlayerNames as VBoxContainer
onready var _playerTexture := $StartScreen/VBoxContainer/TextureRect as TextureRect
onready var _labelPlayerCount := $StartScreen/VBoxContainer/LabelPlayerCount as Label
onready var _buttonHelp := $StartScreen/ButtonContainer/CheckButtonHelp as CheckButton
onready var _buttonSound := $StartScreen/ButtonContainer/CheckButtonSound as CheckButton
onready var _textHelp := $StartScreen/TextContainer as Control

onready var _labelError := $TextError as Label
onready var _tween := $Tween as Tween

var _playerName := ''


func _ready() -> void:
	_playerName = GameState.myName
	if ! _playerName.empty():
		_textName.text = _playerName
		_buttonHost.disabled = _textIp.text.strip_edges().empty()
		_buttonJoin.disabled = _textIp.text.strip_edges().empty()
	
	_panelTitle.show()
	_panelStart.hide()
	_labelError.hide()
	_textHelp.visible = GameConfig.isManualShown
	
	GameState.connect('connection_succeeded', self, '_gotoWaitingPlayers')
	GameState.connect('player_list_update', self, '_updatePlayerList')
	GameState.connect('player_color_update', self, '_updatePlayerColor')
	GameState.connect('game_ended', self, '_stopGameAndBack')
	GameState.connect('game_ready', self, '_onGameReady')
	GameState.connect('game_loaded', self, 'queue_free')
	GameState.connect('player_ready_status_update', self, '_updatePlayerStatus')


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed('quit') && ! GameState.isGameStarted:
		self.get_tree().quit()


func _updatePlayerList(otherPlayerNames : Dictionary, otherPlayerColors : Dictionary) -> void:
	_clearListPlayerItems()
	_addPlayerItem(GameState.myId, GameState.myName, GameState.myColor)
	_labelPlayerCount.text = 'Players: %s/4' % (otherPlayerNames.size() + 1)
	for id in otherPlayerNames.keys():
		_addPlayerItem(id, otherPlayerNames[id], otherPlayerColors[id])


func _addPlayerItem(id : int, name : String, color : Color, isReady : bool = false) -> void:
	var item : PlayerItem = ListPlayerItem.instance()
	item.playerId = id
	item.playerColor = color
	item.playerName = name
	item.isSelf = id == GameState.myId
	item.isServer = id == 1
	item.canBeKicked = GameState.myId == 1 && id != 1
	item.isReady = isReady
	_listPlayerNames.add_child(item)
	_listPlayerNames.add_child(HSeparator.new())
	
	item.connect('on_kickout', self, '_onPlayerBeKickedOut')


func _onPlayerBeKickedOut(id : int) -> void:
	assert(self.get_tree().is_network_server(), 'Only server can kickout others!')
	
	self.rpc_id(id, '_kickedOut')


remote func _kickedOut() -> void:
	_cancelAndBack()
	GameState.resetNetwork()


func _updatePlayerColor(id : int, color : Color) -> void:
	if id == GameState.myId:
		_playerTexture.material.set_shader_param('tint_color', color)
	
	for item in _listPlayerNames.get_children():
		if item is PlayerItem && item.playerId == id:
			item.playerColor = color
			break


func _updatePlayerStatus(id : int, isReady : bool) -> void:
	for item in _listPlayerNames.get_children():
		if item is PlayerItem && item.playerId == id:
			item.isReady = isReady
			break


func _gotoWaitingPlayers() -> void:
	_clearListPlayerItems()
	if self.get_tree().is_network_server():
		_buttonStart.add_color_override('font_color', Color.green)
		_buttonStart.text = 'Start Game'
	else:
		_buttonStart.text = 'Ready'
	
	_panelTitle.hide()
	_panelStart.show()
	
	_playerTexture.material.set_shader_param('tint_color', GameState.myColor)


func _stopGameAndBack(msg : String) -> void:
	_panelStart.hide()
	_panelTitle.show()
	_showError('Game stopped: %s' % msg)


func _on_ButtonHost_pressed() -> void:
	_buttonStart.disabled = false # if you are server then quit and join others make sure your button is clickable
	
	_playerName = _playerName.strip_edges()
	if GameState.hostGame(_playerName):
		_gotoWaitingPlayers()
		_addPlayerItem(GameState.myId, GameState.myName, GameState.myColor)
		_showError('')
	else:
		_showError('Error create host, maybe change the IP and try it again.')


func _on_ButtonJoin_pressed() -> void:
	_buttonStart.disabled = false # if you are server then quit and join others make sure your button is clickable
	
	var ip = _textIp.text
	if ip.is_valid_ip_address():
		_playerName = _playerName.strip_edges()
		if ! GameState.joinGame(ip, _playerName):
			_showError('Failed to join host, maybe change the IP and try it again.')
			return
		_showError('')
	else:
		_showError('IP address is invalid.')


func _on_TextName_text_changed(new_text: String) -> void:
	_playerName = new_text
	_showError('You mast have a name!' if new_text.empty() else '')
	
	if new_text.strip_edges().empty():
		_buttonHost.disabled = true
		_buttonJoin.disabled = true
	else:
		_buttonHost.disabled = false
		if ! _textIp.text.strip_edges().empty():
			_buttonJoin.disabled = false


func _on_TextIP_text_changed(new_text: String) -> void:
	if new_text.strip_edges().empty():
		_buttonJoin.disabled = true
	elif ! _textName.text.strip_edges().empty():
		_buttonJoin.disabled = false


func _on_ButtonStart_pressed() -> void:
	match _buttonStart.text:
		'Ready':
			_buttonStart.text = 'Cancel Ready'
			_updatePlayerStatus(GameState.myId, true)
			GameState.readyGame(true)
		'Cancel Ready':
			_buttonStart.text = 'Ready'
			_updatePlayerStatus(GameState.myId, false)
			GameState.readyGame(false)
		'Start Game':
			GameState.startGame()


func _on_ButtonCancel_pressed() -> void:
	_cancelAndBack()
	GameState.resetNetwork()


func _cancelAndBack() -> void:
	_clearListPlayerItems()
	_panelStart.hide()
	_panelTitle.show()


func _on_CheckButtonHelp_toggled(button_pressed: bool) -> void:
	GameConfig.isManualShown = button_pressed
	_buttonHelp.text = 'Help is On' if button_pressed else 'Help is Off'
	_textHelp.visible = button_pressed


func _on_CheckButtonSound_toggled(button_pressed: bool) -> void:
	GameConfig.isSoundOn = button_pressed
	_buttonSound.text = 'Sound is On' if button_pressed else 'Sound is Off'


func _onGameReady(isReady : bool) -> void:
	_buttonStart.disabled = ! isReady


func _clearListPlayerItems() -> void:
	for child in _listPlayerNames.get_children():
		child.queue_free()


func _showError(error : String) -> void:
	_tween.stop_all()
	if error.empty():
		_labelError.hide()
		return
	
	_labelError.text = error
	_labelError.show()
	_tween.interpolate_property(_labelError, @'custom_colors/font_color', Color.white, Color(0.98, 0.4, 0.19), 2.0, Tween.TRANS_BOUNCE, Tween.EASE_OUT)
	_tween.interpolate_property(_labelError, @'rect_scale', Vector2(1.5, 1.5), Vector2(1, 1), 0.75, Tween.TRANS_BOUNCE, Tween.EASE_OUT)
	_tween.start()

