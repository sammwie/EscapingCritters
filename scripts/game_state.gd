extends Node

signal corruption_changed(stage: int)
signal day_changed(day: int)
signal puzzle_solved(puzzle_id: String)

const FIRST_CORRUPTION_PUZZLE_ID := "farm_eggs"

var current_level := 1

var current_day := 1:
	set(value):
		if current_day == value:
			return
		current_day = value
		day_changed.emit(current_day)

var corruption_stage := 0:
	set(value):
		var next_stage := maxi(value, 0)
		if corruption_stage == next_stage:
			return
		corruption_stage = next_stage
		corruption_changed.emit(corruption_stage)

# Fixed within a playthrough; randomized for a new one.
var puzzle_seed := 0

var solved_puzzles: Dictionary = {}


func advance_day() -> void:
	current_day += 1


func mark_solved(puzzle_id: String) -> void:
	if puzzle_id.is_empty() or is_solved(puzzle_id):
		return

	solved_puzzles[puzzle_id] = true
	if puzzle_id == FIRST_CORRUPTION_PUZZLE_ID:
		set_corruption_stage(maxi(corruption_stage, 1))
	puzzle_solved.emit(puzzle_id)


func is_solved(puzzle_id: String) -> bool:
	return solved_puzzles.has(puzzle_id)


func set_corruption_stage(stage: int) -> void:
	corruption_stage = stage


func new_playthrough() -> void:
	solved_puzzles.clear()
	puzzle_seed = randi()
	current_level = 1
	current_day = 1
	corruption_stage = 0
