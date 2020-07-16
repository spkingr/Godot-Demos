extends MarginContainer
class_name PlayerItem

signal on_kickout(id)


var playerId := 0
var playerName := '' setget __setPlayerName__
var playerColor := Color.white setget __playerColor__
var isServer := false setget __isServer__
var isSelf := true setget __isSelf__
var canBeKicked := false setget __canBeKicked__
var isReady := false setget __isReady__


func _on_ButtonKick_pressed() -> void:
	self.emit_signal('on_kickout', playerId)


func __setPlayerName__(value : String) -> void:
	playerName = value
	$HBoxContainer/LabelName.text = value


func __playerColor__(value : Color) -> void:
	playerColor = value
	$HBoxContainer/ColorRect.color = value


func __isSelf__(value : bool) -> void:
	isSelf = value


func __isServer__(value : bool) -> void:
	isServer = value
	if isServer && ! isSelf:
		$HBoxContainer/LabelName.text += ' (Server)'
	
	if isServer:
		$HBoxContainer/LabelReady.text = 'Is Ready'


func __canBeKicked__(value : bool) -> void:
	canBeKicked = value
	$HBoxContainer/ButtonKick.disabled = ! canBeKicked


func __isReady__(value : bool) -> void:
	isReady = value
	if isReady || isServer:
		$HBoxContainer/LabelReady.text = 'Is Ready'
	else:
		$HBoxContainer/LabelReady.text = 'Not Ready'

