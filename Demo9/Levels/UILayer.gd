extends CanvasLayer


onready var _healthHearts = [$HBoxContainer/TextureRect1, 
							$HBoxContainer/TextureRect2, 
							$HBoxContainer/TextureRect3]


func showHealth(health: int):
	for i in range(_healthHearts.size()):
		_healthHearts[i].self_modulate = Color(1, 1, 1, 1) if i < health else Color(0, 0, 0, 0.5)
