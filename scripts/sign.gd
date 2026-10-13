class_name Sign
extends Interactable
## A readable sign. Shows its text through the normal dialogue box.
## Scene: Area2D (this script) > Sprite2D + CollisionShape2D. Layer 2, mask empty.

@export var speaker := "Sign"
@export_multiline var text := "..."

var _data: DialogueData

func _ready() -> void:
	prompt_text = "Read"
	var line := DialogueLine.new()
	line.speaker = speaker
	line.text = text
	_data = DialogueData.new()
	_data.npc_id = "sign_%s" % get_path()
	_data.lines.append(line)

func _on_interact(_by: Node) -> void:
	if Dialogue.active:
		Dialogue.request_advance()
	else:
		Dialogue.start(_data)
