extends CanvasLayer
## Pause menu. Press Esc (the built-in "ui_cancel" action) to pause and resume.
## Drop scenes/pause_menu.tscn into any gameplay scene, or autoload it.
## It ignores Esc in menu scenes (main_menu, splash, settings, credits).

const FONT_REG: FontFile = preload("res://art/fonts/Silkscreen-Regular.ttf")
const FONT_BOLD: FontFile = preload("res://art/fonts/Silkscreen-Bold.ttf")
const MAIN_MENU_PATH := "res://main_menu.tscn"
const NO_PAUSE_SCENES := ["main_menu", "splash", "settings", "credits"]

# Same palette as the Level 1 task list so everything matches.
const CREAM := Color("fff8e8")
const WOOD := Color("a67448")
const WOOD_LIGHT := Color("bf8a5c")
const WOOD_DARK := Color("785234")
const INK := Color("39281e")

var _root: Control
var _resume_button: Button

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS   # keep working while the game is paused
	_build_ui()
	_root.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not _is_menu_scene():
		toggle()
		get_viewport().set_input_as_handled()

func toggle() -> void:
	if _root.visible:
		resume()
	else:
		pause()

func pause() -> void:
	get_tree().paused = true
	_root.visible = true
	_resume_button.grab_focus()

func resume() -> void:
	get_tree().paused = false
	_root.visible = false

func _to_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_PATH)

func _quit_game() -> void:
	get_tree().quit()

func _is_menu_scene() -> bool:
	var scene := get_tree().current_scene
	return scene != null and NO_PAUSE_SCENES.has(scene.scene_file_path.get_file().get_basename())

func _build_ui() -> void:
	_root = Control.new()
	_root.name = "Root"
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.color = Color(0.06, 0.04, 0.03, 0.6)
	_root.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	_root.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(CREAM, 0.97)
	panel_style.border_color = WOOD
	panel_style.set_border_width_all(6)
	panel_style.set_corner_radius_all(12)
	panel_style.set_content_margin_all(28)
	panel_style.shadow_color = Color(INK, 0.45)
	panel_style.shadow_size = 6
	panel_style.shadow_offset = Vector2(0, 5)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(320, 0)
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)

	var title := Label.new()
	title.text = "Paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", FONT_BOLD)
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", WOOD_DARK)
	box.add_child(title)

	_resume_button = _make_button("Resume", resume)
	box.add_child(_resume_button)
	box.add_child(_make_button("Main Menu", _to_main_menu))
	box.add_child(_make_button("Quit Game", _quit_game))

	var hint := Label.new()
	hint.text = "Esc to resume"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_override("font", FONT_REG)
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", WOOD)
	box.add_child(hint)

func _make_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 52)
	button.add_theme_font_override("font", FONT_REG)
	button.add_theme_font_size_override("font_size", 22)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(color_name, CREAM)
	button.add_theme_stylebox_override("normal", _button_style(WOOD))
	button.add_theme_stylebox_override("hover", _button_style(WOOD_LIGHT))
	button.add_theme_stylebox_override("focus", _button_style(WOOD_LIGHT))
	button.add_theme_stylebox_override("pressed", _button_style(WOOD_DARK))
	button.pressed.connect(callback)
	return button

func _button_style(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = WOOD_DARK
	style.set_border_width_all(4)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16
	style.content_margin_right = 16
	return style
