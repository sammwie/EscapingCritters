extends Node
## Checks the new village map: picture swap, doors, spawns, walkable routes,
## the coop (feeding and eggs), and the Level 2 arena.
## Run: godot --headless --path . res://tests/map_test.tscn

var fails := 0

func check(cond: bool, msg: String) -> void:
	print(("PASS  " if cond else "FAIL  ") + msg)
	if not cond:
		fails += 1

func _ready() -> void:
	get_parent().remove_child.call_deferred(self)
	get_tree().root.add_child.call_deferred(self)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()

func wait(sec: float) -> void:
	var end := Time.get_ticks_msec() + int(sec * 1000)
	while Time.get_ticks_msec() < end:
		if Dialogue.active:
			Dialogue.request_advance()
		await get_tree().create_timer(0.1).timeout

func player() -> CharacterBody2D:
	return get_tree().get_first_node_in_group("player")

func scene() -> Node:
	return get_tree().current_scene

func go(path: String, spawn := "") -> void:
	if spawn == "":
		get_tree().root.remove_meta("spawn_at")
	else:
		get_tree().root.set_meta("spawn_at", spawn)
	get_tree().change_scene_to_file(path)
	await wait(0.8)

## Is a player-sized circle free of walls at this point?
func free_at(p: Vector2) -> bool:
	var q := PhysicsShapeQueryParameters2D.new()
	var c := CircleShape2D.new()
	c.radius = 8.0
	q.shape = c
	q.transform = Transform2D(0, p)
	q.collision_mask = 1
	return scene().get_world_2d().direct_space_state.intersect_shape(q, 1).is_empty()

## Grid of reachable points from `start` (4 px steps).
func reachable(start: Vector2) -> Dictionary:
	var seen := {}
	var open := [Vector2i((start / 4.0).round())]
	seen[open[0]] = true
	while not open.is_empty():
		var cell: Vector2i = open.pop_back()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = cell + d
			if seen.has(n) or n.x < 0 or n.y < 0 or n.x > 128 or n.y > 192:
				continue
			if free_at(Vector2(n) * 4.0):
				seen[n] = true
				open.append(n)
	return seen

func can_reach(grid: Dictionary, p: Vector2) -> bool:
	return grid.has(Vector2i((p / 4.0).round()))

func _run() -> void:
	get_tree().root.set_meta("intro_played", true)
	Level1Quest.stage = Level1Quest.Stage.FEED
	await go("res://scenes/test_main.tscn")
	var map := scene().get_node("Map") as VillageMap
	check(map.texture.resource_path.ends_with("level0_map.png"), "Level 1 shows the normal map")
	check((scene().get_node("NormalOnly") as StaticBody2D).collision_layer == 1 and (scene().get_node("CorruptedOnly") as StaticBody2D).collision_layer == 0, "Level 1 collision set")

	# Every spawn is open and everything important is reachable on foot.
	var start := player().global_position
	check(free_at(start), "player start is open")
	var grid := reachable(start)
	print("      reachable cells: %d" % grid.size())
	for s in ["Spawn_house_outside", "Spawn_bakery_outside", "Spawn_townhall_outside", "Spawn_butcher_outside", "Spawn_coop_outside"]:
		var m := scene().get_node("Doors/" + s) as Node2D
		check(free_at(m.global_position) and can_reach(grid, m.global_position), "%s open and reachable" % s)
	for d in ["HouseDoor", "BakeryDoor", "TownhallDoor", "ButcherDoor", "CoopDoor"]:
		var door := scene().get_node("Doors/" + d) as Node2D
		var near := false
		for off in [Vector2(0, 16), Vector2(0, 18), Vector2(0, 20)]:
			near = near or can_reach(grid, door.global_position + off)
		check(near, "%s can be walked up to" % d)
	for n in ["Baker", "Butcher", "Villager01", "Villager02", "Mochi"]:
		var npc := scene().get_node(n) as Node2D
		var ok := false
		for off in [Vector2(0, 16), Vector2(0, -16), Vector2(16, 0), Vector2(-16, 0)]:
			ok = ok or can_reach(grid, npc.global_position + off)
		check(ok, "%s can be walked up to" % n)
	check(can_reach(grid, Vector2(256, 640)), "bridge over the pond walkable")
	check(not can_reach(grid, Vector2(180, 640)), "pond water blocked")
	check(not can_reach(grid, Vector2(90, 200)), "inside the farm fence blocked")
	# Farm plots reachable from outside the fence (Interactor radius 24 + plot half 8).
	# A plot can be used when the Interactor circle (r 24) touches its 32x32 area.
	for plot in scene().get_node("Farm").get_children():
		var ok := false
		for cell in grid:
			var d: Vector2 = (Vector2(cell) * 4.0 - (plot as Node2D).global_position).abs() - Vector2(16, 16)
			if Vector2(maxf(d.x, 0), maxf(d.y, 0)).length() < 23.0:
				ok = true
				break
		check(ok, "%s reachable from outside the fence" % plot.name)

	# Bed only works when the story says to sleep.
	await go("res://scenes/interiors/house_interior.tscn", "Spawn_inside")
	var bed := scene().get_node("Bed")
	check(not Bed.can_sleep(), "can't sleep before the Level 1 sleep task")
	bed.interact(player())
	await get_tree().create_timer(0.3).timeout
	check(Dialogue.active and not bed._sleeping, "bed gives a 'not tired' thought instead")
	await wait(1.0)
	Level1Quest.stage = Level1Quest.Stage.SLEEP
	check(Bed.can_sleep(), "can sleep at the Level 1 sleep task")
	Level1Quest.stage = Level1Quest.Stage.FEED
	var g := Dialogue._glitch("Something is wrong in this town", 2)
	var firsts_ok := true
	for w in g.split(" "):
		firsts_ok = firsts_ok and w.length() > 0 and w[0].to_lower() != w[0].to_upper()
	check(firsts_ok, "glitched text keeps every word's first letter (%s)" % g)
	await go("res://scenes/test_main.tscn")

	# Round trip through every door.
	for pair in [["HouseDoor", "Spawn_house_outside"], ["BakeryDoor", "Spawn_bakery_outside"], ["TownhallDoor", "Spawn_townhall_outside"], ["ButcherDoor", "Spawn_butcher_outside"], ["CoopDoor", "Spawn_coop_outside"]]:
		scene().get_node("Doors/" + pair[0]).interact(player())
		await wait(1.2)
		var inside := scene().scene_file_path
		var exit := scene().get_node_or_null("ExitDoor")
		check(exit != null, "%s opens %s" % [pair[0], inside.get_file()])
		if exit == null:
			continue
		exit.interact(player())
		await wait(1.2)
		var m := scene().get_node("Doors/" + pair[1]) as Node2D
		check(player().global_position.distance_to(m.global_position) < 1.0, "back outside at %s" % pair[1])

	# Coop: feed, then collect eggs.
	scene().get_node("Doors/CoopDoor").interact(player())
	await wait(1.2)
	var coop := scene()
	check(coop.name == "CoopInterior", "in the coop")
	var cgrid := reachable(player().global_position)
	var trough := coop.get_node("Pen/Trough") as Node2D
	var tr_ok := false
	for cell in cgrid:
		if (Vector2(cell) * 4.0).distance_to(trough.global_position) < 30.0:
			tr_ok = true
			break
	check(tr_ok, "feeder reachable")
	for e in coop.get_node("Pen/EggSpots").get_children():
		var ok := false
		for cell in cgrid:
			if (Vector2(cell) * 4.0).distance_to(e.global_position) < 28.0:
				ok = true
				break
		check(ok, "%s reachable" % e.name)
	check(trough.enabled, "trough usable at the FEED task")
	trough.interact(player())
	await wait(0.6)
	check(Level1Quest.stage == Level1Quest.Stage.EGGS, "feeding moves on to eggs")
	var eggs := []
	for e in coop.get_node("Pen/EggSpots").get_children():
		for c in e.get_children():
			if c is Pickup:
				eggs.append(c)
	check(eggs.size() == 3, "3 eggs laid in the coop (%d)" % eggs.size())
	for egg in eggs:
		egg.interact(player())
		await wait(0.2)
	check(Level1Quest.stage == Level1Quest.Stage.PLANT, "eggs collected -> plant")
	coop.get_node("ExitDoor").interact(player())
	await wait(1.2)

	# Level 2 morning: boarded-up map, arena walls, eggs crack in the coop.
	Level1Quest.stage = Level1Quest.Stage.DONE
	Level2Quest._begun = true
	Level2Quest.stage = Level2Quest.Stage.EVENING
	check(Level2Quest.wake_up(), "level 2 starts")
	await go("res://scenes/test_main.tscn", "Spawn_house_outside")
	map = scene().get_node("Map") as VillageMap
	check(map.texture.resource_path.ends_with("level1_map.png"), "Level 2 shows the boarded-up map")
	check((scene().get_node("CorruptedOnly") as StaticBody2D).collision_layer == 1 and (scene().get_node("NormalOnly") as StaticBody2D).collision_layer == 0, "arena walls on, old props off")
	grid = reachable(player().global_position)
	check(can_reach(grid, Vector2(416, 440)), "arena entrance reachable")
	check(can_reach(grid, Vector2(416, 530)), "inside the arena reachable through its gate")
	check(not can_reach(grid, Vector2(359, 530)), "arena wall blocks")
	check(can_reach(grid, scene().get_node("Doors/Spawn_coop_outside").global_position), "coop still reachable")
	scene().get_node("Doors/CoopDoor").interact(player())
	await wait(1.2)
	var cracked := []
	for e in scene().get_node("Pen/EggSpots").get_children():
		var egg := e.get_node_or_null("L2Egg")
		if egg:
			cracked.append(egg)
	check(cracked.size() == 3, "Level 2 eggs in the coop (%d)" % cracked.size())
	for egg in cracked:
		egg.interact(player())
		await wait(1.0)
	await wait(9.0)
	check(Level2Quest.stage == Level2Quest.Stage.BUTCHER, "eggs crack, walls close in, Butcher stage (stage %d)" % Level2Quest.stage)
	check(scene().get_node_or_null("ButcherBoss") == null, "Butcher doesn't appear inside the coop")
	scene().get_node("ExitDoor").interact(player())
	await wait(1.5)
	var boss := scene().get_node_or_null("ButcherBoss")
	check(boss != null, "Butcher follows you back in the village")
	check(scene().get_node("Doors/ButcherDoor").locked, "shop locked")
	# Fight placement inside the stone yard.
	Dialogue.start(load("res://dialogues/butcher_l2_challenge.tres"))
	await wait(4.0)
	check(Level2Quest.stage == Level2Quest.Stage.FIGHT, "fight starts")
	var arena := Level2Quest.ARENA
	check(arena.has_point(player().global_position) and free_at(player().global_position), "player placed inside the stone arena")
	check(boss != null and arena.has_point(boss.global_position), "Butcher placed inside the arena")
	print("DONE fails=%d" % fails)
	get_tree().quit(fails)
