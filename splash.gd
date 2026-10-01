extends Node2D

@export var logos: Array[TextureRect] = []
@export var fade_in_time := 1.0
@export var hold_time := 1.5
@export var fade_out_time := 1.0
@export var next_scene_path := "res://MainMenu.tscn"

func _ready() -> void:
	for logo in logos:
		logo.modulate.a = 0.0
	_play_splash()

func _play_splash() -> void:
	for logo in logos:
		var tween_in = create_tween()
		tween_in.tween_property(logo, "modulate:a", 1.0, fade_in_time)
		await tween_in.finished

		await get_tree().create_timer(hold_time).timeout

		var tween_out = create_tween()
		tween_out.tween_property(logo, "modulate:a", 0.0, fade_out_time)
		await tween_out.finished

	get_tree().change_scene_to_file(next_scene_path)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton:
		get_tree().change_scene_to_file(next_scene_path)
