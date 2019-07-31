extends Node2D


# 引起爆炸的物体名称集合，这里为玩家和子弹
export(Array, String) var triggerGroups := ['player', 'bullet']


func _on_Area2D_area_or_body_entered(area_or_body):
	for group in triggerGroups:
		if area_or_body.is_in_group(group):
			$Explode.explode()
			$Area2D.queue_free()
			return
