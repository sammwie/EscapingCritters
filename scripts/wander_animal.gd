class_name WanderAnimal
extends Node2D
## A little animal that wanders around inside a rectangle: chickens, ducks.
## The sprite sheet is one row of frames. Frames 0 and 1 are the walk or
## swim cycle; idle_frame (if set) is shown on and off while it rests,
## like a chicken pecking.

@export var sheet: Texture2D
@export var frame_count := 2
@export var idle_frame := -1
@export var area := Rect2(0, 0, 64, 64)  # in world coordinates
@export var speed := 14.0
@export var shadow := true

var _sprite: Sprite2D
var _target := Vector2.ZERO
var _wait := 0.0
var _t := 0.0

func _ready() -> void:
	_t = randf() * 10.0
	if shadow:
		add_child(SoftShadow.make(Vector2(0, 6), Vector2(5, 2)))
	_sprite = Sprite2D.new()
	_sprite.texture = sheet
	_sprite.hframes = frame_count
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)
	_wait = randf_range(0.0, 2.0)
	_pick_target()

func _process(delta: float) -> void:
	_t += delta
	if _wait > 0.0:
		_wait -= delta
		if idle_frame >= 0:
			_sprite.frame = idle_frame if fmod(_t, 1.2) < 0.4 else 0
		else:
			_sprite.frame = int(_t * 2.0) % 2
		return
	var to_target := _target - global_position
	if to_target.length() < 1.0:
		_wait = randf_range(1.0, 3.5)
		_pick_target()
		return
	global_position += to_target.normalized() * minf(speed * delta, to_target.length())
	_sprite.flip_h = to_target.x < 0.0
	_sprite.frame = int(_t * 6.0) % 2

func _pick_target() -> void:
	_target = Vector2(
		randf_range(area.position.x, area.end.x),
		randf_range(area.position.y, area.end.y))
