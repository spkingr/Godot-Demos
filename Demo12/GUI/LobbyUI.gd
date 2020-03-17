extends Control


onready var _panelTitle := $TitleScreen as Control
onready var _buttonHost := $TitleScreen/VBoxContainer/HBoxContainer2/ButtonHost as Button
onready var _buttonJoin := $TitleScreen/VBoxContainer/HBoxContainer2/ButtonJoin as Button
onready var _textName := $TitleScreen/VBoxContainer/HBoxContainer1/VBoxContainer2/TextName as LineEdit
onready var _textIp := $TitleScreen/VBoxContainer/HBoxContainer1/VBoxContainer2/TextIP as LineEdit

onready var _panelStart := $StartScreen as Control
onready var _buttonStart := $StartScreen/VBoxContainer/HBoxContainer/ButtonStart as Button
onready var _buttonCancel := $StartScreen/VBoxContainer/HBoxContainer/ButtonCancel as Button
onready var _listPlayerNames := $StartScreen/VBoxContainer/ListPlayerNames as ItemList

onready var _labelError := $TextError as Label
onready var _tween := $Tween as Tween

var _playerName := ""


func _ready() -> void:
	_panelTitle.show()
	_panelStart.hide()
	_labelError.hide()
	GameState.connect('connection_succeeded', self, '_gotoWaitingPlayers')
	GameState.connect('player_list_update', self, '_updatePlayerList')


func _updatePlayerList(otherPlayerNames : Dictionary) -> void:
	_listPlayerNames.clear()
	_listPlayerNames.add_item(str(GameState.myId))
	_listPlayerNames.add_item(GameState.myName)
	for id in otherPlayerNames.keys():
		var name = otherPlayerNames[id]
		_listPlayerNames.add_item(str(id))
		_listPlayerNames.add_item(name)


func _gotoWaitingPlayers() -> void:
	_buttonStart.disabled = ! self.is_network_master()
	_panelTitle.hide()
	_panelStart.show()


func _on_ButtonHost_pressed() -> void:
	GameState.hostGame(_playerName)
	_gotoWaitingPlayers()
	_listPlayerNames.add_item(str(GameState.myId))
	_listPlayerNames.add_item(GameState.myName)


func _on_ButtonJoin_pressed() -> void:
	var ip = _textIp.text
	if ip.is_valid_ip_address():
		_labelError.text = ''
		GameState.joinGame(ip, _playerName)
	else:
		_labelError.text = 'IP address is invalid!'


func _on_TextName_text_changed(new_text: String) -> void:
	_playerName = new_text
	_labelError.text = 'You mast have a name!' if new_text.empty() else ''
	
	if new_text.empty():
		_buttonHost.disabled = true
		_buttonJoin.disabled = true
	else:
		_buttonHost.disabled = false
		if ! _textIp.text.empty():
			_buttonJoin.disabled = false


func _on_TextIP_text_changed(new_text: String) -> void:
	if new_text.empty():
		_buttonJoin.disabled = true
	elif ! _textName.text.empty():
		_buttonJoin.disabled = false


func _on_ButtonStart_pressed() -> void:
	GameState.rpc('startGame')


func _on_ButtonCancel_pressed() -> void:
	pass # Replace with function body.
