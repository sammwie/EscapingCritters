class_name Bed
extends Interactable
## Press E to sleep. Fades to black, starts a new day, and grows watered
## crops through Level1Quest, since the field lives in the village scene.
## Scene: Area2D (this script) > CollisionShape2D. Layer 2, mask empty.

var _sleeping := false

func _ready() -> void:
	prompt_text = "Sleep"

func _on_interact(by: Node) -> void:
	if _sleeping:
		return
	_sleeping = true
	enabled = false
	if by:
		by.set_physics_process(false)

	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	var black := ColorRect.new()
	black.color = Color(0.08, 0.06, 0.05, 0.0)
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(black)
	var label := Label.new()
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", Level1Quest.FONT_BOLD)
	label.add_theme_font_size_override("font_size", 64)
	label.add_theme_color_override("font_color", Level1Quest.CREAM)
	label.modulate.a = 0.0
	layer.add_child(label)

	var fade_in := create_tween()
	fade_in.tween_property(black, "color:a", 1.0, 1.0)
	await fade_in.finished

	Level1Quest.sleep_through_night()
	label.text = "Day %d" % GameState.current_day
	var show_day := create_tween()
	show_day.tween_property(label, "modulate:a", 1.0, 0.5)
	show_day.tween_interval(1.2)
	show_day.tween_property(label, "modulate:a", 0.0, 0.5)
	await show_day.finished

	var fade_out := create_tween()
	fade_out.tween_property(black, "color:a", 0.0, 1.0)
	await fade_out.finished

	layer.queue_free()
	if is_instance_valid(by):
		by.set_physics_process(true)
	enabled = true
	_sleeping = false
