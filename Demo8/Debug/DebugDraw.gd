# Code by GDQuest
# http://gdquest.com/
# Usage: Attach this script to a Node2D and 
# add as a child of the node you want to draw vectors

# 本脚本源码来自 GDQuest 并被我修改部分代码
# 注意，该节点的父节点必须有一个速度属性： Vector2 velocity
extends Node2D

var colors = {
	'WHITE': Color(.8, .8, .8, 0.2),
	'BLUE': Color(.216, .474, .702, 0.2),
	'RED': Color(1.0, .329, .298, 0.7),
	'YELLOW': Color(.867, .91, .247),
	'GREEN': Color(.054, .718, .247, 0.7)
}

export(String, 'WHITE', 'BLUE', 'RED', 'YELLOW', 'GREEN') var color = 'RED'
export(float) var size = 0.5

const WIDTH = 15
const ARROW_SIZE = 20

var parent = null

func _ready():
	visible = true
	parent = get_parent()

func _process(delta):
	global_rotation = 0
	update()

func _draw():
	if 'velocity' in parent:
		draw_arrow(parent.velocity, Vector2(), size, color)

func draw_arrow(vector, pos, size, color):
	color = colors[color]
	if vector.length() == 0:
		return
	draw_line(pos * scale, vector * size, color, WIDTH)
	var dir = vector.normalized()
	draw_triangle(vector * size, dir, ARROW_SIZE, color)
	draw_circle(pos, 3, color)

func draw_triangle(pos, dir, size, color):
	var a = pos + dir * size
	var b = pos + dir.rotated(2*PI/3) * size
	var c = pos + dir.rotated(4*PI/3) * size
	var points = PoolVector2Array([a, b, c])
	draw_polygon(points, PoolColorArray([color]))
