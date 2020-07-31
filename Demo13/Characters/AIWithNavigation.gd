"""
继承自 AIBase 基类，
用于导航地图中，根据导航寻找目标路径
"""
extends "res://Characters/AIBase.gd"


export var navigationNodePath := @''

var _navigation : Navigation2D = null
var _path : PoolVector2Array


func _ready() -> void:
	if ! navigationNodePath.is_empty():
		_navigation = self.get_node(navigationNodePath)


# 查找可行的移动方向，父类方法
func _findMoveDirection(delta : float, target : Node2D) -> Vector2:
	var dir := Vector2.ZERO
	if _navigation == null:
		return dir
	
	# 使用导航的方法找出可行路径
	var path := _navigation.get_simple_path(self.position, target.position)
	_path = path
	# 注意：第一个点可能是AI自身所在点，这时候会返回 Vector2.ZERO 导致不移动
	while dir == Vector2.ZERO && ! path.empty():
		dir = (path[0] - self.position).normalized()
		path.remove(0)
	return dir


# 画出导航路径点
func _getPathPoints() -> Array:
	return Array(_path)


# 丢失跟踪目标时调用该方法
func _onLostTarget() -> void:
	_path = PoolVector2Array([])


# 画射线，父类方法，这里将导航路径画出来
func _getRayPoints() -> Array:
	var lines := []
	for i in range(1, _path.size()):
		var start := self.to_local(_path[i - 1])
		var end := self.to_local(_path[i])
		lines.append({'start': start, 'end': end, 'enabled': true, 'collided': false})
	return lines

