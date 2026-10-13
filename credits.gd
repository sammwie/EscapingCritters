extends Control
## Credits page. The names live in SECTIONS below, so editing the credits means
## editing this list. Nothing else needs to change.

const MENU_SCENE := "res://main_menu.tscn"

# Each entry is one block on the page: a role heading and the people under it.
# TODO: swap "Your Name Here" for the real team names.
const SECTIONS := [
	{"role": "Game Design", "names": ["Your Name Here"]},
	{"role": "Programming", "names": ["Your Name Here", "Your Name Here", "Your Name Here"]},
	{"role": "Pixel Art", "names": ["Your Name Here"]},
	{"role": "Level Design", "names": ["Your Name Here"]},
	{"role": "Writing", "names": ["Your Name Here"]},
	{"role": "Made With", "names": ["Godot Engine", "LDtk Level Editor", "Silkscreen font by Jason Kottke"]},
]

func _ready() -> void:
	_build_entries()
	%BackButton.pressed.connect(_on_back_pressed)
	%BackButton.grab_focus()

func _build_entries() -> void:
	var grid: Container = %Entries
	for section in SECTIONS:
		var block := VBoxContainer.new()
		block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		block.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		block.add_theme_constant_override("separation", 6)
		grid.add_child(block)

		var role := Label.new()
		role.theme_type_variation = &"RoleLabel"
		role.text = String(section["role"]).to_upper()
		role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		block.add_child(role)

		for person in section["names"]:
			var name_label := Label.new()
			name_label.text = person
			name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			block.add_child(name_label)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back_pressed()
