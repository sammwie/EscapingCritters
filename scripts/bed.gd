class_name Bed
extends Interactable
## Press E on the bed to sleep: fade to black, advance the day, fade back in.
## Emits `slept` after the day has advanced (Coder 1 connects the wake-up and
## the new day-time map to this).
## required_flag: optional GameState flag that must be true before the player
## can sleep (e.g. the butcher note was read). Empty = always allowed. Needs
## GameState.get_flag(); if that doesn't exist yet, sleeping is allowed.
## On sleeping it calls GameState.set_flag("slept", true) if that exists.

signal slept

@export var sleep_prompt := "Go to sleep"
@export var not_tired_text := "Not tired yet."
@export var required_flag: StringName = &""
@export var fade_time := 1.0
@export var black_time := 0.8
@export var advances_day := true

var _sleeping := false

func _ready() -> void:
	prompt_text = sleep_prompt

func _can_sleep() -> bool:
	if required_flag == &"":
		return true
	if GameState.has_method("get_flag"):
		return bool(GameState.call("get_flag", required_flag))
	return true  # can't check yet, so don't block testing

func _on_interact(_by: Node) -> void:
	if _sleeping:
		return
	if not _can_sleep():
		_toast(not_tired_text)
		return
	_sleeping = true
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(false)
	var layer := CanvasLayer.new()
	layer.layer = 100
	var fade := ColorRect.new()
	fade.color = Color.BLACK
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.modulate.a = 0.0
	layer.add_child(fade)
	get_tree().current_scene.add_child(layer)
	var tw := create_tween()
	tw.tween_property(fade, "modulate:a", 1.0, fade_time)
	await tw.finished
	_advance_day()
	if GameState.has_method("set_flag"):
		GameState.call("set_flag", "slept", true)
	slept.emit()
	await get_tree().create_timer(black_time).timeout
	var tw2 := create_tween()
	tw2.tween_property(fade, "modulate:a", 0.0, fade_time)
	await tw2.finished
	layer.queue_free()
	if player:
		player.set_physics_process(true)
	_sleeping = false

func _advance_day() -> void:
	if not advances_day:
		return
	if get_tree().has_group("farm_manager"):
		get_tree().call_group("farm_manager", "end_day")  # advances the day and grows crops
	elif GameState.has_method("advance_day"):
		GameState.call("advance_day")

func _toast(text: String) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 90
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	label.position.y = 80
	layer.add_child(label)
	get_tree().current_scene.add_child(layer)
	var tw := create_tween()
	tw.tween_interval(1.2)
	tw.tween_property(label, "modulate:a", 0.0, 0.5)
	tw.tween_callback(layer.queue_free)
