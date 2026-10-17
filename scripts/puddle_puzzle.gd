class_name PuddlePuzzle
extends Puzzle
## Puddle puzzle: jump (Space or Shift) across rocks to reach the goal. Hold a
## direction while jumping to choose which rock to hop to.
## Add LyingObject (or Rock) children under `rocks_parent`, and point `goal`
## at an Area2D on the far side (its collision mask must include layer 3,
## the player). `water` is a Control (ColorRect) covering the pond: being in
## it without standing on a safe rock sinks the player.
## Safe rocks are random each time the level loads (randomize_each_visit),
## but stay fixed while the player retries, so the path can be learned.
## Rocks are grouped into columns by x position (column_width), and every
## column is guaranteed at least one safe rock. A failure sends the player
## back to the start and restarts the puzzle.

@export var rocks_parent: Node
@export var goal: Area2D
@export var water: Control
@export var safe_ratio := 0.5
@export var auto_reset := true
@export var restart_delay := 1.0
@export var jump_range := 160.0      # how far the player can jump
@export var standing_radius := 20.0  # how close to a safe rock counts as "on" it
@export var goal_hop_time := 0.4
@export var column_width := 60.0     # rocks within this x-distance share a column
@export var randomize_each_visit := true       # new layout each time the level loads
@export var reshuffle_every_attempt := false   # re-roll after every sinking (kills memorizing)

var _rocks: Array[LyingObject] = []
var _player: Node2D
var _player_start := Vector2.ZERO
var _player_modulate := Color.WHITE
var _seed := 0

func _ready() -> void:
	if puzzle_id == &"":
		puzzle_id = &"puddle"
	_seed = randi() if randomize_each_visit else GameState.puzzle_seed
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

# --- Jumping -----------------------------------------------------------

func _is_jump_event(event: InputEvent) -> bool:
	if event.is_action_pressed("ui_accept") and not event.is_echo():
		return true  # Space / Enter
	var key := event as InputEventKey
	return key != null and key.pressed and not key.echo and key.keycode == KEY_SHIFT

func _unhandled_input(event: InputEvent) -> void:
	if not _is_jump_event(event):
		return
	if state != State.ACTIVE or _player == null:
		return
	if _player.get_meta("hopping", false):
		return
	if _try_jump():
		get_viewport().set_input_as_handled()

func _input_dir() -> Vector2:
	var v := Vector2.ZERO
	for keys in [["ui_left", "ui_right", "ui_up", "ui_down"],
			["move_left", "move_right", "move_up", "move_down"]]:
		var ok := true
		for k in keys:
			if not InputMap.has_action(k):
				ok = false
		if ok:
			v += Input.get_vector(keys[0], keys[1], keys[2], keys[3])
	return v.limit_length(1.0)

func _try_jump() -> bool:
	var ppos := _player.global_position
	# The goal wins whenever it is within reach.
	if goal and ppos.distance_to(goal.global_position) <= jump_range:
		_hop_to_goal()
		return true
	var dir := _input_dir()
	var best: Rock = null
	var best_score := -INF
	for r in _rocks:
		var rock := r as Rock
		if rock == null or rock.tested:
			continue
		var to := rock.global_position - ppos
		var d := to.length()
		if d > jump_range:
			continue
		var score := -d
		if dir != Vector2.ZERO:
			var align := dir.normalized().dot(to.normalized())
			if align < 0.3:
				continue
			score = align * 1000.0 - d
		if score > best_score:
			best_score = score
			best = rock
	if best:
		best.jump_test(_player)
		return true
	return false

func _hop_to_goal() -> void:
	var player := _player
	var from := player.global_position
	var to := goal.global_position
	player.set_meta("hopping", true)
	player.set_physics_process(false)
	var tw := create_tween()
	tw.tween_method(_goal_hop_step.bind(player, from, to), 0.0, 1.0, goal_hop_time)
	await tw.finished
	player.set_physics_process(true)
	player.set_meta("hopping", false)

func _goal_hop_step(t: float, player: Node2D, from: Vector2, to: Vector2) -> void:
	player.global_position = from.lerp(to, t) + Vector2(0, -sin(t * PI) * 22.0)

# --- Water -------------------------------------------------------------

func _physics_process(_delta: float) -> void:
	if state != State.ACTIVE or _player == null or water == null:
		return
	if _player.get_meta("hopping", false):
		return
	var pond := Rect2(water.global_position, water.size)
	if not pond.has_point(_player.global_position):
		return
	for r in _rocks:
		var rock := r as Rock
		if rock and rock.tested and rock.is_safe \
				and _player.global_position.distance_to(rock.global_position) <= standing_radius:
			return  # standing on a safe rock
	_sink_player()

func _sink_player() -> void:
	_player.set_physics_process(false)
	_player.set_meta("hopping", true)
	create_tween().tween_property(_player, "modulate:a", 0.0, 0.3)
	fail()

# --- Puzzle setup / flow ----------------------------------------------

func _on_start() -> void:
	_rocks.clear()
	if rocks_parent == null:
		push_warning("PuddlePuzzle '%s' has no rocks_parent." % name)
		return
	for child in rocks_parent.get_children():
		if child is LyingObject:
			_rocks.append(child)
	for rock in _rocks:
		if not rock.revealed.is_connected(_on_rock_revealed):
			rock.revealed.connect(_on_rock_revealed)
	_assign_rocks()

# Decides which rocks are safe from _seed (same seed = same rocks).
func _assign_rocks() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	for rock in _rocks:
		rock.is_safe = rng.randf() < safe_ratio
	_guarantee_a_path(rng)

# Rocks are grouped into columns left to right by x position, and every
# column gets at least one safe rock, so the pond can always be crossed.
func _guarantee_a_path(rng: RandomNumberGenerator) -> void:
	if _rocks.is_empty():
		return
	var min_x := INF
	for rock in _rocks:
		min_x = minf(min_x, rock.global_position.x)
	var columns := {}
	for rock in _rocks:
		var key := floori((rock.global_position.x - min_x + column_width * 0.33) / column_width)
		if not columns.has(key):
			columns[key] = []
		columns[key].append(rock)
	for key in columns:
		var group: Array = columns[key]
		var any_safe := false
		for rock in group:
			if rock.is_safe:
				any_safe = true
		if not any_safe:
			group[rng.randi() % group.size()].is_safe = true

func _on_reset() -> void:
	if reshuffle_every_attempt:
		_seed = randi()
		_assign_rocks()
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
