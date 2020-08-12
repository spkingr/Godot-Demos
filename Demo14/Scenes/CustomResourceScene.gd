extends Node2D


export var customResource1 : Resource = null
export var customResource2 : Resource = null
export var customResource3 : Resource = null


func _ready() -> void:
	if customResource1 && customResource1 is CustomResource:
		customResource1.printInfo()
	if customResource2 && customResource2 is CustomResource:
		customResource2.printInfo()
	if customResource3 && customResource3 is CustomResource:
		customResource3.printInfo()


