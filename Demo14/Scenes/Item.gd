extends Area2D


export var triggerEvent : Resource = null


func _ready() -> void:
	if triggerEvent && triggerEvent is EventResource:
		$Label.text = 'Has Trigger'
		$Label.add_color_override('font_color', Color.red)
	else:
		$Label.text = 'No Trigger'


func _on_Item_body_entered(body: Node) -> void:
	if triggerEvent && triggerEvent is EventResource:
		triggerEvent.emitSignal(body.name)

