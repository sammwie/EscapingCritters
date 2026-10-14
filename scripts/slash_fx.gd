class_name SlashFX
extends Node2D
## A short crescent flash drawn for sword/cleaver swings.

var dir := Vector2.RIGHT
var reach := 30.0
var life := 0.16
var color := Color(1, 0.972549, 0.9098039)
var _t := 0.0

static func spawn(parent: Node, pos: Vector2, direction: Vector2, p_reach: float, p_color := Color(1, 0.972549, 0.9098039)) -> void:
	var fx := SlashFX.new()
	fx.dir = direction
	fx.reach = p_reach
	fx.color = p_color
	fx.z_index = 20
	parent.add_child(fx)
	fx.global_position = pos

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _t >= life:
		queue_free()

func _draw() -> void:
	var k := clampf(_t / life, 0.0, 1.0)
	var a := dir.angle()
	var r := reach * (0.65 + 0.35 * k)
	var spread := deg_to_rad(70.0)
	draw_arc(Vector2.ZERO, r, a - spread, a + spread, 14, Color(color, 1.0 - k), 4.0)
	draw_arc(Vector2.ZERO, r - 4.0, a - spread * 0.8, a + spread * 0.8, 12, Color(1, 0.85, 0.4, (1.0 - k) * 0.8), 2.0)
