class_name TaskPopup
extends CanvasLayer
## A "New task" card that slides down from the top of the screen, holds for a
## moment, then slides away. Any quest can call it whenever its task changes:
##     TaskPopup.show_task(self, "Run home!")
## Only one shows at a time; a new one replaces the old.

const FONT_REG := preload("res://art/fonts/Silkscreen-Regular.ttf")
const FONT_BOLD := preload("res://art/fonts/Silkscreen-Bold.ttf")
const CREAM := Color(1, 0.972549, 0.9098039)
const WOOD := Color(0.6509804, 0.45490196, 0.28235295)
const WOOD_DARK := Color(0.47058824, 0.32156864, 0.20392157)
const INK := Color(0.22745098, 0.15686275, 0.11764706)

@export var hold_time := 3.0

var _card: PanelContainer

static func show_task(host: Node, text: String, heading := "New Task") -> TaskPopup:
	for old in host.get_tree().get_nodes_in_group("task_popup"):
		old.queue_free()
	var popup := TaskPopup.new()
	host.add_child(popup)
	popup._play(heading, text)
	return popup

func _ready() -> void:
	add_to_group("task_popup")
	layer = 70

func _play(heading: String, text: String) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(CREAM, 0.97)
	style.border_color = WOOD
	style.set_border_width_all(6)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(18)
	style.shadow_color = Color(INK, 0.4)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 4)

	_card = PanelContainer.new()
	_card.add_theme_stylebox_override("panel", style)
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_card)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	_card.add_child(box)
	for pair in [[heading.to_upper(), FONT_BOLD, 18, WOOD_DARK], [text, FONT_REG, 22, INK]]:
		var label := Label.new()
		label.text = pair[0]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font", pair[1])
		label.add_theme_font_size_override("font_size", pair[2])
		label.add_theme_color_override("font_color", pair[3])
		box.add_child(label)

	# Size first, then centre it horizontally just above the top edge.
	await get_tree().process_frame
	var view := get_viewport().get_visible_rect().size
	var size := _card.get_combined_minimum_size()
	_card.size = size
	var shown_y := 24.0
	_card.position = Vector2((view.x - size.x) / 2.0, -size.y - 10.0)

	var tw := create_tween()
	tw.tween_property(_card, "position:y", shown_y, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(hold_time)
	tw.tween_property(_card, "position:y", -size.y - 10.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)
