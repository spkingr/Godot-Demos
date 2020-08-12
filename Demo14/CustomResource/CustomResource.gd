extends Resource
class_name CustomResource, 'res://CustomResource/custom_icon.svg'


export var variable1 := ''
export var variable2 := 0
export var variable3 := Vector2.ZERO
export var variable4 := []

func printInfo() -> void:
	var s := '['
	for v in variable4:
		s += str(v) + ', '
	s += ']'
	print('variable1=%s, variable2=%s, variable3=%s, variable4=%s' % [variable1, variable2, variable3, s])
	
