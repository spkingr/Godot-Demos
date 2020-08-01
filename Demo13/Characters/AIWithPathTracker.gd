"""
继承自 AIBase 基类， AI 根据所跟踪目标的路径进行移动、跟随，该寻路方法原文来自 ABitAwake 的博文： 
[Enemy AI: chasing a player without Navigation2D or A* pathfinding]
原文链接： 
[https://abitawake.com/news/articles/enemy-ai-chasing-a-player-without-navigation2d-or-a-star-pathfinding]
Reddit ： [https://www.reddit.com/r/godot/comments/fxab0w/enemy_ai_tutorial_chasing_a_player_without/]
在此方法基础上，本人进行了一定的修改，具体请参考本人博客相关文章：
[http://liuqingwne.me]
"""
extends "res://Characters/AIBase.gd"


export(float, 0.0, 10.0) var recordTimeInterval = 0.1    # 记录跟踪目标位置的时间间隔
export(int, 1, 100) var maxTargetPositionRecords = 8     # 记录位置点的最大数量
export(float, 0.0, 100.0) var minDistanceToRecord = 1.0  # 允许记录位置距离上一点的最小距离

onready var _raycastTarget = $RayCastTarget as RayCast2D # 直接指向目标的检测射线
onready var _raycastStatic = $RayCastStatic as RayCast2D # 指向记录下的目标移动点的射线
onready var _trackTimer := $TrackTimer as Timer          # 跟踪记录位置计时器

var _trackPoints := []           # 跟踪目标的位置点集合
var _trackTarget : Node2D = null # 跟踪目标，可以用父类中的 target.get_ref() 代替


func _ready() -> void:
	_trackTimer.wait_time = recordTimeInterval


func _findMoveDirection(delta: float, target : Node2D) -> Vector2:
	_trackTarget = target
	if _trackTimer.is_stopped():
		# 开启记录计时器
		_trackTimer.start()
	
	var dir := target.global_position - self.global_position
	# 更新射线的指向，强制更新检测结果，如果没有碰撞则优先按此方向移动
	_raycastTarget.cast_to = dir
	_raycastTarget.force_raycast_update()
	# 如果AI与目标之间有碰撞或者不能移动，则开始检测记录下的目标行踪点数组
	if _raycastTarget.is_colliding() && _raycastTarget.get_collider() != target || self.test_move(self.transform, moveSpeed * delta * dir.normalized()):
		# 循环遍历所有记录点，寻找可以移动的点
		for point in _trackPoints:
			var newDir = point - self.global_position
			# 更新射线指向记录点，强制更新检测结果
			_raycastStatic.cast_to = newDir
			_raycastStatic.force_raycast_update()
			# 如果指向该点的射线有发生碰撞，可以移动，那么按该方向移动
			if ! _raycastStatic.is_colliding() && ! self.test_move(self.transform, moveSpeed * delta * newDir.normalized()):
				dir = newDir
				break
	
	return dir.normalized()


func _onLostTarget() -> void:
	_trackTimer.stop()
	_trackTarget = null


func _getPathPoints() -> Array:
	return _trackPoints


func _getRayPoints() -> Array:
	return [_raycastTarget, _raycastStatic]


# 每隔一段时间记录目标的位置
func _on_TrackTimer_timeout() -> void:
	if _trackTarget == null || ! is_instance_valid(_trackTarget):
		return
	
	if ! _trackPoints.empty():
		var distance = _trackTarget.global_position.distance_to(_trackPoints[0])
		if distance <= minDistanceToRecord:
			return
	if _trackPoints.size() >= maxTargetPositionRecords:
		_trackPoints.pop_back()
	
	# 将当前目标的位置记录在数组的第一个位置
	_trackPoints.push_front(_trackTarget.global_position)

