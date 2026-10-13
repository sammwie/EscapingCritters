class_name Egg
extends LyingObject
## A coop egg. Real eggs are collected; fake ones crack open empty.
## Scene: Area2D (this script) > CollisionShape2D (CircleShape2D, radius ~10).
## Collision: Layer 2 only, Mask empty.
## Set is_safe = false in the Inspector for fake eggs.
## Placeholder visuals: a drawn oval. Fake eggs get a subtle tell (slightly
## off-white) until the designers decide what the real tell is (spec Q3).

@export var tell_strength := 0.15  # 0 = fake looks identical to real

var opened := false

func _ready() -> void:
	prompt_text = "Take egg"
	add_to_group("eggs")
	queue_redraw()

func _draw() -> void:
	var col := Color("f5f0e1")
	if not is_safe and not opened:
		col = col.darkened(tell_strength)
	if opened and not is_safe:
		col = Color("2b2b2b")  # cracked open, empty
	draw_circle(Vector2.ZERO, 10.0, col)

func _play_reveal() -> void:
	opened = true
	enabled = false
	prompt_text = ""
	queue_redraw()
