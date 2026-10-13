extends Node2D
## Composes the team's scenes and art without editing their source files.

const EGG_POSITIONS := [Vector2(450, 970), Vector2(550, 1000), Vector2(650, 970), Vector2(750, 1000), Vector2(850, 970), Vector2(950, 1000)]
const WALK_AREA := Rect2(70, 900, 1780, 140)

@onready var puzzle: EggPuzzle = $EggTest/EggPuzzle
@onready var player: CharacterBody2D = $EggTest/Player
@onready var status: Label = $HUD/Notice/Lines/Status
@onready var objective: Label = $HUD/Notice/Lines/Objective

var collected := 0


func _ready() -> void:
	GameState.new_playthrough()
	player.position = Vector2(280, 975)
	player.speed = 240.0
	player.get_node("Sprite2D").hide()
	# A presentation-only shape override; the shared player resource is untouched.
	var interaction_shape := CircleShape2D.new()
	interaction_shape.radius = 46.0
	player.get_node("Interactor/CollisionShape2D").shape = interaction_shape
	var egg_names := ["Egg", "Egg2", "Egg3", "Egg4", "Egg5", "Egg6"]
	for index in egg_names.size():
		var egg: Egg = puzzle.get_node(egg_names[index])
		egg.position = EGG_POSITIONS[index]
		egg.interacted.connect(_refresh_eggs)
	puzzle.egg_taken.connect(_on_egg_taken)
	GameState.corruption_changed.connect(_refresh_status)
	puzzle.failed.connect(_on_failed)
	# The original prompt and dialogue scripts remain responsible for their UI.
	var prompt: Label = $EggTest/InteractPrompt/PromptLabel
	prompt.add_theme_font_override("font", load("res://art/fonts/Silkscreen-Regular.ttf"))
	prompt.add_theme_font_size_override("font_size", 26)
	prompt.anchor_top = 0.0
	prompt.anchor_bottom = 0.0
	prompt.offset_top = 815.0
	prompt.offset_bottom = 860.0
	var dialogue_panel: Control = $DialogueBox/PanelContainer
	dialogue_panel.offset_top = -220.0
	dialogue_panel.offset_bottom = -24.0
	dialogue_panel.offset_left = 48.0
	dialogue_panel.offset_right = -48.0
	dialogue_panel.add_theme_stylebox_override("panel", $HUD/Notice.get_theme_stylebox("panel"))
	dialogue_panel.theme = $HUD/Notice.theme
	_refresh_status(GameState.corruption_stage)


func _physics_process(_delta: float) -> void:
	# Keep walking in the foreground of the supplied illustration.
	player.position = player.position.clamp(WALK_AREA.position, WALK_AREA.end)


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_R or event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		while Dialogue.active:
			Dialogue.advance()
		if event.keycode == KEY_R:
			get_tree().reload_current_scene()
		else:
			get_tree().change_scene_to_file("res://main_menu.tscn")


func _refresh_status(stage: int) -> void:
	status.text = "SOMETHING FEELS WRONG..." if stage >= 1 else "A QUIET MORNING"
	if stage >= 1:
		objective.text = "The eggs are collected. The color has drained away."


func _on_egg_taken(real: bool) -> void:
	if real:
		collected += 1
		objective.text = "Collect four real eggs in the meadow.  %d / 4" % collected


func _refresh_eggs(_by: Node) -> void:
	for egg: Egg in puzzle.get_children():
		if egg.opened and egg.is_safe:
			egg.hide()


func _on_failed() -> void:
	status.text = "THAT EGG WAS EMPTY."
	objective.text = "Press R to start fresh. Look closely at the darker eggs."
