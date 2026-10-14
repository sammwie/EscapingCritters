class_name LoreNote
extends Interactable
## A torn note lying on the ground. Press E to read it. Reading adds it to
## NotesLog (press N to read all notes again) and emits read_done.

signal read_done

@export var note_id := "butcher_note"
@export var title := "Torn Note"
@export_multiline var body := ""

var _t := 0.0

func _ready() -> void:
	prompt_text = "Read note"
	collision_layer = 2
	collision_mask = 0
	if get_child_count() == 0:
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 9.0
		shape.shape = circle
		add_child(shape)

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _draw() -> void:
	var bob := sin(_t * 3.0) * 1.2
	# soft glow so it reads from across the arena
	var glow := 0.18 + 0.1 * sin(_t * 4.0)
	draw_circle(Vector2(0, bob), 11.0, Color(1, 0.85, 0.4, glow))
	# paper with a torn corner
	var paper := PackedVector2Array([
		Vector2(-5, -6 + bob), Vector2(5, -6 + bob), Vector2(5, 3 + bob),
		Vector2(2, 6 + bob), Vector2(-1, 4 + bob), Vector2(-5, 6 + bob),
	])
	draw_colored_polygon(paper, Color(1, 0.96, 0.87))
	draw_polyline(paper + PackedVector2Array([paper[0]]), Color(0.47, 0.32, 0.20), 1.0)
	for i in 3:
		draw_line(Vector2(-3, -3 + i * 3 + bob), Vector2(3, -3 + i * 3 + bob), Color(0.23, 0.16, 0.12), 1.0)

func _on_interact(_by: Node) -> void:
	enabled = false
	NotesLog.add(note_id, title, body)
	var viewer := NoteViewer.open_note(get_tree().current_scene, title, body)
	await viewer.closed
	read_done.emit()
	queue_free()
