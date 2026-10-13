class_name Puzzle
extends Node
## Base class for all five puzzles (farm, lake, shop, treehouse, town square).
## Levels only need to listen to `solved` / `failed`.
## Every puzzle has an ID and reports to WorldState when solved.

signal solved
signal failed

enum State { IDLE, ACTIVE, SOLVED, FAILED }

@export var puzzle_id: StringName = &""
var state := State.IDLE

func start() -> void:
	if puzzle_id == &"":
		push_warning("Puzzle '%s' has no puzzle_id set." % name)
	state = State.ACTIVE
	_on_start()

func reset() -> void:
	state = State.IDLE
	_on_reset()
	start()

func complete() -> void:
	if state != State.ACTIVE:
		return
	state = State.SOLVED
	_report_solved()
	solved.emit()

func fail() -> void:
	if state != State.ACTIVE:
		return
	state = State.FAILED
	failed.emit()

# WorldState is owned by Coder 3. Until it exists (or if it has no
# mark_solved method yet) this does nothing, so nothing breaks.
# Expected API: WorldState.mark_solved(puzzle_id: StringName)
func _report_solved() -> void:
	var ws := get_node_or_null("/root/WorldState")
	if ws and ws.has_method("mark_solved"):
		ws.mark_solved(puzzle_id)

# Override these in each puzzle:
func _on_start() -> void: pass
func _on_reset() -> void: pass
