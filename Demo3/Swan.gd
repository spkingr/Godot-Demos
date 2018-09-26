extends Sprite

# 速度常量
const SPEED = 100
# 最左边界和最右边界
var minX = -100
var maxX = 800

func _process(delta):
	position.x -= SPEED * delta
	# 如果天鹅飞到左边边界，把它的x坐标置为最右边界
	if position.x < minX:
		position.x = maxX
