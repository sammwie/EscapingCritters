class_name Level2Quest
extends Node
## Level 2, "Things Get WEIRD". Starts the morning after Level 1 ends (right
## after the Baker's wheat-and-eggs delivery) and plays out as fixed, scripted
## story beats, in this order:
##
##   EVENING - the Baker hands over the bread, mentions tomorrow's eggs (just
##             dialogue, not a task) and tells you to get some rest. Sleep to start.
##   EGGS    - collect the three coop eggs; each cracks open empty
##   WALLS   - scripted scare: the walls close in (no fail state)
##   BUTCHER - his shop closes early, he starts following you, his dialogue is
##             strange. Talk to him to start the fight.
##   FIGHT   - real-time fight outside his shop (Space = attack, Shift = dodge)
##   NOTE    - he drops a torn note: read it (it is saved; press N to re-read)
##   DONE    - Level 2 complete, GameState.current_level becomes 3
##
## Add one of these to every scene the player can be in (village and
## interiors), the same way Level1Quest is. Progress is kept in static vars so
## it survives walking in and out of buildings.
##
## In the village it looks for these sibling nodes by name:
##   "Butcher" (NPC), "Doors/ButcherDoor", "Doors/Spawn_house_outside",
##   "Pen/EggSpots" (Marker2Ds), and the player's "Camera2D".

enum Stage { INACTIVE, EVENING, EGGS, WALLS, BUTCHER, FIGHT, NOTE, DONE }

const NEEDED := 3
## The fight happens in this rectangle of the village, outside the butcher shop.
const ARENA := Rect2(180, 282, 158, 106)
const WARNING_DIALOGUE := "res://dialogues/butcher_l2_warning.tres"
const CHALLENGE_DIALOGUE := "res://dialogues/butcher_l2_challenge.tres"

const NOTE_TITLE := "Torn Note"
## PLACEHOLDER lore. Rewrite this text whenever the story team decides what
## the Butcher's clue should say.
const NOTE_BODY := "The eggs are empty again. I keep the knives sharp so I don't have to think about it.\n\nSomeone tells me what to say each morning. I say it. I don't remember deciding to.\n\nIf you are reading this: the roads don't lead out. Ask the Baker why the bread never runs out.\n\n- B."

const FONT_REG := preload("res://art/fonts/Silkscreen-Regular.ttf")
const FONT_BOLD := preload("res://art/fonts/Silkscreen-Bold.ttf")
const CREAM := Color(1, 0.972549, 0.9098039)
const WOOD := Color(0.6509804, 0.45490196, 0.28235295)
const WOOD_DARK := Color(0.47058824, 0.32156864, 0.20392157)
const INK := Color(0.22745098, 0.15686275, 0.11764706)

static var stage: int = Stage.INACTIVE
static var eggs_cracked: Array[String] = []
static var note_pos := Vector2(259, 335)
## Seconds to wait after Level 1 ends (so its banner can finish) before the
## fade to the next morning. Tests set this lower.
static var start_delay := 6.0
static var _begun := false
static var _version := 0
static var _pending_banner := false

var _scene: Node
var _player: CharacterBody2D
var _boss: ButcherBoss
var _is_village := false
var _scripted := false
var _door_hooked := false
var _task_labels: Array[Label] = []
var _panel: PanelContainer
var _seen_version := -1

## Call when a brand new game starts.
static func reset() -> void:
	stage = Stage.INACTIVE
	eggs_cracked.clear()
	note_pos = Vector2(259, 335)
	_begun = false
	NotesLog.reset()
	_version += 1

## Called by the Bed after sleeping. Starts the real Level 2 morning when
## Level 1 is finished. Returns true if it did.
static func wake_up() -> bool:
	if Level1Quest.stage != Level1Quest.Stage.DONE:
		return false
	if stage != Stage.INACTIVE and stage != Stage.EVENING:
		return false
	stage = Stage.EGGS
	GameState.current_level = 2
	GameState.corruption_stage = maxi(GameState.corruption_stage, 1)
	_pending_banner = true
	_version += 1
	return true

func _ready() -> void:
	CombatInput.ensure()
	_scene = get_parent()
	_build_ui()
	Dialogue.conversation_ended.connect(_on_conversation_ended)
	_setup.call_deferred()

func _setup() -> void:
	for n in get_tree().get_nodes_in_group("player"):
		if _scene.is_ancestor_of(n) and not n.is_queued_for_deletion():
			_player = n as CharacterBody2D
			break
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	_is_village = _scene.get_node_or_null("Butcher") != null and _scene.get_node_or_null("Pen/EggSpots") != null
	if _is_village:
		_ensure_glitch_overlay()
		if stage == Stage.FIGHT or stage == Stage.WALLS:
			stage = Stage.BUTCHER  # these two beats can't be resumed halfway
		_apply_village_state()
	_version += 1

func _process(_delta: float) -> void:
	if _pending_banner and stage == Stage.EGGS and not Dialogue.active:
		_pending_banner = false
		_show_banner("Level 2", "Things get weird.")
	if _seen_version != _version:
		_seen_version = _version
		_refresh()
	if _is_village and not _begun and stage == Stage.INACTIVE and Level1Quest.stage == Level1Quest.Stage.DONE:
		_begun = true
		_begin_evening()

# While a scripted line is on screen with nobody to talk to, E has to advance
# it. Handled in _input so the Interactor doesn't advance it a second time.
func _input(event: InputEvent) -> void:
	if _scripted and Dialogue.active and event.is_action_pressed("interact"):
		Dialogue.request_advance()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("notes") and not Dialogue.active and get_tree().get_nodes_in_group("note_viewer").is_empty():
		get_viewport().set_input_as_handled()
		NoteViewer.open_log(_scene)

# ---------- the evening after Level 1 ----------

# The Baker hands over the loaf (Level 1's last line), then asks about
# tomorrow's eggs as plain dialogue. Sleeping in the house starts the morning.
func _begin_evening() -> void:
	await get_tree().create_timer(start_delay).timeout
	while Dialogue.active:
		await get_tree().process_frame
	if stage != Stage.INACTIVE:
		return
	stage = Stage.EVENING
	_version += 1
	_freeze(true)
	await _say("Baker", [
		"Oh, one more thing, dear.",
		"The hens have been so quiet lately. Could you look in on the coop first thing tomorrow? I'll need the eggs for the morning batch.",
		"Now go home and get some rest. Tomorrow's another busy day.",
	], "l2_baker_evening")
	await _say("You", ["(Eggs first thing tomorrow. Time to head home and sleep.)"], "l2_evening_thought")
	_freeze(false)

# ---------- village state (re-applied every time the village loads) ----------

func _apply_village_state() -> void:
	if not _is_village:
		return
	var npc := _scene.get_node_or_null("Butcher")
	match stage:
		Stage.EGGS:
			if npc and "dialogue" in npc:
				npc.dialogue = load(WARNING_DIALOGUE)
			_spawn_eggs()
		Stage.BUTCHER:
			_spawn_eggs()
			_lock_door()
			_make_follower()
		Stage.NOTE:
			_spawn_eggs()
			_lock_door()
			_remove_butcher_npc()
			_spawn_note(note_pos)
		Stage.DONE:
			_spawn_eggs()
			_lock_door()
			_remove_butcher_npc()

func _spawn_eggs() -> void:
	var spots := _scene.get_node_or_null("Pen/EggSpots")
	if spots == null:
		return
	for spot in spots.get_children():
		if spot.get_node_or_null("L2Egg") != null:
			continue
		var egg := CrackingEgg.new()
		egg.name = "L2Egg"
		spot.add_child(egg)
		if eggs_cracked.has(String(spot.name)):
			egg.show_cracked()
		else:
			egg.cracked.connect(_on_egg_cracked.bind(String(spot.name)))
	if stage == Stage.EGGS and eggs_cracked.size() >= NEEDED:
		_start_walls.call_deferred()

func _remove_butcher_npc() -> void:
	var npc := _scene.get_node_or_null("Butcher")
	if npc:
		npc.queue_free()

func _lock_door() -> void:
	var door := _scene.get_node_or_null("Doors/ButcherDoor")
	if door == null:
		return
	door.locked = true
	door.prompt_text = "Closed"
	if not _door_hooked:
		_door_hooked = true
		door.bumped_locked.connect(_on_door_bumped)

func _make_follower() -> void:
	if _boss != null and is_instance_valid(_boss):
		return
	var pos := Vector2(248, 284)
	var npc := _scene.get_node_or_null("Butcher")
	if npc:
		pos = (npc as Node2D).global_position
		npc.queue_free()
	_boss = ButcherBoss.new()
	_boss.name = "ButcherBoss"
	_scene.add_child(_boss)
	_boss.global_position = pos
	_boss.begin_follow(_player)
	_boss.talked.connect(_on_boss_talked)

func _ensure_glitch_overlay() -> void:
	if get_tree().get_nodes_in_group("glitch_overlay").is_empty():
		var overlay := (load("res://scenes/glitch_overlay.tscn") as PackedScene).instantiate()
		_scene.add_child(overlay)

# ---------- story beats ----------

func _on_egg_cracked(spot_name: String) -> void:
	if stage != Stage.EGGS or eggs_cracked.has(spot_name):
		return
	eggs_cracked.append(spot_name)
	_version += 1
	if eggs_cracked.size() == 1:
		_say("You", ["...It's empty."], "l2_first_egg")
	if eggs_cracked.size() >= NEEDED:
		await get_tree().create_timer(1.2).timeout
		while Dialogue.active:
			await get_tree().process_frame
		_start_walls()

func _start_walls() -> void:
	if stage != Stage.EGGS:
		return
	stage = Stage.WALLS
	_version += 1
	_freeze(true)
	var cam := _player.get_node_or_null("Camera2D") as Camera2D
	await WallSqueeze.play(_scene, cam)
	GameState.corruption_stage = maxi(GameState.corruption_stage, 2)
	_freeze(false)
	await _say("You", ["What was that...?", "Something is wrong in this town."], "l2_after_walls")
	stage = Stage.BUTCHER
	_version += 1
	get_tree().call_group("glitch_overlay", "flicker", 0.4, 1.0)
	_apply_village_state()

func _on_door_bumped() -> void:
	if Dialogue.active:
		return
	_say("Sign", ["Closed early today.", "Nobody remembers hanging the sign."], "l2_door_closed")

func _on_boss_talked() -> void:
	if Dialogue.active:
		Dialogue.request_advance()
		return
	if stage == Stage.BUTCHER:
		Dialogue.start(load(CHALLENGE_DIALOGUE))

func _on_conversation_ended(npc_id: String) -> void:
	if npc_id == "butcher_l2_challenge" and stage == Stage.BUTCHER:
		_start_fight()

func _start_fight() -> void:
	if _boss == null or not is_instance_valid(_boss):
		return
	stage = Stage.FIGHT
	_version += 1
	var arena := ButcherArena.new()
	arena.name = "ButcherArena"
	_scene.add_child(arena)
	arena.won.connect(_on_butcher_defeated)
	arena.begin(_player, _boss, ARENA)

func _on_butcher_defeated(at: Vector2) -> void:
	note_pos = at
	stage = Stage.NOTE
	_version += 1
	_spawn_note(at)

func _spawn_note(pos: Vector2) -> void:
	if _scene.get_node_or_null("TornNote") != null:
		return
	var note := LoreNote.new()
	note.name = "TornNote"
	note.note_id = "butcher_note"
	note.title = NOTE_TITLE
	note.body = NOTE_BODY
	note.read_done.connect(_on_note_read)
	_scene.add_child(note)
	note.global_position = pos
	note.scale = Vector2.ZERO
	create_tween().tween_property(note, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK)

func _on_note_read() -> void:
	stage = Stage.DONE
	GameState.current_level = 3
	_version += 1
	_show_banner("Level 2 Complete", "Press N to read your notes. Level 3 is next.")

# ---------- helpers ----------

func _freeze(on: bool) -> void:
	if _player:
		_player.set_physics_process(not on)

## Shows lines through the normal dialogue box. E advances them.
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

# ---------- UI ----------

func _refresh() -> void:
	_panel.visible = stage != Stage.INACTIVE and stage != Stage.EVENING
	var active_index := 0
	match stage:
		Stage.EGGS, Stage.WALLS:
			active_index = 0
		Stage.BUTCHER:
			active_index = 1
		Stage.FIGHT:
			active_index = 2
		Stage.NOTE:
			active_index = 3
		Stage.DONE:
			active_index = 4
	var tasks := [
		"Collect the Baker's eggs from the coop (%d/%d)" % [mini(eggs_cracked.size(), NEEDED), NEEDED],
		"Something is wrong. Talk to the Butcher",
		"Defeat the Butcher",
		"Read the torn note",
	]
	for i in _task_labels.size():
		var label := _task_labels[i]
		label.visible = i <= active_index and i < tasks.size()
		if i < active_index:
			label.text = "[x] " + tasks[i]
			label.modulate = Color(1, 1, 1, 0.45)
		else:
			label.text = "[ ] " + tasks[i]
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

	for i in 4:
		var label := Label.new()
		label.add_theme_font_override("font", FONT_REG)
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", INK)
		box.add_child(label)
		_task_labels.append(label)

func _show_banner(heading: String, sub: String) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 60
	add_child(layer)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.modulate.a = 0.0
	layer.add_child(box)
	for pair in [[heading, FONT_BOLD, 64], [sub, FONT_REG, 24]]:
		var label := Label.new()
		label.text = pair[0]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font", pair[1])
		label.add_theme_font_size_override("font_size", pair[2])
		label.add_theme_color_override("font_color", CREAM)
		label.add_theme_color_override("font_shadow_color", INK)
		label.add_theme_constant_override("shadow_offset_x", 4)
		label.add_theme_constant_override("shadow_offset_y", 4)
		box.add_child(label)
	var tween := create_tween()
	tween.tween_property(box, "modulate:a", 1.0, 1.0)
	tween.tween_interval(3.0)
	tween.tween_property(box, "modulate:a", 0.0, 1.0)
	tween.tween_callback(layer.queue_free)
