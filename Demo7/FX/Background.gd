extends ParallaxBackground

export(float) var scrollSpeed = 50

func _process(delta):
	# 手动控制背景滚动
	self.scroll_offset.y -= scrollSpeed * delta