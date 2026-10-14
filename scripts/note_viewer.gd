class_name NoteViewer
extends CanvasLayer
## A readable parchment page. NoteViewer.open_note(host, title, body) shows one
## note; NoteViewer.open_log(host) shows every note the player has found.
## Press E, Esc or Enter to close. The player is frozen while it is open.

signal closed

const THEME := preload("res://ui/menu_theme.tres")

var _frozen: Array[Node] = []

static func open_note(host: Node, title: String, body: String) -> NoteViewer:
	var viewer := NoteViewer.new()
	host.add_child(viewer)
	viewer._build([{"title": title, "body": body}], false)
	return viewer

static func open_log(host: Node) -> NoteViewer:
	var viewer := NoteViewer.new()
	host.add_child(viewer)
	viewer._build(NotesLog.entries, true)
	return viewer

func _ready() -> void:
	layer = 80
	add_to_group("note_viewer")
	for node in get_tree().get_nodes_in_group("player"):
		if node.is_physics_processing():
			node.set_physics_process(false)
			_frozen.append(node)

func _build(notes: Array, is_log: bool) -> void:
	var root := Control.new()
	root.theme = THEME
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var dim := ColorRect.new()
	dim.color = Color(0.1, 0.07, 0.05, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var panel := PanelContainer.new()
	panel.theme_type_variation = &"ParchmentPanel"
	panel.custom_minimum_size = Vector2(1000, 0)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	panel.add_child(box)

	var heading := Label.new()
	heading.theme_type_variation = &"TitleLabel"
	heading.add_theme_font_size_override("font_size", 48)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.text = "NOTES" if is_log else String(notes[0]["title"]).to_upper()
	box.add_child(heading)
	box.add_child(HSeparator.new())

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 26)
	if is_log:
		var scroll := ScrollContainer.new()
		scroll.custom_minimum_size = Vector2(0, 460)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.add_child(list)
		list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_child(scroll)
	else:
		box.add_child(list)

	if notes.is_empty():
		var empty := Label.new()
		empty.text = "You haven't found any notes yet."
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		list.add_child(empty)
	for entry in notes:
		if is_log:
			var name_label := Label.new()
			name_label.theme_type_variation = &"RoleLabel"
			name_label.text = String(entry["title"]).to_upper()
			list.add_child(name_label)
		var text := Label.new()
		text.text = entry["body"]
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.custom_minimum_size = Vector2(880, 0)
		text.add_theme_font_size_override("font_size", 26 if is_log else 30)
		list.add_child(text)

	box.add_child(HSeparator.new())
	var hint := Label.new()
	hint.text = "E / Esc : close"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 22)
	hint.modulate = Color(1, 1, 1, 0.7)
	box.add_child(hint)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept") or event.is_action_pressed("notes"):
		get_viewport().set_input_as_handled()
		_close()

func _close() -> void:
	for node in _frozen:
		if is_instance_valid(node):
			node.set_physics_process(true)
	closed.emit()
	queue_free()
