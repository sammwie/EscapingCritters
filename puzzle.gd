class_name Puzzle
extends Node
## Base class for all five puzzles (farm, lake, shop, treehouse, town square).
## Levels only need to listen to `solved` / `failed`.

signal solved
signal failed

enum State { IDLE, ACTIVE, SOLVED, FAILED }
var state := State.IDLE

func start() -> void:
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
	solved.emit()

func fail() -> void:
	if state != State.ACTIVE:
		return
	state = State.FAILED
	failed.emit()

# Override these in each puzzle:
func _on_start() -> void: pass
func _on_reset() -> void: pass
