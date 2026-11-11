class_name PuzzleTrigger
extends Interactable

@export var puzzle: Puzzle


func _process(_delta: float) -> void:
	if puzzle and "solved_puzzles" in GameState:
		enabled = not GameState.solved_puzzles.has(puzzle.puzzle_id)


func _on_interact(by: Node) -> void:
	if puzzle:
		puzzle.start()
