class_name Butterflies
extends Node2D
## Spawns a few butterflies that flutter around the village.

@export var count := 6
@export var area := Rect2(40, 40, 430, 520)
@export var colors: Array[Color] = [Color.WHITE, Color(1, 0.95, 0.5), Color(0.75, 0.85, 1), Color(1, 0.8, 0.9)]

const SHEET := preload("res://art/animals/butterfly.png")

var _flies: Array[Dictionary] = []

func _ready() -> void:
	z_index = 5
	for i in count:
		var s := Sprite2D.new()
		s.texture = SHEET
		s.hframes = 2
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.modulate = colors[i % colors.size()]
		s.position = _random_point()
		add_child(s)
		_flies.append({"sprite": s, "target": _random_point(), "t": randf() * 5.0})

func _process(delta: float) -> void:
	for f in _flies:
		var s: Sprite2D = f.sprite
		f.t += delta
		s.frame = int(f.t * 8.0) % 2
		var to_target: Vector2 = f.target - s.position
		if to_target.length() < 2.0:
			f.target = _random_point()
		var wobble := Vector2(0, sin(f.t * 6.0) * 0.4)
		s.position += to_target.normalized() * 12.0 * delta + wobble
		s.flip_h = to_target.x < 0.0

func _random_point() -> Vector2:
	return Vector2(randf_range(area.position.x, area.end.x), randf_range(area.position.y, area.end.y))
