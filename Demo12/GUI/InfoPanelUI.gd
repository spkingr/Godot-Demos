extends Control
class_name InfoPanel


const MAX_LINE_COUNT := 100

onready var _labelInfo := $NinePatchRect/MarginContainer/VBoxContainer/LabelInfo as RichTextLabel
onready var _messageContainer := $NinePatchRect/MarginContainer/VBoxContainer/HBoxContainer as HBoxContainer
onready var _textMessage := $NinePatchRect/MarginContainer/VBoxContainer/HBoxContainer/TextMessage as LineEdit
onready var _tween := $Tween as Tween

var _isEntering := false


func _ready() -> void:
	_messageContainer.hide()
	_labelInfo.bbcode_text = '------Game Started------'
	GameConfig.connect('new_message', self, '_on_NewMessage_arrive')


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed('text_enter'):
		_onEntering()
	if event.is_action_pressed('quit') && _isEntering:
		_onEntering()
		self.get_tree().set_input_as_handled()


func _onEntering() -> void:
	_messageContainer.visible = ! _isEntering
	_isEntering = ! _isEntering
	if _isEntering:
		_textMessage.grab_focus()
	else:
		_sendMessage()
	
	GameConfig.emit_signal('text_enter', _isEntering)


func _on_ButtonSend_pressed(msg : String = '') -> void:
	_messageContainer.visible = false
	_isEntering = false
	_sendMessage()
	GameConfig.emit_signal('text_enter', _isEntering)


func _sendMessage() -> void:
	_labelInfo.grab_focus()
	var msg := _textMessage.text.strip_edges()
	_textMessage.clear()
	
	if ! msg.empty():
		GameConfig.sendMessage(GameConfig.MessageType.Chat, GameState.myId, msg)
		GameConfig.rpc('sendMessage', GameConfig.MessageType.Chat, GameState.myId, msg)


func _on_NewMessage_arrive(bbcodeMessage : String) -> void:
#	self.rpc('_remoteAppendMessage', bbcodeMessage)
	_remoteAppendMessage(bbcodeMessage)


remotesync func _remoteAppendMessage(msg : String) -> void:
	_labelInfo.newline()
	_labelInfo.append_bbcode(msg)
	
	yield(self.get_tree(), 'idle_frame')
	var lineCount := _labelInfo.get_line_count()
	while lineCount > MAX_LINE_COUNT:
		_labelInfo.remove_line(0)
		lineCount -= 1
	
	var final := lineCount - 1
	if lineCount <= 10:
		_labelInfo.scroll_to_line(final)
	else:
		var start := lineCount - 8
		var duration := 1.0
		_tween.interpolate_method(_labelInfo, 'scroll_to_line', start, final, duration, Tween.TRANS_CUBIC, Tween.EASE_OUT)
		_tween.start()

