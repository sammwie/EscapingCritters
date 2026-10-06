class_name DialogueData
extends Resource
## One per NPC. Create in the editor: right-click > New Resource > DialogueData.

@export var npc_id := ""
@export var lines: Array[DialogueLine] = []         # first conversation
@export var repeat_lines: Array[DialogueLine] = []  # later conversations
