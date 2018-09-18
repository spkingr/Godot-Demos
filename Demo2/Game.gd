# 继承于Node2D
extends Node2D

# 常量，表示速度（像素）
const SPEED = 200
# 定义一些变量，不需要类型
var maxX = 600 # 角色运动右边界
var minX = 0 # 角色运动左边界
var knight

# 节点进入场景开始时调用此方法，常用作初始化
func _ready():
	knight = self.get_node("Knight")
	maxX -= knight.get_rect().size.x / 2
	minX += knight.get_rect().size.x / 2

# 每一帧运行此方法，delta表示每帧间隔
func _process(delta):
	# Input表示设备输入，这里D和右光标表示往右动
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		moveKnightX(1, SPEED, delta)
	elif Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		moveKnightX(-1, SPEED, delta)
	
# 自定义函数，direciton表示方向，speed表示速度，delta是帧间隔
func moveKnightX(direction, speed, delta):
	if direction == 0:
		return
	# position属性为节点当前置，Vector2向量简单乘法
	knight.position += Vector2(SPEED, 0) * delta * direction
	# 越界检测
	if knight.position.x > maxX:
		knight.position = Vector2(maxX, knight.position.y)
	elif knight.position.x < minX:
		knight.position = Vector2(minX, knight.position.y)
	
	knight.scale = Vector2(direction, 1)
