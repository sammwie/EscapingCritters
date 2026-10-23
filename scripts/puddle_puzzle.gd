class_name PuddlePuzzle
extends Puzzle
## Puddle puzzle: jump (Space or Shift) across rocks to reach the goal. Hold a
## direction to aim: a white ring shows which rock the jump will hit. While
## standing on a safe rock the player can't walk, only hop.
## Add LyingObject (or Rock) children under `rocks_parent`, and point `goal`
## at an Area2D on the far side (its collision mask must include layer 3,
## the player). `water` is a Control (ColorRect) covering the pond: being in
## it without standing on a safe rock sinks the player.
## Safe rocks are random each time the level loads (randomize_each_visit),
## but stay fixed while the player retries, so the path can be learned.
## Rocks are grouped into columns by x position (column_width), and every
## column is guaranteed at least one safe rock. A failure sends the player
## back to the start and restarts the puzzle.
## The player is kept inside `play_area` (match it to your Ground rectangle).
## A small instruction box (instructions_text) explains the controls and
## fades out once the puzzle is solved.
## Reaching the goal flickers the glitch overlay (group "glitch_overlay", if
## the scene has one) and shows `ending_text` for a moment (placeholder).
##
## STORY MODE: tick `rigged_to_lose` and the puzzle plays normally, but when
## the player reaches the far bank they lose anyway: the puzzle is reported
## complete, the player sinks, the glitch overlay flickers, the screen fades
## to black, and `lose_scene_path` (the Knows All map) loads. Until that scene
## exists it shows a placeholder message and reloads the level for testing.
## If GameState has set_flag(), it is called as set_flag("pond_lost", true).

@export var rocks_parent: Node
@export var goal: Area2D
@export var water: Control
@export var play_area := Rect2(-100, 100, 1000, 400)  # player can't leave this
@export var safe_ratio := 0.5
@export var auto_reset := true
@export var restart_delay := 1.0
@export var jump_range := 160.0      # how far the player can jump
@export var standing_radius := 20.0  # how close to a safe rock counts as "on" it
@export var goal_hop_time := 0.4
@export var column_width := 60.0     # rocks within this x-distance share a column
@export var randomize_each_visit := true       # new layout each time the level loads
@export var reshuffle_every_attempt := false   # re-roll after every sinking (kills memorizing)
@export var ending_text := "You made it across."
@export var ending_flicker := true
@export var ending_show_time := 3.0
@export var show_instructions := true
@export_multiline var instructions_text := "HOW TO CROSS\nArrow keys: aim at a stone\nSpace / Shift: jump to it\nWrong stones and water sink you\nReach the far bank to finish"
@export_group("Story mode")
@export var rigged_to_lose := false   # reach the far bank, then sink and lose anyway
@export_file("*.tscn") var lose_scene_path := ""   # the Knows All map
@export var glitch_time := 1.6      
@export var fade_time := 1.2        
@export var sink_at_bank := false  

var _rocks: Array[LyingObject] = []
var _player: Node2D
var _player_start := Vector2.ZERO
var _player_modulate := Color.WHITE
var _seed := 0
var _hint_layer: CanvasLayer
var _losing := false

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
	if show_instructions:
		_build_instructions()

func _find_player() -> Node2D:
	var p := get_tree().get_first_node_in_group("player")
	if p == null:
		for n in get_tree().current_scene.find_children("*", "CharacterBody2D", true, false):
			return n as Node2D
	return p as Node2D

# --- Instruction box ---------------------------------------------------

func _build_instructions() -> void:
	_hint_layer = CanvasLayer.new()
	_hint_layer.layer = 40
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.08, 0.06, 0.80)
	style.border_color = Color("c9a56a")
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = instructions_text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color("f3e9d2"))
	panel.add_child(label)
	panel.position = Vector2(12, 12)
	_hint_layer.add_child(panel)
	add_child(_hint_layer)

func _hide_instructions() -> void:
	if _hint_layer == null:
		return
	var panel := _hint_layer.get_child(0)
	var tw := create_tween()
	tw.tween_property(panel, "modulate:a", 0.0, 0.6)
	tw.tween_callback(_hint_layer.queue_free)
	_hint_layer = null

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

func _goal_in_reach() -> bool:
	return goal != null and _player.global_position.distance_to(goal.global_position) <= jump_range

# The rock a jump would hit right now, given the held direction (or null).
func _find_target(dir: Vector2) -> Rock:
	var ppos := _player.global_position
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
	return best

func _try_jump() -> bool:
	# The goal wins whenever it is within reach.
	if _goal_in_reach():
		_hop_to_goal()
		return true
	var target := _find_target(_input_dir())
	if target:
		target.jump_test(_player)
		return true
	return false

func _set_target(target: Rock) -> void:
	for r in _rocks:
		var rock := r as Rock
		if rock:
			rock.targeted = (rock == target)

func _hop_to_goal() -> void:
	var player := _player
	var from := player.global_position
	var to := goal.global_position
	_set_target(null)
	player.set_meta("hopping", true)
	player.set_physics_process(false)
	var tw := create_tween()
	tw.tween_method(_goal_hop_step.bind(player, from, to), 0.0, 1.0, goal_hop_time)
	await tw.finished
	if _losing:
		return  # story mode: the sinking sequence has taken over
	player.set_physics_process(true)
	player.set_meta("hopping", false)

func _goal_hop_step(t: float, player: Node2D, from: Vector2, to: Vector2) -> void:
	player.global_position = from.lerp(to, t) + Vector2(0, -sin(t * PI) * 22.0)

# --- Aiming, water, boundaries -----------------------------------------

func _physics_process(_delta: float) -> void:
	if _player == null or _losing:
		return
	# Keep the player inside the play area (not while hopping or sinking).
	if play_area.has_area() and not _player.get_meta("hopping", false):
		_player.global_position = _player.global_position.clamp(play_area.position, play_area.end)
	if state != State.ACTIVE or _player.get_meta("hopping", false):
		_set_target(null)
		return
	# Show which rock a jump would hit.
	_set_target(null if _goal_in_reach() else _find_target(_input_dir()))
	if water == null:
		return
	var pond := Rect2(water.global_position, water.size)
	if not pond.has_point(_player.global_position):
		return
	if _standing_on_safe_rock():
		_player.set_physics_process(false)  # locked on the rock: only hopping moves
		return
	_sink_player()

func _standing_on_safe_rock() -> bool:
	for r in _rocks:
		var rock := r as Rock
		if rock and rock.tested and rock.is_safe \
				and _player.global_position.distance_to(rock.global_position) <= standing_radius:
			return true
	return false

func _sink_player() -> void:
	_set_target(null)
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
		if state == State.ACTIVE:
			_hide_instructions()
			if rigged_to_lose:
				complete()          # the puzzle counts as solved...
				_lose_sequence()    # ...and then the player loses anyway
				return
			_play_ending()
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

# --- Story mode: reach the far bank, then lose anyway -------------------

func _lose_sequence() -> void:
	if _losing:
		return
	_losing = true
	_set_target(null)
	if _player:
		_player.set_physics_process(false)  # no more moving
		_player.set_meta("hopping", true)
		if sink_at_bank:
			create_tween().tween_property(_player, "modulate:a", 0.0, glitch_time * 0.6)
	# The glitch builds up...
	get_tree().call_group("glitch_overlay", "turn_on", glitch_time)
	await get_tree().create_timer(glitch_time * 0.5).timeout
	# ...and the screen fades to black while it keeps going.
	var layer := CanvasLayer.new()
	layer.layer = 100
	var fade := ColorRect.new()
	fade.color = Color.BLACK
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.modulate.a = 0.0
	layer.add_child(fade)
	get_tree().current_scene.add_child(layer)
	var tw := create_tween()
	tw.tween_property(fade, "modulate:a", 1.0, fade_time)
	await tw.finished
	if GameState.has_method("set_flag"):
		GameState.set_flag("pond_lost", true)
	if lose_scene_path != "" and ResourceLoader.exists(lose_scene_path):
		get_tree().change_scene_to_file(lose_scene_path)
		return
	# No Knows All map yet: show a placeholder, then reload the level for testing.
	push_warning("PuddlePuzzle: lose_scene_path is empty or missing, so the Knows All map was not loaded.")
	_show_message("[Knows All map goes here]")
	await get_tree().create_timer(2.5).timeout
	get_tree().reload_current_scene()

# --- Ending (placeholder until the designers decide) -------------------

func _play_ending() -> void:
	if ending_flicker:
		get_tree().call_group("glitch_overlay", "flicker")
	if ending_text != "":
		_show_message(ending_text)

func _show_message(text: String) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 120
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 8)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	label.position.y = 60
	label.modulate.a = 0.0
	layer.add_child(label)
	get_tree().current_scene.add_child(layer)
	var tw := create_tween()
	tw.tween_property(label, "modulate:a", 1.0, 0.4)
	tw.tween_interval(ending_show_time)
	tw.tween_property(label, "modulate:a", 0.0, 0.8)
	tw.tween_callback(layer.queue_free)
