extends Node2D


export var enableDebug := true

export var pathPointRadius := [4.0, 2.0, 2.0]
export var pathDefaultColor := Color.darkgray
export var pathStartColor := Color.green
export var pathEndColor := Color.white

export var rayLineSize := 2.0
export var rayLenMultiplier := 1.0
export var rayDefaultColor := Color.cyan
export var rayCollisionColor := Color.red
export var rayDisabledColor := Color.darkgray

var path := [] # Vector2
var rays := [] # {'start': Vector2, 'end': Vector2, 'enabled': bool, 'collided': bool}


func _process(delta: float) -> void:
	if enableDebug:
		self.update()
	else:
		path.clear()
		rays.clear()
		self.update()


func _draw() -> void:
	if ! path.empty():
		_drawPath(path)
	if ! rays.empty():
		_drawRays(rays)


func _drawPath(path : Array) -> void:
	var i := 0
	for p in path:
		var point : Vector2 = self.global_transform.xform_inv(p)
		var size := 4.0
		var color := pathDefaultColor
		if i == path.size() - 1:
			size = 4.0 if pathPointRadius.empty() else pathPointRadius[-1]
			color = pathStartColor
		elif i == 0:
			size = 4.0 if pathPointRadius.empty() else pathPointRadius[0]
			color = pathEndColor
		else:
			if pathPointRadius.size() > i + 1:
				size = pathPointRadius[i]
			elif pathPointRadius.size() >= 2:
				size = pathPointRadius[1]
			elif ! pathPointRadius.empty():
				size = pathPointRadius[0]
		i += 1
		self.draw_circle(point, size, color)


func _drawRays(rays : Array) -> void:
	var color := rayDefaultColor
	var size := rayLineSize
	for ray in rays:
		if ray is RayCast2D:
			var start = ray.position
			var end = start + ray.cast_to.rotated(ray.rotation) * rayLenMultiplier
			if ! ray.enabled:
				color = rayDisabledColor
			elif ray.is_colliding():
				color = rayCollisionColor
			self.draw_line(start, end, color, size)
		else:
			var start = ray['start']
			var end = start + (ray['end'] - start) * rayLenMultiplier
			if ! ray['enabled']:
				color = rayDisabledColor
			elif ray['collided']:
				color = rayCollisionColor
			self.draw_line(start, end, color, size)

