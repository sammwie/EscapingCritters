class_name CrackingEgg
extends Interactable
## Level 2 egg. It looks like a normal egg, but when you pick it up it shakes,
## the glitch overlay flickers, and it cracks open with nothing inside.
## Emits `cracked` when the animation ends.

signal cracked

const EGG_TEX := preload("res://art/Inventory items/Normal Egg.png")
const SHELL_TEX := preload("res://art/Inventory items/Corrupted grey egg.png")
const ART_SCALE := 0.09

var is_cracked := false
var _sprite: Sprite2D

func _ready() -> void:
	prompt_text = "Collect egg"
	collision_layer = 2
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 7.0
	shape.shape = circle
	add_child(shape)
	_sprite = Sprite2D.new()
	_sprite.texture = EGG_TEX
	_sprite.scale = Vector2.ONE * ART_SCALE
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)

func _draw() -> void:
	if not is_cracked:
		return
	# the empty inside: a small dark hollow under the two shell halves
	var points := PackedVector2Array()
	for i in 14:
		var a := TAU * i / 14.0
		points.append(Vector2(cos(a) * 4.2, 1.0 + sin(a) * 5.0))
	draw_colored_polygon(points, Color(0.08, 0.06, 0.05))

func _on_interact(_by: Node) -> void:
	if is_cracked:
		return
	enabled = false
	for i in 8:
		_sprite.position.x = 1.3 if i % 2 == 0 else -1.3
		await get_tree().create_timer(0.05).timeout
	_sprite.position = Vector2.ZERO
	get_tree().call_group("glitch_overlay", "flicker", 0.35, 1.0)
	show_cracked()
	await get_tree().create_timer(0.35).timeout
	cracked.emit()

## Shows the cracked state immediately (also used when the scene reloads).
func show_cracked() -> void:
	is_cracked = true
	enabled = false
	if _sprite:
		_sprite.visible = false
	for side in [-1, 1]:
		var half := Sprite2D.new()
		half.texture = SHELL_TEX
		half.region_enabled = true
		half.region_rect = Rect2(0 if side < 0 else 64, 0, 64, 128)
		half.scale = Vector2.ONE * ART_SCALE
		half.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		half.position = Vector2(side * 4.6, 0)
		half.rotation = side * 0.4
		add_child(half)
	queue_redraw()
