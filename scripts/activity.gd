class_name Activity
extends Node
## Base class for the cozy activities: farming, fishing, shop, treehouse,
## town square. Like Puzzle, but for things with no win/lose state.

signal started
signal finished(result: Dictionary)

@export var activity_id: StringName = &""
var running := false

func start() -> void:
	if running:
		return
	running = true
	_on_start()
	started.emit()

func finish(result: Dictionary = {}) -> void:
	if not running:
		return
	running = false
	_on_finish(result)
	finished.emit(result)

# Override in each activity:
func _on_start() -> void: pass
func _on_finish(_result: Dictionary) -> void: pass
