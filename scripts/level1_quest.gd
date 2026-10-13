class_name Level1Quest
extends Node
## Level 1, "A normal day". Walks the player through a cozy farming day
## with an on-screen task list:
##   talk to the Baker > plant > water > sleep > harvest > deliver wheat.
## Add one of these to every scene the player can be in (village and
## interiors). Progress is kept in static vars, so it survives walking
## in and out of buildings for the whole play session.
##
## In the village it also looks for sibling nodes named "Baker" (an NPC)
## and "Farm" (holding FarmPlot instances) and wires them up.

enum Stage { TALK_BAKER, PLANT, WATER, SLEEP, HARVEST, DELIVER, DONE }

const NEEDED := 3
const FONT_REG := preload("res://art/fonts/Silkscreen-Regular.ttf")
const FONT_BOLD := preload("res://art/fonts/Silkscreen-Bold.ttf")
const WHEAT_ART := preload("res://art/Inventory items/wheat.png")
const BAKER_LINES := {
	Stage.TALK_BAKER: "res://dialogues/baker_l1_morning.tres",
	Stage.DELIVER: "res://dialogues/baker_l1_delivery.tres",
	Stage.DONE: "res://dialogues/baker_l1_after.tres",
}
const BAKER_WAITING := "res://dialogues/baker_l1_waiting.tres"

const CREAM := Color(1, 0.972549, 0.9098039)
const WOOD := Color(0.6509804, 0.45490196, 0.28235295)
const WOOD_DARK := Color(0.47058824, 0.32156864, 0.20392157)
const INK := Color(0.22745098, 0.15686275, 0.11764706)

static var stage: int = Stage.TALK_BAKER
static var planted := 0
static var watered := 0
static var harvested := 0
static var plot_saves := {}   # plot name -> [state, growth, days_to_grow]
static var _version := 0      # bumps on any change so every scene's UI refreshes

var _baker: Node = null
var _plots: Array[FarmPlot] = []
var _task_labels: Array[Label] = []
var _seen_version := -1

# Call this when a brand new game starts.
static func reset() -> void:
	stage = Stage.TALK_BAKER
	planted = 0
	watered = 0
	harvested = 0
	plot_saves.clear()
	_version += 1

# Called by Bed. Grows watered crops even though the field is in another scene.
static func sleep_through_night() -> void:
	if GameState.has_method("advance_day"):
		GameState.call("advance_day")
	else:
		GameState.current_day += 1
	for plot_name in plot_saves:
		var s: Array = plot_saves[plot_name]
		if s[0] == FarmPlot.State.WATERED:
			s[1] += 1
			s[0] = FarmPlot.State.GROWN if s[1] >= s[2] else FarmPlot.State.PLANTED
	if stage == Stage.SLEEP:
		stage = Stage.HARVEST
	_version += 1

func _ready() -> void:
	_build_ui()
	Dialogue.conversation_ended.connect(_on_conversation_ended)
	_setup_village.call_deferred()

func _process(_delta: float) -> void:
	if _seen_version != _version:
		_seen_version = _version
		_refresh()

# ---------- Village wiring ----------

func _setup_village() -> void:
	var scene := get_parent()
	_baker = scene.get_node_or_null("Baker")
	var farm := scene.get_node_or_null("Farm")
	if farm:
		for child in farm.get_children():
			if child is FarmPlot:
				_setup_plot(child)
	_version += 1

func _setup_plot(plot: FarmPlot) -> void:
	_plots.append(plot)
	var crop := Sprite2D.new()
	crop.name = "Crop"
	crop.texture = WHEAT_ART
	crop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	plot.add_child(crop)
	if plot_saves.has(plot.name):
		var s: Array = plot_saves[plot.name]
		plot.growth = s[1]
		plot._set_state(s[0])
	plot.planted.connect(_on_planted.bind(plot))
	plot.watered.connect(_on_watered.bind(plot))
	plot.harvested.connect(_on_harvested.bind(plot))
	plot.state_changed.connect(_on_plot_state.bind(plot))
	_update_crop(plot)

func _on_planted(_crop_id: StringName, _plot: FarmPlot) -> void:
	planted += 1
	_check()

func _on_watered(_plot: FarmPlot) -> void:
	watered += 1
	_check()

func _on_harvested(_crop_id: StringName, _plot: FarmPlot) -> void:
	harvested += 1
	_check()

func _on_plot_state(_state: int, plot: FarmPlot) -> void:
	plot_saves[plot.name] = [plot.state, plot.growth, plot.days_to_grow]
	_update_crop(plot)
	_version += 1

func _update_crop(plot: FarmPlot) -> void:
	var crop: Sprite2D = plot.get_node_or_null("Crop")
	if crop == null:
		return
	match plot.state:
		FarmPlot.State.EMPTY:
			crop.visible = false
		FarmPlot.State.GROWN:
			crop.visible = true
			crop.scale = Vector2.ONE * 0.125
			crop.modulate = Color.WHITE
		_:
			crop.visible = true
			crop.scale = Vector2.ONE * 0.06
			crop.modulate = Color(0.6, 1.0, 0.5)

func _on_conversation_ended(npc_id: String) -> void:
	if npc_id != "baker":
		return
	if stage == Stage.TALK_BAKER:
		_set_stage(Stage.PLANT)
	elif stage == Stage.DELIVER:
		_set_stage(Stage.DONE)
		GameState.current_level = 2
		_show_banner("Level 1 Complete", "Tomorrow, the bread will come out the same.")

func _check() -> void:
	match stage:
		Stage.PLANT:
			if planted >= NEEDED:
				_set_stage(Stage.WATER)
		Stage.WATER:
			if watered >= NEEDED:
				_set_stage(Stage.SLEEP)
		Stage.HARVEST:
			if harvested >= NEEDED:
				_set_stage(Stage.DELIVER)
	_version += 1

func _set_stage(new_stage: int) -> void:
	stage = new_stage
	_version += 1
	_check()  # catch up if the next task is already done

# ---------- UI ----------

func _refresh() -> void:
	for plot in _plots:
		plot.enabled = stage >= Stage.PLANT
	if _baker and "dialogue" in _baker:
		var path: String = BAKER_LINES.get(stage, BAKER_WAITING)
		_baker.dialogue = load(path)

	var tasks := [
		"Say good morning to the Baker",
		"Plant wheat in the farm field (%d/%d)" % [mini(planted, NEEDED), NEEDED],
		"Water the seeds (%d/%d)" % [mini(watered, NEEDED), NEEDED],
		"Go home and sleep in your bed",
		"Harvest the wheat (%d/%d)" % [mini(harvested, NEEDED), NEEDED],
		"Bring the wheat to the Baker",
	]
	for i in _task_labels.size():
		var label := _task_labels[i]
		label.visible = i <= stage
		if i < stage:
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

	var panel := PanelContainer.new()
	panel.position = Vector2(32, 32)
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	var title := Label.new()
	title.text = "Today's Tasks"
	title.add_theme_font_override("font", FONT_BOLD)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", WOOD_DARK)
	box.add_child(title)

	for i in 6:
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
	tween.tween_interval(3.5)
	tween.tween_property(box, "modulate:a", 0.0, 1.0)
	tween.tween_callback(layer.queue_free)
