extends Control
class_name ResultPopup


const BUTTON_STAY_BIT := 0b01
const BUTTON_BACK_BIT := 0b10

onready var _dialog := $PopupDialog as PopupDialog
onready var _labelMessage := $PopupDialog/MarginContainer/VBoxContainer/CenterContainer/LabelInfo as Label
onready var _labelTitle := $PopupDialog/MarginContainer/VBoxContainer/LabelTitle as Label
onready var _buttonStay := $PopupDialog/MarginContainer/VBoxContainer/HBoxContainer/ButtonStay
onready var _buttonBack := $PopupDialog/MarginContainer/VBoxContainer/HBoxContainer/ButtonBack


func _input(event: InputEvent) -> void:
	if _dialog.visible && event.is_action_pressed('text_enter'):
		self.get_tree().set_input_as_handled()


func _on_ButtonStay_pressed() -> void:
	if self.get_tree().paused:
		self.get_tree().paused = false
	_dialog.hide()


func _on_ButtonBack_pressed() -> void:
	if self.get_tree().paused:
		self.get_tree().paused = false
	GameConfig.backToMainScene()


func _on_Button_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed('ui_select'):
		self.get_tree().set_input_as_handled()


func showPopup(msg : String, title : String = 'Message', exlusive : bool = false, hidedButtonBits : int = 0) -> void:
	_labelMessage.text = msg
	_labelTitle.text = title
	_dialog.popup_exclusive = exlusive
	_buttonStay.visible = (hidedButtonBits & BUTTON_STAY_BIT) == 0
	_buttonBack.visible = (hidedButtonBits & BUTTON_BACK_BIT) == 0
	prints((hidedButtonBits & BUTTON_STAY_BIT), (hidedButtonBits & BUTTON_BACK_BIT))
	_dialog.popup()


func hidePopup() -> void:
	_dialog.hide()

