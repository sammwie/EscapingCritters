class_name KnowsAllWatcher
extends Node2D
## Knows All's first appearance (GDD Level 3): a formless shape far off,
## watching silently. It never approaches. If the player gets too close it
## dissolves, and it can show up somewhere else later.
## Emits `noticed` once, the first time the player comes within notice_range.
## PLACEHOLDER visuals drawn in code until the designers make the real art.

signal noticed

@export var notice_range := 140.0
@export var vanish_range := 70.0
@export var size := 10.0

var _t := 0.0
var _seen := false
var _gone := false
var _player: Node2D

func _ready() -> void:
	z_index = 2
	_player = get_tree().get_first_node_in_group("player") as Node2D

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _gone or _player == null:
		return
	var d := global_position.distance_to(_player.global_position)
	if not _seen and d <= notice_range:
		_seen = true
		noticed.emit()
	if d <= vanish_range:
		vanish()

func vanish() -> void:
	if _gone:
		return
	_gone = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.8)
	tw.tween_callback(queue_free)

func _draw() -> void:
	# A dark, shifting mass that is taller than it is wide, with no face.
	for i in 6:
		var a := _t * 0.7 + i * TAU / 6.0
		var off := Vector2(cos(a) * size * 0.5, sin(a * 1.3) * size * 0.9 - size)
		var r := size * (0.55 + 0.2 * sin(_t * 1.7 + i))
		draw_circle(off, r, Color(0.1, 0.03, 0.14, 0.7))
	draw_circle(Vector2(0, -size), size * 0.6, Color(0.02, 0.0, 0.04, 0.95))
