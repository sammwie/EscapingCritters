extends SceneTree
## Run with --headless --path . --script res://tests/test_first_glitch.gd.
## For pixel verification use a rendering driver and append -- --render-check.

var failures: Array[String] = []
var solved_events: Array[String] = []
var day_events: Array[int] = []
var corruption_events: Array[int] = []
var gs


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _run() -> void:
	gs = root.get_node_or_null("GameState")
	_check(gs != null, "GameState must exist as the actual project autoload")
	if gs == null:
		quit(1)
		return
	gs.new_playthrough()
	gs.puzzle_solved.connect(func(id: String): solved_events.append(id))
	gs.day_changed.connect(func(day: int): day_events.append(day))
	gs.corruption_changed.connect(func(stage: int): corruption_events.append(stage))
	_check(gs.current_day == 1 and gs.corruption_stage == 0, "Fresh state: day 1, stage 0")
	_check(gs.solved_puzzles.is_empty(), "Fresh state: no solved puzzles")
	gs.advance_day()
	_check(gs.current_day == 2 and day_events == [2], "Advance day and emit exactly once")
	gs.mark_solved("")
	_check(gs.solved_puzzles.is_empty(), "Ignore an empty puzzle ID")
	gs.mark_solved("puddle")
	gs.mark_solved("puddle")
	_check(gs.is_solved("puddle") and gs.solved_puzzles.size() == 1, "Record each puzzle once")
	_check(solved_events == ["puddle"], "Emit puzzle_solved only once for duplicate completions")
	_check(gs.corruption_stage == 0, "Other puzzle IDs do not trigger the farm effect")
	gs.set_corruption_stage(3)
	gs.mark_solved("farm_eggs")
	_check(gs.corruption_stage == 3, "Farm completion cannot reduce later corruption")
	gs.current_level = 5
	gs.new_playthrough()
	_check(gs.current_day == 1 and gs.current_level == 1, "Reset level and day")
	_check(gs.corruption_stage == 0 and gs.solved_puzzles.is_empty(), "Reset corruption and progress")
	_check(corruption_events.back() == 0, "Reset emits stage 0 to listeners")
	gs.set_corruption_stage(-1)
	_check(gs.corruption_stage == 0, "Clamp negative corruption to zero")

	# Exercise Coder 2's real FarmManager and FarmPlot, not copies of the day logic.
	var farm = load("res://scenes/farm.tscn").instantiate()
	root.add_child(farm)
	await process_frame
	await process_frame
	var plot = farm.get_node("FarmPlot")
	plot.interact(null) # plant
	plot.interact(null) # water
	farm.get_node("FarmManager").end_day()
	_check(gs.current_day == 2 and plot.growth == 1, "Farm day cycle advances state and crops once")
	farm.free()
	gs.new_playthrough()

	var effect = load("res://scenes/corruption_effect.tscn").instantiate()
	root.add_child(effect)
	_check(not effect.get_node("Overlay").visible, "Stage 0 hides the effect")
	_check(effect.get_node("Overlay").mouse_filter == Control.MOUSE_FILTER_IGNORE, "Effect does not block clicks")

	# Solve through actual egg interactions and the shared Puzzle reporting path.
	var eggs = load("res://scenes/egg_test.tscn").instantiate()
	root.add_child(eggs)
	await process_frame
	var puzzle = eggs.get_node("EggPuzzle")
	for egg in puzzle.get_children():
		if egg.is_safe:
			egg.interact(eggs.get_node("Player"))
	_check(gs.is_solved("farm_eggs"), "Real egg interactions record the farm puzzle")
	_check(gs.corruption_stage == 1, "Solving the farm raises corruption to 1")
	_check(effect.get_node("Overlay").visible, "Existing effect responds to corruption_changed")
	_check(eggs.get_node("CorruptionEffect/Overlay").visible, "Egg scene contains a working effect")
	eggs.free()
	effect.free()

	# Loaded saves / scene changes must apply existing state without a fresh signal.
	effect = load("res://scenes/corruption_effect.tscn").instantiate()
	root.add_child(effect)
	_check(effect.get_node("Overlay").visible, "Effect loaded at stage 1 applies current state")
	gs.new_playthrough()
	_check(not effect.get_node("Overlay").visible, "New playthrough restores normal color")
	effect.free()

	eggs = load("res://scenes/egg_test.tscn").instantiate()
	root.add_child(eggs)
	await process_frame
	puzzle = eggs.get_node("EggPuzzle")
	for egg in puzzle.get_children():
		if not egg.is_safe:
			egg.interact(null)
			break
	_check(not gs.is_solved("farm_eggs") and gs.corruption_stage == 0, "A failed egg puzzle cannot trigger corruption")
	eggs.free()

	# The demo explicitly starts fresh; only its HUD sits above the effect layer.
	gs.set_corruption_stage(1)
	var demo = load("res://scenes/first_glitch_demo.tscn").instantiate()
	root.add_child(demo)
	current_scene = demo
	await process_frame
	_check(gs.corruption_stage == 0, "Starting the demo resets a prior playthrough")
	if "--render-check" in OS.get_cmdline_user_args():
		await _check_rendering(demo)

	# Drive the demo's actual R input handler and scene reload path.
	gs.mark_solved("farm_eggs")
	var restart := InputEventKey.new()
	restart.keycode = KEY_R
	restart.pressed = true
	demo._unhandled_key_input(restart)
	await process_frame
	await process_frame
	# Reload adds the new scene deferred; let its one-frame prompt setup finish.
	await process_frame
	await process_frame
	_check(gs.corruption_stage == 0 and gs.solved_puzzles.is_empty(), "R reload starts a fresh playthrough")
	_check(not current_scene.get_node("EggTest/CorruptionEffect/Overlay").visible, "R reload restores normal colors")
	current_scene.free()
	current_scene = null
	if failures.is_empty():
		print("PASS: GameState, real day cycle, egg completion/failure, effect startup/reset, and demo restart")
	else:
		print("FAIL: %d checks" % failures.size())
	quit(0 if failures.is_empty() else 1)


func _capture(path: String) -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(path)
	return image


func _check_rendering(demo: Node) -> void:
	DirAccess.make_dir_recursive_absolute("res://.godot/glitch_checks")
	var normal: Image = await _capture("res://.godot/glitch_checks/stage_0.png")
	var puzzle = demo.get_node("EggTest/EggPuzzle")
	for egg in puzzle.get_children():
		if egg.is_safe:
			egg.interact(demo.get_node("EggTest/Player"))
	var faded: Image = await _capture("res://.godot/glitch_checks/stage_1.png")
	gs.new_playthrough()
	var reset_image: Image = await _capture("res://.godot/glitch_checks/reset.png")
	# Sample the supplied town illustration, away from actors and HUD.
	var sample := Vector2i(200, 1000)
	var normal_color := normal.get_pixelv(sample)
	var faded_color := faded.get_pixelv(sample)
	_check(normal_color.s - faded_color.s > 0.2, "Rendered stage 1 visibly reduces saturation")
	_check(normal_color.is_equal_approx(reset_image.get_pixelv(sample)), "Rendered reset restores the original color")
	print("Rendered garden saturation: %.3f -> %.3f; reset %.3f" % [normal_color.s, faded_color.s, reset_image.get_pixelv(sample).s])
