class_name SoftShadow
extends Node2D
## A soft oval shadow drawn under a character so it sits on the ground.

@export var radius := Vector2(6, 2.5)
@export var color := Color(0.1, 0.07, 0.05, 0.25)

func _draw() -> void:
	var points := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		points.append(Vector2(cos(a) * radius.x, sin(a) * radius.y))
	draw_colored_polygon(points, color)

static func make(offset: Vector2, size: Vector2) -> SoftShadow:
	var s := SoftShadow.new()
	s.name = "Shadow"
	s.position = offset
	s.radius = size
	return s
