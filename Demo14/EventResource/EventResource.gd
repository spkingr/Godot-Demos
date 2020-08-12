extends Resource
class_name EventResource, 'res://EventResource/event_icon.svg'

signal custom_event(type, message)


export var type := 'defaultEvent'


func emitSignal(object) -> void:
	self.emit_signal('custom_event', type, object)
