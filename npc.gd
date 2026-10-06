class_name NPC
extends Interactable
## Test villager. Press interact to start dialogue; press again to advance.

@export var dialogue: DialogueData

func _on_interact(_by: Node) -> void:
	if Dialogue.active:
		Dialogue.advance()
	elif dialogue:
		Dialogue.start(dialogue)
