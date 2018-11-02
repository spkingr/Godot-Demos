extends Area2D

func _on_Coin_body_entered(body):
	$AnimationPlayer.current_animation = 'disappear'
	print('Coin collected!')

# 取消关联，已经在AnimationPlayer动画帧中实现
"""
func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == 'disappear':
		# queue_free方法将出该节点
		self.queue_free()
"""