extends Control


export var messageEvent : Resource = null
export var triggerEvent : Resource = null


func _ready() -> void:
	if messageEvent && messageEvent is EventResource:
		messageEvent.connect('custom_event', self, '_onCustomEventHandler')
	if triggerEvent && triggerEvent is EventResource:
		triggerEvent.connect('custom_event', self, '_onTriggerEventHandler')


func _onCustomEventHandler(type : String, info : String) -> void:
	assert(type == 'messageEvent', 'Only receive message events.')
	_updateText(info)


func _onTriggerEventHandler(type : String, name : String) -> void:
	assert(type == 'triggerEvent', 'Only receive trigger events.')
	var text := '[color=lime]%s triggers the event![/color]' % name
	_updateText(text)


func _updateText(text : String) -> void:
	$RichTextLabel.newline()
	$RichTextLabel.append_bbcode(text)
	while $RichTextLabel.get_line_count() > 100:
		$RichTextLabel.remove_line(0)
	$RichTextLabel.scroll_to_line($RichTextLabel.get_line_count() - 1)

