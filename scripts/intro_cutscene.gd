extends Node2D

## Attach this to the root node of whatever scene should open with the
## story intro. Builds its own fullscreen text overlay in code, fades
## each line in and out in sequence, then removes itself and lets the
## player move. No manual UI nodes needed, and no other changes to the
## scene are made.

@export var intro_lines := [
	"You wake up in a place that feels... perfect.",
	"Flower fields. Quiet cottages. The sun, warm and still.",
	"Everything here is exactly as it should be."
]
@export var line_hold_time := 2.2
@export var fade_time := 0.8

var overlay: CanvasLayer
var bg: ColorRect
var label: Label
var player: Node = null

func _ready() -> void:
	# Only play the intro the first time, not when walking back out of a building.
	if get_tree().root.has_meta("intro_played"):
		return
	get_tree().root.set_meta("intro_played", true)

	player = _find_player(self)
	if player and player.has_method("set_physics_process"):
		player.set_physics_process(false)
		player.set_process_unhandled_input(false)

	_build_overlay()
	_play_intro()

func _find_player(node: Node) -> Node:
	for child in node.get_children():
		if child.name == "Player" or (child is CharacterBody2D):
			return child
		var found := _find_player(child)
		if found:
			return found
	return null

func _build_overlay() -> void:
	overlay = CanvasLayer.new()
	overlay.layer = 100
	add_child(overlay)

	bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(bg)

	label = Label.new()
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(800, 100)
	label.position = -label.custom_minimum_size / 2
	label.modulate.a = 0.0
	overlay.add_child(label)

func _play_intro() -> void:
	for line in intro_lines:
		label.text = line
		var tween_in := create_tween()
		tween_in.tween_property(label, "modulate:a", 1.0, fade_time)
		await tween_in.finished

		await get_tree().create_timer(line_hold_time).timeout

		var tween_out := create_tween()
		tween_out.tween_property(label, "modulate:a", 0.0, fade_time)
		await tween_out.finished

	var bg_fade := create_tween()
	bg_fade.tween_property(bg, "color:a", 0.0, fade_time)
	await bg_fade.finished

	overlay.queue_free()

	if player:
		player.set_physics_process(true)
		player.set_process_unhandled_input(true)
