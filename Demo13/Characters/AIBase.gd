"""
AI 基类，其他三种 AI 的父类： AIWithNavigation/AIWithRaycasts/AIWithPathTracker
"""
extends KinematicBody2D


export var moveSpeed := 150                 # 移动速度
export var minFollowDistance := 16          # 最小跟随距离
export var pathPointCount := 20             # AI自身路径记录点数量
export var debugNodePath := @''             # 画图节点，用于Debug
export var pathPointMinRecordDistance := 16 # AI自身路径点用于记录的最短距离（距离上一个点）

onready var _visionArea := $VisionArea2D as Area2D
onready var _labelName := $LabelName as Label

var _debugNode : Node2D = null # Debug节点
var _points := []              # 用于Debug的路径点

var target : WeakRef = null    # 跟随目标，弱引用


func _ready() -> void:
	if ! debugNodePath.is_empty():
		_debugNode = self.get_node(debugNodePath)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed('toggle_name'):
		_labelName.visible = ! _labelName.visible
	

func _physics_process(delta: float) -> void:
	if target == null || target.get_ref() == null:
		_points.clear()
		if _debugNode:
			_debugNode.path = []
		return
	
	var player : Node2D = target.get_ref()
	if player.global_position.distance_to(self.global_position) > minFollowDistance:
		var dir := _findMoveDirection(delta, player)
		self.move_and_slide(moveSpeed * dir)
	
	if _debugNode:
		_debugNode.path = _getPathPoints()
		_debugNode.rays = _getRayPoints()


func _on_ScanArea_body_entered(body: Node) -> void:
	if body.is_in_group('player'):
		target = weakref(body)


func _on_ScanArea_body_exited(body: Node) -> void:
	_onLostTarget()
	target = null


# 根据当前目标返回 AI 追踪方向
func _findMoveDirection(delta: float, target : Node2D) -> Vector2:
	var dir := (target.global_position - self.global_position).normalized()
	return dir


# 丢失跟踪目标时调用该方法
func _onLostTarget() -> void:
	pass


# 获取用于 Debug 的点
func _getPathPoints() -> Array:
	if _points.empty() || self.global_position.distance_to(_points[-1]) >= pathPointMinRecordDistance:
		_points.append(self.global_position)
	if _points.size() > pathPointCount:
		_points.pop_front()
	return _points


# 获取用于 Debug 的射线
func _getRayPoints() -> Array:
	return []

