extends Node2D


var path := [] setget __setPath__


func _ready() -> void:
	print('Debug with path')


func __setPath__(value : Array) -> void:
	path.clear()
	for i in value:
		path.append(i)
	self.update()


func _draw() -> void:
	if path:
		var i = 0
		for p in path:
			i += 1
			var color = Color.white
			if i == 1:
				color = Color.green
			if i == path.size():
				color = Color.red
			self.draw_circle(p, 4, color)
