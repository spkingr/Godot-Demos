extends Control
class_name ResultPopup


onready var _backgound := $Backgroud as ColorRect
onready var _dialog := $PopupDialog as PopupDialog
onready var _labelMessage := $PopupDialog/MarginContainer/VBoxContainer/CenterContainer/LabelInfo as Label
onready var _labelTitle := $PopupDialog/MarginContainer/VBoxContainer/LabelTitle as Label


func _input(event: InputEvent) -> void:
	if _dialog.visible && event.is_action_pressed('text_enter'):
		self.get_tree().set_input_as_handled()


func _on_ButtonStay_pressed() -> void:
	_dialog.hide()


func _on_ButtonBack_pressed() -> void:
	GameConfig.backToMainScene()


func _on_Button_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed('ui_select'):
		self.get_tree().set_input_as_handled()


func showPopup(msg : String, title : String = 'Message', exlusive : bool = false) -> void:
	_labelMessage.text = msg
	_labelTitle.text = title
	_dialog.popup()
	_dialog.popup_exclusive = exlusive
