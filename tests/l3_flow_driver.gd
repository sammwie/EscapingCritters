extends Node
## Headless playthrough of Level 3. Run: godot --headless --path . res://tests/l3_flow_test.tscn

var fails := 0

func check(cond: bool, msg: String) -> void:
	print(("PASS  " if cond else "FAIL  ") + msg)
	if not cond:
		fails += 1

func _ready() -> void:
	# Survive scene changes.
	get_parent().remove_child.call_deferred(self)
	get_tree().root.add_child.call_deferred(self)
	_run.call_deferred()

func wait(sec: float) -> void:
	var end := Time.get_ticks_msec() + int(sec * 1000)
	while Time.get_ticks_msec() < end:
		if Dialogue.active:
			Dialogue.request_advance()
		await get_tree().create_timer(0.15).timeout

func scene_path() -> String:
	return get_tree().current_scene.scene_file_path if get_tree().current_scene else ""

func player() -> Node2D:
	return get_tree().get_first_node_in_group("player")

func _run() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	Level1Quest.stage = Level1Quest.Stage.DONE
	Level2Quest.stage = Level2Quest.Stage.DONE
	Level2Quest._begun = true
	GameState.current_level = 3
	get_tree().root.set_meta("intro_played", true)
	get_tree().root.set_meta("spawn_at", "Spawn_inside")
	get_tree().change_scene_to_file("res://scenes/interiors/house_interior.tscn")
	await wait(1.0)
	check(Level3Quest.stage == Level3Quest.Stage.GO_TO_BED, "note read -> task: go to bed")
	check(get_tree().get_nodes_in_group("task_popup").size() == 0, "popup waits for L2 banner")
	var l2 := get_tree().current_scene.get_node_or_null("Level2Quest")
	await wait(0.5)
	check(l2 != null and not l2._panel.visible, "level 2 task list hidden")

	var l3panel := get_tree().current_scene.get_node("Level3Quest")
	await wait(5.5)
	check(Level3Quest.announced == Level3Quest.Stage.GO_TO_BED and l3panel._task_labels[0].visible, "bed task pops up and joins the list together")
	var day_before := GameState.current_day
	get_tree().current_scene.get_node("Bed").interact(player())
	# Sleep fade + day card take ~3.2s; check the list right after waking,
	# before the "ask the Baker" pop-up has come in.
	await get_tree().create_timer(3.6).timeout
	check(Level3Quest.stage == Level3Quest.Stage.ASK_BAKER and not l3panel._task_labels[1].visible, "new task not in the list before its pop-up")
	await wait(5.4)
	check(Level3Quest.stage == Level3Quest.Stage.ASK_BAKER, "slept -> ask baker")
	check(l3panel._task_labels[1].visible and Level3Quest.announced == Level3Quest.Stage.ASK_BAKER, "task list updates with the pop-up")
	var day_now := GameState.current_day
	get_tree().current_scene.get_node("Bed").interact(player())
	await get_tree().create_timer(0.3).timeout
	check(Dialogue.active and not get_tree().current_scene.get_node("Bed")._sleeping, "can't go back to sleep after waking")
	await wait(1.0)
	check(GameState.current_day == day_now and Level3Quest.stage == Level3Quest.Stage.ASK_BAKER, "day and task unchanged")
	check(StoryInteractable.get_story_flag("cat_dead"), "cat died overnight")
	check(GameState.get_flag("note_read") and GameState.get_flag("cat_dead"), "GameState flags note_read + cat_dead set")
	check(GameState.current_day == day_before + 1, "day advanced once")
	check(player().is_physics_processing(), "player can move after waking")

	get_tree().current_scene.get_node("ExitDoor").interact(player())
	await wait(5.0)
	check(scene_path() == StoryRouter.VILLAGE_DAY3, "house exit -> day 3 map (%s)" % scene_path())
	check(get_tree().current_scene.get_node_or_null("StoryTint") != null, "day 3 tint applied")
	var cat := get_tree().current_scene.get_node("Mochi")
	check(not cat.enabled, "mochi can't be petted")
	check(cat.get_node("CatStory").enabled, "mochi 'Look' available")
	check(player().global_position.distance_to(get_tree().current_scene.get_node("Doors/Spawn_house_outside").global_position) < 2.0, "spawned outside house")
	check(get_tree().current_scene.get_node_or_null("CorruptionScreen") != null, "day 3 pixelation on")
	var q := get_tree().current_scene.get_node("Level3Quest")
	check(q._crowd.size() >= 5, "onlookers out (%d)" % q._crowd.size())
	check(q._crowd_mode == q.CrowdMode.STARE, "onlookers just stare at first")
	var talk_to: Node = q._crowd[0]
	talk_to.interact(player())
	check(Dialogue.active, "onlooker gives a cold line")
	await wait(1.0)
	q._hostile_t = q.STALK_AT - 0.1
	await wait(1.5)
	check(q._crowd_mode == q.CrowdMode.STALK, "after a while they start following")
	q._hostile_t = q.CLOSE_AT - 0.1
	await wait(1.0)
	check(q._crowd_mode == q.CrowdMode.CLOSE, "then they crowd closer")
	check(not talk_to.enabled, "and stop answering")
	var sprite := (q._crowd[2] as Node).get_node_or_null("Sprite2D")
	check(sprite != null and sprite.material is ShaderMaterial, "villagers use corrupt shader")

	var baker2d := get_tree().current_scene.get_node("Baker/Baker2D")
	baker2d.interact(player())
	await wait(6.0)
	check(Level3Quest.stage == Level3Quest.Stage.RUN_HOME, "baker confronted -> run home")
	var l3 := get_tree().current_scene.get_node("Level3Quest")
	check(l3._crowd.size() >= 9, "villagers surround (%d)" % l3._crowd.size())
	await wait(4.0)
	var close := 0
	for v in l3._crowd:
		if is_instance_valid(v) and v.global_position.distance_to(player().global_position) < 50:
			close += 1
	check(close >= 4, "villagers closed in around player (%d close)" % close)
	check(player().is_physics_processing(), "player still free to run")

	get_tree().current_scene.get_node("Doors/HouseDoor").interact(player())
	await wait(11.0)
	check(scene_path() == "res://scenes/interiors/house_interior.tscn", "ran home")
	check(Level3Quest.stage == Level3Quest.Stage.SNEAK, "auto nightfall -> sneak")
	check(get_tree().current_scene.get_node_or_null("StoryTint") != null, "house is night-tinted")
	check(GameState.is_night, "GameState.is_night on")
	check(player().is_physics_processing(), "player unfrozen after nightfall")
	var night_day := GameState.current_day
	get_tree().current_scene.get_node("Bed").interact(player())
	await get_tree().create_timer(0.3).timeout
	check(Dialogue.active and not get_tree().current_scene.get_node("Bed")._sleeping, "can't sleep before sneaking out")
	await wait(1.0)
	check(GameState.current_day == night_day and Level3Quest.stage == Level3Quest.Stage.SNEAK, "still night, still sneak task")
	var hl := get_tree().current_scene.get_node("Level3Quest")
	check(hl._task_labels[3].visible, "sneak task in the list")

	get_tree().current_scene.get_node("ExitDoor").interact(player())
	await wait(1.5)
	check(scene_path() == StoryRouter.VILLAGE_NIGHT, "house exit -> night map (%s)" % scene_path())
	var night := get_tree().current_scene
	check(night.get_node_or_null("Baker") == null or night.get_node("Baker").is_queued_for_deletion(), "day npcs cleared")
	check(night.get_node("Doors/BakeryDoor").locked and night.get_node("Doors/CoopDoor").locked, "other doors locked at night")
	check(night.get_node("CorruptionScreen").get_index() < night.get_node("DialogueBox").get_index(), "pixelation drawn under the dialogue box")
	var hp := night.get_node("HidingPuzzle")
	check(hp.state == Puzzle.State.ACTIVE, "hiding puzzle running")
	# get caught once: stand in front of a guard
	var g: Node2D = night.get_node("NightGuards/Guard1")
	player().global_position = g.global_position + g.facing * 30
	await wait(3.5)
	check(player().global_position.distance_to(night.get_node("NightStart").global_position) < 2.0, "caught -> back to start")
	var watcher: Node2D = night.get_node("KnowsAllWatcher")
	player().global_position = watcher.global_position + Vector2(0, -150)
	await get_tree().create_timer(0.3).timeout
	check(watcher._seen, "knows all noticed from a distance")
	check(Dialogue.active, "player reacts to it")
	var any_active := false
	for gg in get_tree().get_nodes_in_group("patrol_guard"):
		any_active = any_active or gg._active
	check(not any_active, "guards pause while you look")
	await wait(2.0)
	check(is_instance_valid(watcher), "it never approaches or leaves on its own")
	player().global_position = night.get_node("PondEntrance").global_position
	await wait(2.5)
	check(scene_path() == StoryRouter.POND, "reached pond (%s)" % scene_path())
	check(Level3Quest.stage == Level3Quest.Stage.POND, "stage pond")
	check(GameState.get_flag("hid_from_villagers"), "GameState hid_from_villagers set")

	var pp := get_tree().current_scene.get_node("PuddlePuzzle")
	pp._on_goal_entered(player())
	await wait(6.0)
	check(scene_path() == StoryRouter.KNOWS_ALL, "rigged pond loss -> knows all (%s)" % scene_path())
	check(Level3Quest.stage == Level3Quest.Stage.KNOWS_ALL, "stage knows all")
	check(GameState.get_flag("pond_lost"), "GameState pond_lost set")
	check(GameState.get_flag("baker_confronted"), "GameState baker_confronted set")
	print("DONE fails=%d" % fails)
	get_tree().quit(fails)
