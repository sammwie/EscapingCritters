class_name Level3Quest
extends Node
## Level 3 (merged Levels 2 and 3 from the 10/20 meeting). Picks up right after
## the Butcher's torn note is read and runs to the Knows All map:
##
##   GO_TO_BED  - go home and sleep. Mochi dies overnight.
##   ASK_BAKER  - wake up, the map has changed (village_day3). Ask the Baker
##                what happened to Mochi. He panics about the pond.
##   RUN_HOME   - villagers close in around you (scripted, they can't catch
##                you). Get back through your front door.
##   SNEAK      - the house fades to night on its own. Sneak through the night
##                map (village_night) to the pond without being seen.
##   POND       - the rigged pond puzzle (levels/puddle_level.tscn).
##   KNOWS_ALL  - you sank. The Knows All map (placeholder).
##
## Level2Quest adds one of these next to itself in every scene, the same way
## Level1Quest adds Level2Quest, so it never has to be placed by hand. Scenes
## that have no Level2Quest (the pond, Knows All) place one directly.
## Progress lives in static vars so it survives scene changes.
##
## Which map this is gets worked out from the scene:
##   a "Bed" node                    -> the house
##   root metadata story_map = "day3" / "night" / "knows_all"
##   a "PuddlePuzzle" node           -> the pond
##
## Debug builds only: F3 jumps straight to "Butcher note read, go to bed".

enum Stage { INACTIVE, GO_TO_BED, ASK_BAKER, RUN_HOME, SNEAK, POND, KNOWS_ALL }

const FONT_REG := preload("res://art/fonts/Silkscreen-Regular.ttf")
const FONT_BOLD := preload("res://art/fonts/Silkscreen-Bold.ttf")
const CREAM := Color(1, 0.972549, 0.9098039)
const WOOD := Color(0.6509804, 0.45490196, 0.28235295)
const WOOD_DARK := Color(0.47058824, 0.32156864, 0.20392157)
const INK := Color(0.22745098, 0.15686275, 0.11764706)

## Placeholder tints until the designers' maps arrive.
const DAY3_TINT := Color(0.93, 0.84, 0.9)
const NIGHT_TINT := Color(0.32, 0.36, 0.6)

const TASKS := [
	"Go home and get some sleep",
	"Ask the Baker what happened to Mochi",
	"Run home!",
	"Sneak out to the pond without being seen",
	"Cross the pond",
]

const CORRUPT_SHADER := preload("res://corrupt_tint.gdshader")

## Screen corruption per map: pixel block size in screen pixels, then a
## color grade. It only ever gets worse (GDD: corruption is permanent).
const DAY3_PIXEL := 5.0
const SURROUND_PIXEL := 8.0
const NIGHT_PIXEL := 7.0
const DAY3_GRADE := Color(1.05, 0.9, 1.0)
const NIGHT_GRADE := Color(0.9, 0.95, 1.1)

## Day 3 hostility timings, in seconds outside before the Baker scene.
const STALK_AT := 20.0
const CLOSE_AT := 45.0
## Extra villagers standing around the day 3 map, staring.
const ONLOOKER_SPOTS := [Vector2(176, 150), Vector2(262, 142), Vector2(340, 236)]
const COLD_LINES := [
	["...", "We don't talk to you anymore."],
	["You shouldn't be outside today.", "Go back inside."],
	["Did you sleep well?", "You weren't supposed to."],
	["Don't look at me.", "DON'T LOOK AT ME."],
	["The Baker is waiting for you.", "He's been waiting a long time."],
]

## How many villagers make up the ring after the Baker scene.
const SURROUND_TOTAL := 9
const SURROUND_RADIUS := 28.0
const SURROUND_SPEED := 38.0
const VILLAGER_ART := ["res://art/villager-01", "res://art/villager-02"]

static var stage: int = Stage.INACTIVE
static var _version := 0

var _scene: Node
var _player: CharacterBody2D
var _map := ""
enum CrowdMode { STARE, STALK, CLOSE, SURROUND }
var _crowd: Array[Node2D] = []
var _crowd_mode := CrowdMode.STARE
var _crowd_radius := 75.0
var _crowd_speed := 22.0
var _crowd_t := 0.0
var _hostile_t := 0.0
var _scripted := false
var _panel: PanelContainer
var _task_labels: Array[Label] = []
var _seen_version := -1

## Call when a brand new game starts.
static func reset() -> void:
	stage = Stage.INACTIVE
	_version += 1

func _ready() -> void:
	_scene = get_parent()
	_build_ui()
	_setup.call_deferred()

func _setup() -> void:
	_player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	_map = _detect_map()
	match _map:
		"house":
			var bed := _scene.get_node_or_null("Bed")
			if bed and bed.has_signal("slept"):
				bed.slept.connect(_on_slept)
			if stage >= Stage.SNEAK and stage < Stage.POND:
				_add_tint(NIGHT_TINT)
			if stage == Stage.RUN_HOME:
				_nightfall()
		"day3":
			_add_tint(DAY3_TINT)
			_ensure_glitch_overlay()
			_setup_day3()
		"night":
			_add_tint(NIGHT_TINT)
			_ensure_glitch_overlay()
			CorruptionScreen.ensure(_scene).step_to(NIGHT_PIXEL, 0.4, NIGHT_GRADE)
			_setup_night()
		"pond":
			_setup_pond()
		"knows_all":
			if stage < Stage.KNOWS_ALL:
				stage = Stage.KNOWS_ALL
				_version += 1
			GameState.set_flag("pond_lost", true)
	_version += 1

func _detect_map() -> String:
	var tag := String(_scene.get_meta("story_map", ""))
	if tag != "":
		return tag
	if _scene.get_node_or_null("Bed") is Bed:
		return "house"
	if _scene.get_node_or_null("PuddlePuzzle") != null:
		return "pond"
	return "other"

func _process(delta: float) -> void:
	# The Butcher's note was just read: Level 3 begins with going to bed.
	if stage == Stage.INACTIVE and Level2Quest.stage == Level2Quest.Stage.DONE:
		stage = Stage.GO_TO_BED
		_version += 1
		GameState.set_flag("note_read", true)
		_announce_after_banner()
	if _seen_version != _version:
		_seen_version = _version
		_refresh()
	if _map == "day3" and stage == Stage.ASK_BAKER and not _crowd.is_empty():
		_update_hostility(delta)
	if not _crowd.is_empty():
		_move_crowd(delta)

func _input(event: InputEvent) -> void:
	if _scripted and Dialogue.active and event.is_action_pressed("interact"):
		Dialogue.request_advance()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if OS.is_debug_build() and event is InputEventKey and event.pressed \
			and not event.echo and event.keycode == KEY_F3:
		_debug_skip_to_level3()

# ---------- GO_TO_BED: the bed in the house ----------

func _announce_after_banner() -> void:
	# Let Level 2's "Level 2 Complete" banner finish first.
	await get_tree().create_timer(5.5).timeout
	while Dialogue.active:
		await get_tree().process_frame
	if stage == Stage.GO_TO_BED:
		TaskPopup.show_task(self, TASKS[0])

## The Bed emits `slept` while the screen is still black.
func _on_slept() -> void:
	if stage != Stage.GO_TO_BED:
		return
	stage = Stage.ASK_BAKER
	# Mochi dies overnight.
	StoryInteractable.set_story_flag("cat_dead", true)
	GameState.set_night(false)
	GameState.corruption_stage = maxi(GameState.corruption_stage, 2)
	_version += 1
	# Wait for the Bed's fade back in, then point the player outside.
	await get_tree().create_timer(1.4).timeout
	await _say("You", ["(...It's so quiet this morning. Where's Mochi?)"], "l3_wake")
	TaskPopup.show_task(self, TASKS[1])

# ---------- ASK_BAKER and RUN_HOME: the changed day map ----------
#
# Hostility escalates the longer you stay out (GDD Level 2):
#   arrival      villagers stare and refuse to talk
#   STALK_AT s   they start trailing you at a distance
#   CLOSE_AT s   they crowd in tighter and the town glitches more
#   Baker scene  they surround you (scripted, can't catch you)

func _setup_day3() -> void:
	var screen := CorruptionScreen.ensure(_scene)
	screen.step_to(DAY3_PIXEL, 0.3, DAY3_GRADE)
	var baker := _scene.get_node_or_null("Baker") as Node2D
	if baker:
		_corrupt.call_deferred(baker, 0.35)
		var story := baker.get_node_or_null("Baker2D")
		if story and story.has_signal("story_beat_finished"):
			story.story_beat_finished.connect(_on_baker_confronted)
	if stage == Stage.ASK_BAKER:
		_setup_onlookers()
		if not _seen_dead_cat():
			_cat_intro.call_deferred()
	elif stage == Stage.RUN_HOME:
		screen.step_to(SURROUND_PIXEL, 0.45, DAY3_GRADE)
		_start_surround(false)

func _seen_dead_cat() -> bool:
	return StoryInteractable.get_story_flag("l3_saw_cat")

## First step outside on day 3: notice Mochi.
func _cat_intro() -> void:
	StoryInteractable.set_story_flag("l3_saw_cat", true)
	await get_tree().create_timer(0.6).timeout
	get_tree().call_group("glitch_overlay", "flicker", 0.5, 0.6)
	_freeze(true)
	await _say("You", [
		"Mochi...?",
		"She isn't moving.",
		"(The whole town looks... wrong. The Baker will know what happened.)",
	], "l3_cat_intro")
	_freeze(false)

## Villagers who stare at you and won't talk on the way to the Baker.
func _setup_onlookers() -> void:
	_crowd.clear()
	_crowd_mode = CrowdMode.STARE
	_hostile_t = 0.0
	var i := 0
	for n in ["Villager01", "Villager02"]:
		var v := _scene.get_node_or_null(n) as Node2D
		if v:
			_make_onlooker(v, i)
			i += 1
	for spot in ONLOOKER_SPOTS:
		var v := _spawn_villager(i)
		v.global_position = spot
		_make_onlooker(v, i)
		i += 1

func _make_onlooker(v: Node2D, i: int) -> void:
	if "dialogue" in v:
		v.dialogue = _cold_dialogue("l3_onlooker_%d" % i, COLD_LINES[i % COLD_LINES.size()])
	if "enabled" in v:
		v.enabled = true
	for child in v.get_children():
		if child is StaticBody2D:
			child.queue_free()
		elif child is NPCLook:
			child.face_range = 400.0  # every head turns to follow you
	_corrupt.call_deferred(v, 0.5)
	_crowd.append(v)

func _update_hostility(delta: float) -> void:
	if Dialogue.active:
		return
	_hostile_t += delta
	if _crowd_mode == CrowdMode.STARE and _hostile_t >= STALK_AT:
		_crowd_mode = CrowdMode.STALK
		_crowd_radius = 75.0
		_crowd_speed = 22.0
		_say("You", ["(Are they... following me?)"], "l3_followed")
	elif _crowd_mode == CrowdMode.STALK and _hostile_t >= CLOSE_AT:
		_crowd_mode = CrowdMode.CLOSE
		_crowd_radius = 50.0
		_crowd_speed = 30.0
		get_tree().call_group("glitch_overlay", "flicker", 0.6, 0.8)
		CorruptionScreen.ensure(_scene).step_to(DAY3_PIXEL + 1.5, 0.38, DAY3_GRADE, 2.0)
		for v in _crowd:
			if is_instance_valid(v):
				_corrupt(v, 0.8)
				if "enabled" in v:
					v.enabled = false  # they've stopped answering at all

func _on_baker_confronted() -> void:
	if stage != Stage.ASK_BAKER:
		return
	stage = Stage.RUN_HOME
	GameState.corruption_stage = maxi(GameState.corruption_stage, 2)
	_version += 1
	CorruptionScreen.ensure(_scene).step_to(SURROUND_PIXEL, 0.45, DAY3_GRADE, 1.5)
	_start_surround(true)

func _start_surround(fresh: bool) -> void:
	_crowd_mode = CrowdMode.SURROUND
	_crowd_radius = SURROUND_RADIUS
	_crowd_speed = SURROUND_SPEED
	var center := _player.global_position if _player else Vector2(256, 300)
	# Whoever is already out there joins in, the Baker too.
	for n in ["Villager01", "Villager02", "Baker"]:
		var v := _scene.get_node_or_null(n) as Node2D
		if v and not _crowd.has(v):
			_crowd.append(v)
	# Then more walk in from off screen until the ring is full.
	var i := _crowd.size()
	while _crowd.size() < SURROUND_TOTAL:
		var v := _spawn_villager(i)
		var angle := TAU * float(i) / SURROUND_TOTAL
		v.global_position = center + Vector2.from_angle(angle) * (150.0 if fresh else 60.0)
		_crowd.append(v)
		i += 1
	for v in _crowd:
		if is_instance_valid(v):
			_make_hostile(v)
	if fresh:
		get_tree().call_group("glitch_overlay", "flicker", 0.8, 1.0)
		await get_tree().create_timer(0.4).timeout
		await _say("You", ["(They're all staring at me.)", "(I need to get home. Now.)"], "l3_run")
	TaskPopup.show_task(self, TASKS[2])

func _spawn_villager(i: int) -> Node2D:
	var v := (load("res://scenes/npc.tscn") as PackedScene).instantiate() as Node2D
	v.name = "Villager_L3_%d" % i
	var look := NPCLook.new()
	look.art_folder = VILLAGER_ART[i % VILLAGER_ART.size()]
	look.face_range = 400.0
	v.add_child(look)
	_scene.add_child(v)
	return v

func _make_hostile(v: Node2D) -> void:
	_corrupt.call_deferred(v, 1.0)
	if "enabled" in v:
		v.enabled = false  # no chatting, they just stare
	for child in v.get_children():
		if child is StaticBody2D:
			child.queue_free()  # never block the way home
		elif child is Interactable:
			child.enabled = false
			child.set_process(false)

## Per-character corruption (GDD Art Style): colors invert and desaturate on
## the villager itself, separate from the screen-wide effect.
func _corrupt(v: Node, amount: float) -> void:
	if not is_instance_valid(v):
		return
	var sprite := v.get_node_or_null("Sprite2D") as CanvasItem
	if sprite == null:
		# NPCLook adds its sprite a frame late; try once more.
		await get_tree().process_frame
		if not is_instance_valid(v):
			return
		sprite = v.get_node_or_null("Sprite2D") as CanvasItem
		if sprite == null:
			return
	var mat := sprite.material as ShaderMaterial
	if mat == null or mat.shader != CORRUPT_SHADER:
		mat = ShaderMaterial.new()
		mat.shader = CORRUPT_SHADER
		sprite.material = mat
	mat.set_shader_parameter("amount", amount)

## Moves the crowd: still while staring, otherwise toward a slowly turning
## ring around the player. Nobody ever stops the player moving.
func _move_crowd(delta: float) -> void:
	if _player == null or Dialogue.active or _crowd_mode == CrowdMode.STARE:
		return
	_crowd_t += delta
	var count := _crowd.size()
	for i in count:
		var v := _crowd[i]
		if not is_instance_valid(v):
			continue
		var angle := TAU * float(i) / count + _crowd_t * 0.25
		var target := _player.global_position + Vector2.from_angle(angle) * _crowd_radius
		v.global_position = v.global_position.move_toward(target, _crowd_speed * delta)

func _cold_dialogue(id: String, lines: Array) -> DialogueData:
	var data := DialogueData.new()
	data.npc_id = id
	for j in lines.size():
		var line := DialogueLine.new()
		line.speaker = "Villager"
		line.text = String(lines[j])
		line.glitch = j == lines.size() - 1
		data.lines.append(line)
		data.repeat_lines.append(line)
	return data

# ---------- RUN_HOME -> SNEAK: back in the house ----------

## Getting home fades straight to night, no second sleep needed.
func _nightfall() -> void:
	_freeze(true)
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	var black := ColorRect.new()
	black.color = Color(0.03, 0.03, 0.06, 1.0)
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(black)
	var label := Label.new()
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", FONT_REG)
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", CREAM)
	label.modulate.a = 0.0
	layer.add_child(label)

	for text in ["You bolt the door behind you.", "Footsteps circle the house for hours...", "Night falls."]:
		label.text = text
		var tw := create_tween()
		tw.tween_property(label, "modulate:a", 1.0, 0.6)
		tw.tween_interval(1.4)
		tw.tween_property(label, "modulate:a", 0.0, 0.6)
		await tw.finished

	stage = Stage.SNEAK
	_version += 1
	GameState.set_night(true)
	_add_tint(NIGHT_TINT)
	var fade := create_tween()
	fade.tween_property(black, "color:a", 0.0, 1.2)
	await fade.finished
	layer.queue_free()
	await _say("You", [
		"(The Baker panicked when I asked about Mochi. He kept saying nobody goes to the pond.)",
		"(Whatever they're hiding is there. I'm going tonight.)",
	], "l3_night_thought")
	_freeze(false)
	TaskPopup.show_task(self, TASKS[3])

# ---------- SNEAK: the night map ----------

func _setup_night() -> void:
	# Everyone is out patrolling instead (the guards in the scene).
	for n in ["Baker", "Villager01", "Villager02"]:
		var v := _scene.get_node_or_null(n)
		if v:
			v.queue_free()
	for path in ["Doors/BakeryDoor", "Doors/ButcherDoor", "Doors/TownhallDoor"]:
		var door := _scene.get_node_or_null(path)
		if door and "locked" in door:
			door.locked = true
			door.locked_message = "Dark inside. Better not."
			door.prompt_text = "Locked"
	var puzzle := _scene.get_node_or_null("HidingPuzzle")
	if puzzle and puzzle.has_signal("solved"):
		puzzle.solved.connect(_on_reached_pond)
	for guard in get_tree().get_nodes_in_group("patrol_guard"):
		_corrupt.call_deferred(guard, 0.9)
	var watcher := _scene.get_node_or_null("KnowsAllWatcher")
	if watcher and watcher.has_signal("noticed"):
		watcher.noticed.connect(_on_watcher_noticed)

## Knows All's first appearance: far off, silent, never approaching.
func _on_watcher_noticed() -> void:
	if stage != Stage.SNEAK:
		return
	# Freeze the guards too, so stopping to look is never what gets you caught.
	var guards := get_tree().get_nodes_in_group("patrol_guard")
	for g in guards:
		g.set_active(false)
	get_tree().call_group("glitch_overlay", "flicker", 0.6, 0.7)
	await _say("You", [
		"(Something is standing out on the water.)",
		"(It isn't moving. It's just... watching me.)",
	], "l3_knows_all_seen")
	for g in guards:
		if is_instance_valid(g):
			g.set_active(true)

func _on_reached_pond() -> void:
	if stage != Stage.SNEAK:
		return
	stage = Stage.POND
	_version += 1
	_freeze(true)
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	var black := ColorRect.new()
	black.color = Color(0, 0, 0, 0)
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(black)
	var tw := create_tween()
	tw.tween_property(black, "color:a", 1.0, 1.0)
	await tw.finished
	GameState.change_scene(StoryRouter.POND)

# ---------- POND ----------

func _setup_pond() -> void:
	var puzzle := _scene.get_node_or_null("PuddlePuzzle")
	if puzzle and "lose_scene_path" in puzzle and String(puzzle.lose_scene_path) == "":
		puzzle.lose_scene_path = StoryRouter.KNOWS_ALL
	if stage == Stage.POND:
		_add_tint(NIGHT_TINT.lightened(0.25))
		CorruptionScreen.ensure(_scene).step_to(NIGHT_PIXEL, 0.4, NIGHT_GRADE)
		TaskPopup.show_task(self, TASKS[4])

# ---------- helpers ----------

func _add_tint(color: Color) -> void:
	if _scene.get_node_or_null("StoryTint") != null:
		(_scene.get_node("StoryTint") as CanvasModulate).color = color
		return
	var tint := CanvasModulate.new()
	tint.name = "StoryTint"
	tint.color = color
	_scene.add_child(tint)

func _ensure_glitch_overlay() -> void:
	if get_tree().get_nodes_in_group("glitch_overlay").is_empty():
		var overlay := (load("res://scenes/glitch_overlay.tscn") as PackedScene).instantiate()
		_scene.add_child(overlay)

func _freeze(on: bool) -> void:
	if _player:
		_player.set_physics_process(not on)

func _say(speaker: String, lines: Array, id: String) -> void:
	var data := DialogueData.new()
	data.npc_id = id
	for text in lines:
		var line := DialogueLine.new()
		line.speaker = speaker
		line.text = String(text)
		data.lines.append(line)
		data.repeat_lines.append(line)
	_scripted = true
	Dialogue.start(data)
	await Dialogue.finished
	_scripted = false

## Debug: pretend Levels 1 and 2 are done and the note was just read.
func _debug_skip_to_level3() -> void:
	Level1Quest.stage = Level1Quest.Stage.DONE
	Level2Quest.stage = Level2Quest.Stage.DONE
	Level2Quest._begun = true
	GameState.current_level = 3
	stage = Stage.GO_TO_BED
	_version += 1
	get_tree().root.set_meta("intro_played", true)
	get_tree().root.set_meta("spawn_at", "Spawn_inside")
	get_tree().change_scene_to_file("res://scenes/interiors/house_interior.tscn")

# ---------- UI ----------

func _refresh() -> void:
	_panel.visible = stage >= Stage.GO_TO_BED and stage < Stage.KNOWS_ALL
	var active := stage - Stage.GO_TO_BED
	for i in _task_labels.size():
		var label := _task_labels[i]
		label.visible = i <= active
		if i < active:
			label.text = "[x] " + TASKS[i]
			label.modulate = Color(1, 1, 1, 0.45)
		else:
			label.text = "[ ] " + TASKS[i]
			label.modulate = Color.WHITE

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(CREAM, 0.95)
	style.border_color = WOOD
	style.set_border_width_all(6)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(20)
	style.shadow_color = Color(INK, 0.4)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 4)

	_panel = PanelContainer.new()
	_panel.position = Vector2(32, 32)
	_panel.add_theme_stylebox_override("panel", style)
	_panel.visible = false
	layer.add_child(_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_panel.add_child(box)

	var title := Label.new()
	title.text = "Today's Tasks"
	title.add_theme_font_override("font", FONT_BOLD)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", WOOD_DARK)
	box.add_child(title)

	for i in TASKS.size():
		var label := Label.new()
		label.add_theme_font_override("font", FONT_REG)
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", INK)
		box.add_child(label)
		_task_labels.append(label)
