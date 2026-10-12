class_name NPC
extends Interactable
## Villager. Press interact to start dialogue; press again to skip typing,
## then again to advance.
##
## Freeze hook: while this NPC is mid-conversation, `frozen` is true.
## Movement/AI scripts should check `frozen` (or override _on_frozen /
## _on_unfrozen). Any AnimatedSprite2D child is paused automatically.

@export var dialogue: DialogueData

var frozen := false

func _ready() -> void:
	Dialogue.line_started.connect(_on_line_started)
	Dialogue.conversation_ended.connect(_on_conversation_ended)

func _on_interact(_by: Node) -> void:
	if Dialogue.active:
		Dialogue.request_advance()
	elif dialogue:
		Dialogue.start(dialogue)

func _on_line_started(npc_id: String) -> void:
	if dialogue and npc_id == dialogue.npc_id and not frozen:
		frozen = true
		for child in get_children():
			if child is AnimatedSprite2D:
				child.pause()
		_on_frozen()

func _on_conversation_ended(npc_id: String) -> void:
	if dialogue and npc_id == dialogue.npc_id and frozen:
		frozen = false
		for child in get_children():
			if child is AnimatedSprite2D:
				child.play()
		_on_unfrozen()

# Override in subclasses (e.g. stop a patrol, face the player).
func _on_frozen() -> void:
	pass

func _on_unfrozen() -> void:
	pass
