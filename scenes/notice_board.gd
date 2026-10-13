class_name NoticeBoard
extends Interactable
## The notice board in the town square. Press E to read today's
## announcement through the normal dialogue box.
## Placeholder visuals: a tan rectangle.
## Scene: Area2D (this script) > CollisionShape2D (RectangleShape2D, 48x32)
##                             > Node named "TownSquare" (town_square.gd)
## Collision: Layer 2 only, Mask empty.
## Uses GameState.current_day to pick the announcement.

@export var speaker := "Notice Board"
@export var size := Vector2(48, 32)

@onready var town_square: TownSquare = get_node_or_null("TownSquare")

func _ready() -> void:
	prompt_text = "Read"
	if town_square == null:
		push_warning("NoticeBoard '%s' needs a child node named TownSquare." % name)

func _draw() -> void:
	draw_rect(Rect2(-size / 2.0, size), Color("c9a66b"))

func _on_interact(_by: Node) -> void:
	if Dialogue.active:
		Dialogue.request_advance()
		return
	if town_square == null:
		return
	var line := DialogueLine.new()
	line.speaker = speaker
	line.text = town_square.announcement_for_day(GameState.current_day)
	var data := DialogueData.new()
	data.npc_id = "notice_board_%s_day%d" % [get_path(), GameState.current_day]
	data.lines.append(line)
	data.repeat_lines.append(line)  # reading it again shows the same text
	Dialogue.start(data)
