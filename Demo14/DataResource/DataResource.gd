extends Resource
class_name DataResource, 'res://DataResource/data_icon.svg'


export var name := 'Player'
export(String, FILE, '*.png') var imageSrc = ''
export var moveSpeed := 0.0
export var turningSpeed := 0.0
export var minStopDistance := 0.0

