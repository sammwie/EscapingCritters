extends Node2D
## PLACEHOLDER for the Knows All map (final level). Replace this scene's
## contents when the designers deliver the real map; keep the Level3Quest
## node and the story_map = "knows_all" metadata on the root.
## Draws a dark void with a slowly shifting formless mass in the middle.

const FONT_BOLD := preload("res://art/fonts/Silkscreen-Bold.ttf")
const FONT_REG := preload("res://art/fonts/Silkscreen-Regular.ttf")
const CREAM := Color(1, 0.972549, 0.9098039)

var _t := 0.0

func _ready() -> void:
	_intro.call_deferred()

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-400, -300, 1312, 1000), Color(0.04, 0.02, 0.06))
	var center := Vector2(256, 200)
	for i in 7:
		var a := _t * 0.6 + i * TAU / 7.0
		var r := 34.0 + 10.0 * sin(_t * 1.3 + i)
		draw_circle(center + Vector2.from_angle(a) * 18.0, r, Color(0.22, 0.08, 0.3, 0.55))
	draw_circle(center, 30.0 + 4.0 * sin(_t * 2.0), Color(0.08, 0.02, 0.12))

func _intro() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(false)
	var layer := CanvasLayer.new()
	layer.layer = 60
	add_child(layer)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.modulate.a = 0.0
	layer.add_child(box)
	for pair in [["Knows All", FONT_BOLD, 64], ["[Placeholder: final level map goes here]", FONT_REG, 22]]:
		var label := Label.new()
		label.text = pair[0]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font", pair[1])
		label.add_theme_font_size_override("font_size", pair[2])
		label.add_theme_color_override("font_color", CREAM)
		box.add_child(label)
	var tw := create_tween()
	tw.tween_property(box, "modulate:a", 1.0, 1.5)
	tw.tween_interval(3.0)
	tw.tween_property(box, "modulate:a", 0.0, 1.0)
	await tw.finished
	layer.queue_free()
	if player:
		player.set_physics_process(true)
