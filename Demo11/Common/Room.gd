extends RigidBody2D
class_name Room


export var customSolver : float = 0.75  # 碰撞体形状的求解偏差

var _size : Vector2 = Vector2.ZERO      # 房间大小


func _ready():
	var shape = RectangleShape2D.new()
	shape.extents = _size / 2
	shape.custom_solver_bias = customSolver
	$CollisionShape2D.shape = shape


# 设置房间的位置和大小
func makeRoom(pos: Vector2, size: Vector2) -> void:
	self.position = pos
	_size = size


# 获取房间的位置尺寸，可以传入一个偏差值
func getRect(tolerance : float = 0.0) -> Rect2:
	var s = _size - Vector2(tolerance, tolerance)
	return Rect2(self.position - s / 2, s)
