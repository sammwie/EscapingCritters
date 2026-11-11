extends Node2D

const LIFETIME := 0.4
const PUFF_OFFSETS := [
	Vector2(-6, 0),
	Vector2(-2, -3),
	Vector2(2, 0),
	Vector2(6, -2),
]
const PUFF_SIZES := [
	Vector2(4, 3),
	Vector2(5, 3),
	Vector2(4, 3),
	Vector2(3, 3),
]
const DUST_COLOR := Color(0.78, 0.72, 0.6, 0.7)

var _age := 0.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var progress := _age / LIFETIME
	var fade := 1.0 - progress
	for i in PUFF_OFFSETS.size():
		var direction := -1.0 if i < 2 else 1.0
		var offset: Vector2 = PUFF_OFFSETS[i] + Vector2(direction * progress * 4.0, -progress * 3.0)
		var size: Vector2 = PUFF_SIZES[i] * (1.0 - progress * 0.35)
		var color := DUST_COLOR
		color.a *= fade
		draw_rect(Rect2(offset - size * 0.5, size), color)
