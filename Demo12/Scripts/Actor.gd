extends KinematicBody2D
class_name Actor


### set gets:
export var maxHealth : float = 100 setget __setMaxHealth__
export var moveSpeed : float = 160

var health : float setget __setHealth__
var isInvulnerable := false setget __setIsInvulnerable__
var power : int = 1


func __setHealth__(value : float) -> void:
	health = value
	

func __setMaxHealth__(value : float) -> void:
	maxHealth = value


func __setIsInvulnerable__(value : bool) -> void:
	isInvulnerable = value


master func collect(itemIndex : int) -> void:
	pass


master func bomb(byKiller : int, damage : int) -> void:
	pass
