class_name HidingPuzzle
extends Puzzle
## Sneak past patrolling guards to the exit. Hide in bushes (interact) to
## avoid the vision cones. If you're caught you restart from the start point.

@export var guards_parent: Node
@export var exit_marker: Node2D
@export var start_marker: Node2D
@export var exit_radius := 24.0
@export var caught_text := "You were seen... start again."
@export var caught_delay := 1.0
@export var fade_time := 0.5
@export var auto_start := true

var _player: Node2D
var _running := false
var _caught := false
var _layer: CanvasLayer
var _fade_rect: ColorRect
var _label: Label

func _ready() -> void:
	_build_overlay()
	if auto_start:
		start.call_deferred()

func _on_start() -> void:
	_player = get_tree().get_first_node_in_group("player") as Node2D
	_caught = false
	for guard in _guards():
		guard.player = _player
		if not guard.spotted.is_connected(_on_spotted):
			guard.spotted.connect(_on_spotted)
	_running = true

func _on_reset() -> void:
	_running = false
	for guard in _guards():
		guard.reset_guard()

func _guards() -> Array:
	var out: Array = []
	if guards_parent:
		for child in guards_parent.get_children():
			if child is PatrolGuard:
				out.append(child)
	return out

func _physics_process(_delta: float) -> void:
	if not _running or _caught or _player == null or exit_marker == null:
		return
	if _player.global_position.distance_to(exit_marker.global_position) <= exit_radius:
		_running = false
		complete()

func _on_spotted() -> void:
	if _caught:
		return
	_caught = true
	_running = false
	for guard in _guards():
		guard.set_active(false)
	if _player:
		_player.set_physics_process(false)
	fail()
	_label.text = caught_text
	_label.visible = true
	var tw := create_tween()
	tw.tween_property(_fade_rect, "color:a", 1.0, fade_time)
	await tw.finished
	await get_tree().create_timer(caught_delay).timeout
	get_tree().call_group("hiding_spot", "release")
	if _player:
		if start_marker:
			_player.global_position = start_marker.global_position
		_player.visible = true
		_player.set_meta("hidden", false)
		_player.set_physics_process(true)
	reset()
	_label.visible = false
	var tw2 := create_tween()
	tw2.tween_property(_fade_rect, "color:a", 0.0, fade_time)
	await tw2.finished
	start()

func _build_overlay() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 100
	add_child(_layer)
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_fade_rect)
	_label = Label.new()
	_label.visible = false
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_label)
