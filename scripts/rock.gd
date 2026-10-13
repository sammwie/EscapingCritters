class_name Rock
extends LyingObject
## A stepping stone in the puddle. Looks the same whether safe or not;
## pressing E on it tests it. Unsafe rocks sink (dark), safe ones hold (gray).
## Scene: Area2D (this script) > CollisionShape2D (CircleShape2D, radius ~12).
## Collision: Layer 2 only, Mask empty.
## is_safe is set by PuddlePuzzle at start, so leave it alone in the Inspector.

var tested := false

func _ready() -> void:
	prompt_text = "Step on rock"
	queue_redraw()

func _draw() -> void:
	var col := Color("9a9a9a")
	if tested:
		col = Color("6fbf73") if is_safe else Color("1d2b4a")  # holds / sinks
	draw_circle(Vector2.ZERO, 12.0, col)

func _play_reveal() -> void:
	tested = true
	enabled = false
	queue_redraw()

# Called by PuddlePuzzle when the puzzle restarts.
func reset_rock() -> void:
	tested = false
	enabled = true
	queue_redraw()
