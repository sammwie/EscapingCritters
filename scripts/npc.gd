class_name NPC
extends Interactable
## Test villager. Press interact to start dialogue; press again to skip
## typing, then again to advance.

@export var dialogue: DialogueData

func _on_interact(_by: Node) -> void:
	if Dialogue.active:
		Dialogue.request_advance()
	elif dialogue:
		Dialogue.start(dialogue)
