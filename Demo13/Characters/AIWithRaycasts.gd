"""
继承自 AIBase 基类，
使用射线进行路径寻找，粗糙地模仿了 Game Endeavor （@GameEndeavor[https://twitter.com/GameEndeavor]）的思路
原作者实现示意图：[https://gyazo.com/22f6b51c947ffaa4c81860155eefa9b3]
"""
extends "res://Characters/AIBase.gd"


# 射线类，检测玩家是否可以移动的射线，用于记录射线状态
# 属性：长度、方向、玩家是否可以移动、相对于玩家的比重、相对当前移动方向的比重
class Ray:
	var length := 0.0
	var dir := Vector2.ZERO
	var canMove := true
	var playerWeight := 0.0
	var moveonWeight := 0.0
	
	func _init(length : float, dir : Vector2) -> void:
		self.length = length
		self.dir = dir


export var raySize := 50     # 射线检测的长度
export var rayCount := 24    # 射线总数量（360度范围）

var _rays := []              # 所有的射线数组
var _currentRay : Ray = null # 当前移动方向射线


func _ready() -> void:
	var dir := Vector2.RIGHT
	for i in range(0, rayCount):
		var ray := Ray.new(raySize, dir.rotated(i * PI * 2 / rayCount))
		_rays.append(ray)
	_currentRay = _rays[0]


# 查找可行的移动方向，父类方法
func _findMoveDirection(delta : float, target : Node2D) -> Vector2:
	var vector := target.global_position - self.global_position
	var dir := vector.normalized()
	var length := vector.length()
	
	_updateRays(delta, vector, _currentRay.dir)
	_findRayDirection()
	
	return _currentRay.dir if _currentRay else Vector2.ZERO


# 更新射线碰撞状态、射线比重
func _updateRays(delta : float, targetDir : Vector2, moveDir : Vector2) -> void:
	var state := self.get_world_2d().direct_space_state
	for r in _rays:
		var ray : Ray = r
		# 使用 world space state 发射射线检测是否碰撞
		var collision := state.intersect_ray(self.global_position, self.global_position + ray.dir * ray.length, [], 0x1)
		if collision:
			ray.canMove = false
		else:
			# 射线没有碰撞前提下测试该射线方向是否可以移动
			ray.canMove = ! self.test_move(self.global_transform, self.moveSpeed * delta * ray.dir)
		# 射线的玩家比重为：方向向量点乘玩家方向向量
		ray.playerWeight = targetDir.dot(ray.dir)
		# 射线的移动比重为：方向向量点乘当前移动方向向量
		ray.moveonWeight = moveDir.dot(ray.dir)


# 查询合适的用于跟踪移动的射线
func _findRayDirection() -> void:
	var raysSameSide := []  # 与当前移动方向角度不大于90度的无碰撞射线集合
	var raysOtherSide := [] # 与当前移动方向角度超过90度的无碰撞射线集合
	for ray in _rays:
		if ray.canMove && ray.dir.dot(_currentRay.dir) > 0:
			raysSameSide.append(ray)
		elif ray.canMove:
			raysOtherSide.append(ray)
	
	# 当前射线没有发生碰撞则找出与玩家方向最合适的射线
	if _currentRay.canMove:
		for ray in _rays:
			if ray.canMove && ray.dir.dot(_currentRay.dir) > 0:
				raysSameSide.append(ray)
		for ray in raysSameSide:
			if ray.playerWeight >= _currentRay.playerWeight:
				_currentRay = ray
	# 当前射线发生碰撞或者不能移动，找出能移动的合适射线
	else:
		var newRay : Ray = _currentRay
		# 优先检测同一方向的射线
		if ! raysSameSide.empty():
			newRay = raysSameSide[0]
			for ray in raysSameSide:
				if ray.moveonWeight > newRay.moveonWeight:
					newRay = ray
		# 如果同一方向的射线全部发生碰撞，则检测另一方向
		elif ! raysOtherSide.empty():
			newRay = raysOtherSide[0]
			for ray in raysOtherSide:
				if ray.playerWeight > newRay.playerWeight:
					newRay = ray
		_currentRay = newRay


# 丢失跟踪目标
func _onLostTarget() -> void:
	_currentRay = _rays.front()


# 用于 Debug 将射线画出来
func _getRayPoints() -> Array:
	var rays := []
	var usePlayerWeight := true if _currentRay && _currentRay.canMove else false
	for ray in _rays:
		var start := Vector2.ZERO
		var end : Vector2 = ray.dir * ray.length * (ray.playerWeight / 40 if usePlayerWeight else ray.moveonWeight / 5)
		var enabled := true
		var collided : bool = ! ray.canMove
		rays.append({'start': start, 'end': end, 'enabled': enabled, 'collided': collided})
	return rays

