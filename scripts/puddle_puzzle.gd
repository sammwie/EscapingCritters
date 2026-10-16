class_name PuddlePuzzle
extends Puzzle
## Puddle puzzle: jump (Space) onto rocks to find the safe path, then reach
## the goal. Add LyingObject (or Rock) children under `rocks_parent`, and
## point `goal` at an Area2D on the far side (its collision mask must include
## layer 3, the player). Safe path is fixed per playthrough via
## GameState.puzzle_seed. Landing on an unsafe rock fails the puzzle; with
## auto_reset the player goes back to the start and the puzzle restarts with
## the same layout (same seed = same safe rocks).

@export var rocks_parent: Node
@export var goal: Area2D
@export var safe_ratio := 0.5
@export var auto_reset := true
@export var restart_delay := 1.0
@export var jump_range := 140.0  # how far the player can jump

var _rocks: Array[LyingObject] = []
var _player: Node2D
var _player_start := Vector2.ZERO
var _player_modulate := Color.WHITE

func _ready() -> void:
	if puzzle_id == &"":
		puzzle_id = &"puddle"
	_player = _find_player()
	if _player:
		_player_start = _player.global_position
		_player_modulate = _player.modulate
	if goal and not goal.body_entered.is_connected(_on_goal_entered):
		goal.body_entered.connect(_on_goal_entered)
	failed.connect(_on_failed)
	start()

func _find_player() -> Node2D:
	var p := get_tree().get_first_node_in_group("player")
	if p == null:
		for n in get_tree().current_scene.find_children("*", "CharacterBody2D", true, false):
			return n as Node2D
	return p as Node2D

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_accept") or event.is_echo():
		return
	if state != State.ACTIVE or _player == null:
		return
	if _player.get_meta("hopping", false):
		return
	var rock := _nearest_untested_rock()
	if rock:
		get_viewport().set_input_as_handled()
		rock.jump_test(_player)

func _nearest_untested_rock() -> Rock:
	var best: Rock = null
	var best_dist := jump_range
	for r in _rocks:
		if r is Rock and not r.tested:
			var d := _player.global_position.distance_to(r.global_position)
			if d <= best_dist:
				best_dist = d
				best = r
	return best

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
	if not auto_reset:
		return
	await get_tree().create_timer(restart_delay).timeout
	_respawn_player()
	reset()

func _respawn_player() -> void:
	if _player == null:
		return
	_player.global_position = _player_start
	_player.modulate = _player_modulate
	_player.set_physics_process(true)
	_player.set_meta("hopping", false)
