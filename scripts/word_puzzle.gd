class_name WordPuzzle
extends Puzzle

@export var answer := "BROOK"
@export var title_text := "Notice Board"
@export var clue := "Where the water runs through the village."
@export var solved_message := "Something clicks open."
@export var wrong_message := "That doesn't seem right..."
@export var close_delay := 1.0

var _layer: CanvasLayer
var _field: LineEdit
var _feedback: Label
var _open := false


func _ready() -> void:
	if puzzle_id == &"":
		puzzle_id = &"town_hall_word"


func _on_start() -> void:
	if _open:
		return
	_open = true
	_build_ui()
	get_tree().paused = true
	_field.grab_focus()


func _on_reset() -> void:
	_close()


func _close() -> void:
	if not _open:
		return
	_open = false
	get_tree().paused = false
	if _layer:
		_layer.queue_free()
		_layer = null


func _scramble(word: String) -> String:
	var target := word.to_upper()
	var letters: Array = []
	for ch in target:
		letters.append(ch)
	var result := target
	for i in 10:
		letters.shuffle()
		result = " ".join(letters)
		if result.replace(" ", "") != target:
			break
	return result


func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 50
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_layer)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 0)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)

	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var clue_label := Label.new()
	clue_label.text = clue
	clue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	clue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(clue_label)

	var scrambled := Label.new()
	scrambled.text = _scramble(answer)
	scrambled.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scrambled.add_theme_font_size_override("font_size", 28)
	box.add_child(scrambled)

	_field = LineEdit.new()
	_field.placeholder_text = "Type the word, press Enter"
	_field.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_field.text_submitted.connect(_submit)
	_field.gui_input.connect(_on_field_input)
	box.add_child(_field)

	_feedback = Label.new()
	_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_feedback)

	var close_btn := Button.new()
	close_btn.text = "Close (Esc)"
	close_btn.pressed.connect(reset)
	box.add_child(close_btn)


func _on_field_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		reset()


func _submit(text: String) -> void:
	if text.strip_edges().to_upper() == answer.to_upper():
		_field.editable = false
		_feedback.text = solved_message
		await get_tree().create_timer(close_delay).timeout
		_close()
		complete()
	else:
		_feedback.text = wrong_message
		_field.clear()
