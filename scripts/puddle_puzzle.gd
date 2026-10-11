class_name PuddlePuzzle
extends Puzzle
## Example subclass. Add LyingObject rocks as children of `rocks_parent`.
## Safe path is fixed per playthrough via GameState.puzzle_seed.

@export var rocks_parent: Node
@export var safe_ratio := 0.5

var _rocks: Array[LyingObject] = []

func _on_start() -> void:
	_rocks.clear()
	for child in rocks_parent.get_children():
		if child is LyingObject:
			_rocks.append(child)
	var rng := RandomNumberGenerator.new()
	rng.seed = GameState.puzzle_seed
	for rock in _rocks:
		rock.is_safe = rng.randf() < safe_ratio
		if not rock.revealed.is_connected(_on_rock_revealed):
			rock.revealed.connect(_on_rock_revealed)

func _on_rock_revealed(safe: bool) -> void:
	if not safe:
		fail() # level restarts on failure; same seed = same layout
