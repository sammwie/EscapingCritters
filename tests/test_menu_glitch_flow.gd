extends SceneTree
## Exercise the F5 entry scene and actual New Game button at the user's window size.

var failures: Array[String] = []
var gs


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _capture(path: String) -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(path)
	return image


func _run() -> void:
	gs = root.get_node("GameState")
	root.size = Vector2i(1152, 648)
	DirAccess.make_dir_recursive_absolute("res://.godot/glitch_checks")
	# Enter the configured project start scene, rather than starting at the demo.
	var start_scene = load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	# Keep the actual splash transition, with shorter waits for this test.
	start_scene.fade_in_time = 0.01
	start_scene.hold_time = 0.01
	start_scene.fade_out_time = 0.01
	root.add_child(start_scene)
	current_scene = start_scene
	for frame in 240:
		await process_frame
		if current_scene != null and current_scene.name == "MainMenu":
			break
	_check(current_scene != null and current_scene.name == "MainMenu", "F5 splash reaches MainMenu")
	if current_scene == null or current_scene.name != "MainMenu":
		quit(1)
		return
	var menu = current_scene
	await process_frame
	await process_frame
	var menu_image: Image = await _capture("res://.godot/glitch_checks/menu_1152.png")
	_check(menu_image.get_size() == Vector2i(1152, 648), "Render at the user's 1152x648 window size")
	var visible_area := Rect2(Vector2.ZERO, root.get_visible_rect().size)
	for button in menu.get_node("ButtonList").get_children():
		_check(visible_area.encloses(button.get_global_rect()), "%s fits inside the menu viewport" % button.name)
	_check(visible_area.encloses(menu.get_node("Label").get_global_rect()), "Menu title fits inside the viewport")
	_check(not menu.get_node("Label").get_global_rect().intersects(menu.get_node("ButtonList/NewGameButton").get_global_rect()), "Title does not overlap New Game")

	gs.current_day = 4
	gs.mark_solved("farm_eggs")
	# Emit the real button signal to test the connection established in _ready().
	menu.get_node("ButtonList/NewGameButton").pressed.emit()
	for frame in 5:
		await process_frame
	_check(current_scene != null and current_scene.name == "FirstGlitchDemo", "New Game enters the glitch demo")
	if current_scene == null or current_scene.name != "FirstGlitchDemo":
		quit(1)
		return
	_check(gs.current_day == 1 and gs.corruption_stage == 0 and gs.solved_puzzles.is_empty(), "New Game clears previous progress")
	var demo = current_scene
	_check(demo.get_node("TownBackdrop").texture.resource_path == "res://art/escaping_critters_main_menu_bg.png", "Use the supplied town artwork")
	_check(not demo.get_node("EggTest/Player/Sprite2D").visible, "Hide the inherited Godot placeholder in this demo only")
	var critter = demo.get_node("EggTest/Player/CritterArt")
	_check(critter.sprite_frames.get_frame_count("walk_east") == 8, "Use the supplied critter walking frames")
	_check(critter.sprite_frames.get_frame_texture("idle_south", 0).resource_path == "res://art/critter/rotations/south.png", "Use the supplied critter idle artwork")
	for villager_name in ["Baker", "Butcher", "Neighbor", "Neighbor2"]:
		_check(demo.get_node("Villagers/" + villager_name + "/Sprite2D").texture.resource_path != "res://icon.svg", "Use team art for " + villager_name)
	var player = demo.get_node("EggTest/Player")
	var start_position: Vector2 = player.position
	Input.action_press("move_right")
	for frame in 5:
		await physics_frame
	await process_frame
	_check(player.position.x > start_position.x, "The original player movement still runs")
	_check(critter.animation == "walk_east" and critter.is_playing(), "Movement plays the matching team walking animation")
	Input.action_release("move_right")
	await physics_frame
	await physics_frame
	await process_frame
	_check(critter.animation == "idle_east", "Stopping uses the matching team idle pose")
	var normal: Image = await _capture("res://.godot/glitch_checks/demo_1152_normal.png")
	for egg in demo.get_node("EggTest/EggPuzzle").get_children():
		if egg.is_safe:
			# Exercise real overlap detection, nearest-target selection, and E input.
			player.position = egg.position + Vector2(-30, 0)
			await physics_frame
			await physics_frame
			await process_frame
			await process_frame
			_check(player.get_node("Interactor").current_target == egg, "The real interactor selects " + egg.name)
			var take := InputEventKey.new()
			take.keycode = KEY_E
			take.physical_keycode = KEY_E
			take.pressed = true
			Input.parse_input_event(take)
			await process_frame
			take.pressed = false
			Input.parse_input_event(take)
			_check(egg.opened and not egg.visible, "E collects and hides the real egg " + egg.name)
	var faded: Image = await _capture("res://.godot/glitch_checks/demo_1152_glitch.png")
	_check(gs.is_solved("farm_eggs") and gs.corruption_stage == 1, "Farm puzzle completion triggers the effect from New Game")
	# CanvasItems scales the 1920x1080 world by 0.6 into this window.
	var sample := Vector2i(120, 600)
	_check(normal.get_pixelv(sample).s - faded.get_pixelv(sample).s > 0.2, "Glitch visibly reduces saturation at 1152x648")
	var restart := InputEventKey.new()
	restart.keycode = KEY_R
	restart.pressed = true
	demo._unhandled_key_input(restart)
	for frame in 5:
		await process_frame
	var reset_image: Image = await _capture("res://.godot/glitch_checks/demo_1152_reset.png")
	_check(gs.corruption_stage == 0 and gs.solved_puzzles.is_empty(), "Restart clears corruption and solved puzzles")
	_check(normal.get_pixelv(sample).is_equal_approx(reset_image.get_pixelv(sample)), "Restart restores the rendered color")
	# Reuse the existing dialogue resource and NPC behavior with the new presentation.
	var baker = current_scene.get_node("Villagers/Baker")
	baker.interact(current_scene.get_node("EggTest/Player"))
	_check(root.get_node("Dialogue").active and baker.frozen, "Existing baker dialogue still starts and freezes its actor")
	_check(current_scene.get_node("DialogueBox/PanelContainer").visible, "Existing dialogue UI is integrated")
	root.get_node("Dialogue").request_advance() # reveal the existing typewriter text
	await _capture("res://.godot/glitch_checks/demo_1152_dialogue.png")
	while root.get_node("Dialogue").active:
		root.get_node("Dialogue").advance()
	_check(not baker.frozen, "Existing dialogue unfreezes the baker")
	current_scene.free()
	current_scene = null
	print("PASS: F5 splash, menu layout at 1152x648, New Game, real puzzle completion, visible glitch, and restart" if failures.is_empty() else "FAIL: %d checks" % failures.size())
	quit(0 if failures.is_empty() else 1)
