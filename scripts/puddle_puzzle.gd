class_name PuddlePuzzle
extends Puzzle
## Puddle puzzle: test rocks to find the safe path, then reach the goal.
## Add LyingObject (or Rock) children under `rocks_parent`, and point `goal`
## at an Area2D on the far side (its collision mask must include layer 3,
## the player). Safe path is fixed per playthrough via GameState.puzzle_seed.
## Testing an unsafe rock fails the puzzle; with auto_reset the puzzle
## restarts with the same layout (same seed = same safe rocks).

@export var rocks_parent: Node
@export var goal: Area2D
@export var safe_ratio := 0.5
@export var auto_reset := true

var _rocks: Array[LyingObject] = []

func _ready() -> void:
	if puzzle_id == &"":
		puzzle_id = &"puddle"
	if goal and not goal.body_entered.is_connected(_on_goal_entered):
		goal.body_entered.connect(_on_goal_entered)
	failed.connect(_on_failed)
	start()

func _on_start() -> void:
	_rocks.clear()
	if rocks_parent == null:
		push_warning("PuddlePuzzle '%s' has no rocks_parent." % name)
		return
	for child in rocks_parent.get_children():
		if child is LyingObject:
			_rocks.append(child)
	var rng := RandomNumberGenerator.new()
	rng.seed = GameState.puzzle_seed
	for rock in _rocks:
		rock.is_safe = rng.randf() < safe_ratio
		if not rock.revealed.is_connected(_on_rock_revealed):
			rock.revealed.connect(_on_rock_revealed)

func _on_reset() -> void:
	for rock in _rocks:
		if rock.has_method("reset_rock"):
			rock.reset_rock()

func _on_rock_revealed(safe: bool) -> void:
	if state != State.ACTIVE:
		return
	if not safe:
		fail()

func _on_goal_entered(body: Node) -> void:
	if body.is_in_group("player") or body is CharacterBody2D:
		complete()

func _on_failed() -> void:
	if auto_reset:
		reset.call_deferred()
