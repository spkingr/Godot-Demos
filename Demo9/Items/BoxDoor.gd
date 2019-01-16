extends Area2D

onready var _audioPlayer = $AudioStreamPlayer


func _on_BoxDoor_body_entered(body):
	if body.is_in_group('player') && body.has_method('openDoor'):
		body.openDoor()
		_audioPlayer.play()
