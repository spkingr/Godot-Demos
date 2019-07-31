extends Node2D


export var roomScene : PackedScene = null  # 房间子场景
export var roomCount : int = 25            # 房间总数量
export var tileSize : int = 32             # 地图瓦片单元尺寸
export var minSize : int = 4               # 房间最小尺寸，乘以瓦片尺寸
export var maxSize : int = 10              # 房间最大尺寸，乘以瓦片尺寸
export(float, 0.0, 1.0) var cullTolerance : float = 0.4  # 剔除部分房间，系数

onready var _roomContainer := $RoomContainer
onready var _camera := $Camera2D
onready var _windowSize : Vector2 = self.get_viewport_rect().size

var _isWorking := false                    # 是否正在进行生成中
var _astarPath : AStar = null              # AStar算法实例
var _zoom : Vector2 = Vector2.ONE          # 相机缩放
var _offset : Vector2 = Vector2.ZERO       # 相机偏移


func _unhandled_input(event):
	if event.is_action_pressed('ui_accept'):
		generateRooms()


func _ready():
	generateRooms()


func _process(delta):
	_camera.zoom = lerp(_camera.zoom, _zoom, 0.5)
	_camera.offset = lerp(_camera.offset, _offset, 0.25)
	self.update() # 更新重绘


func _draw():
	# 绘制房间
	for room in _roomContainer.get_children():
		self.draw_rect(room.getRect(), Color(0.0, 1.0, 0.0), false)
	
	# 绘制AStar中的链接点路径
	if _astarPath:
		for point in _astarPath.get_points():
			var pos1 : Vector3 = _astarPath.get_point_position(point)
			for connection in _astarPath.get_point_connections(point):
				var pos2 : Vector3 = _astarPath.get_point_position(connection)
				self.draw_line(Vector2(pos1.x, pos1.y), Vector2(pos2.x, pos2.y), Color(1.0, 0.0, 0.0), 5.0, true)


# 随机地图生成方法，可以拆分为多个函数，这里分4步
func generateRooms() -> void:
	if ! roomScene || _isWorking:
		return
	
	# 标记，删除旧房间
	_isWorking = true
	_astarPath = null
	for room in _roomContainer.get_children():
		room.queue_free()
	
	# 随机生成新的房间，尺寸随机
	randomize()
	for i in range(roomCount):
		var room : Room = roomScene.instance()
		var width := randi() % (maxSize - minSize) + minSize
		var height := randi() % (maxSize - minSize) + minSize
		var size := Vector2(width, height) * tileSize
		room.makeRoom(Vector2.ZERO, size)
		_roomContainer.add_child(room)
	print('Step 1 is done.') # 第一步完成
	
	# 停留1秒，让生成的房间有足够时间分散开
	yield(self.get_tree().create_timer(1.0), 'timeout')
	
	# 随机删除一部分房间，把房间的位置全部添加到数组，注意时 Vector3 类型
	var allPoints : Array = []
	for room in _roomContainer.get_children():
		if randf() < cullTolerance:
			room.queue_free()
		else:
			room.mode = RigidBody2D.MODE_STATIC
			allPoints.append(Vector3(room.position.x, room.position.y, 0.0))
	print('Step 2 is done.') # 第二步完成
	
	# 创建新的AStar算法，添加第一个点
	_astarPath = AStar.new()
	_astarPath.add_point(_astarPath.get_available_point_id(), allPoints.pop_front())
	# 循环所有【未添加的点】，循环所有AStar中【已添加的点】
	# 找出【未添加点】与【已添加点】的距离中，【最短】的距离点，并添加到AStar中
	# 同时将该点从【未添加点集合】中删除
	while allPoints:
		var minDistance : float = INF
		var minDistancePosition : Vector3
		var minDistancePositionIndex : int
		var currentPointId :int = -1
		for point in _astarPath.get_points():
			for index in range(allPoints.size()):
				var pos = allPoints[index]
				var distance = _astarPath.get_point_position(point).distance_to(pos)
				if distance < minDistance:
					minDistance = distance
					minDistancePosition = pos
					minDistancePositionIndex = index
					currentPointId = point
		var id = _astarPath.get_available_point_id()
		_astarPath.add_point(id, minDistancePosition)
		_astarPath.connect_points(currentPointId, id)
		allPoints.remove(minDistancePositionIndex)
	print('Step 3 is done.') # 第三步完成
	
	# 等待一帧的时间，用于等待被删除的房间被彻底移除
	yield(self.get_tree(), 'idle_frame')
	if _roomContainer.get_child_count() == 0:
		return
	
	# 找出所有房间最左上角和最右下角的两个坐标，确定摄像机的缩放和位移
	var minPos := Vector2(_roomContainer.get_child(0).position.x, _roomContainer.get_child(0).position.y)
	var maxPos := minPos
	for room in _roomContainer.get_children():
		var rect := room.getRect() as Rect2
		if rect.position.x < minPos.x:
			minPos.x = rect.position.x
		if rect.end.x > maxPos.x:
			maxPos.x = rect.end.x
		if rect.position.y < minPos.y:
			minPos.y = rect.position.y
		if rect.end.y > maxPos.y:
			maxPos.y = rect.end.y
	_zoom = Vector2.ONE * ceil(max((maxPos.x - minPos.x) / _windowSize.x, (maxPos.y - minPos.y) / _windowSize.y))
	_offset = (maxPos + minPos) / 2
	print('Step 4 is done.') # 第四步完成
	
	_isWorking = false


func _on_Button_pressed():
	self.get_tree().change_scene('res://Main.tscn')
