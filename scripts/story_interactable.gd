class_name StoryInteractable
extends Interactable
## Interactable for story beats. Talks normally, then switches to a special
## conversation once a story flag is set (e.g. the Baker after the cat dies).
##
## use_parent_dialogue: when this is a child of an NPC, the normal
## conversation is whatever dialogue the parent NPC currently has. Quest
## scripts that swap the NPC's dialogue (like Level 1's Baker lines) keep working.

signal story_beat_finished

@export var dialogue: DialogueData          ## normal conversation
@export var story_dialogue: DialogueData    ## special one-time conversation
@export var use_parent_dialogue := false    ## use the parent NPC's current dialogue as the normal one
@export var active_flag := ""               ## only interactable once this flag is set ("" = always)
@export var required_flag := ""             ## story_dialogue plays only once this is set ("" = always)
@export var done_flag := ""                 ## set when the story conversation ends
@export var flicker_on_finish := true

# Fallback if GameState has no get_flag/set_flag yet (Coder 3 adds them).
static var _local_flags := {}

var _story_npc_id := ""

# Public helpers so other scripts (e.g. PetCat) share the same flags.
static func get_story_flag(flag: String) -> bool:
	if GameState.has_method("get_flag"):
		return GameState.get_flag(flag)
	return _local_flags.get(flag, false)

static func set_story_flag(flag: String, value: bool) -> void:
	_local_flags[flag] = value
	if GameState.has_method("set_flag"):
		GameState.set_flag(flag, value)

func _process(_delta: float) -> void:
	enabled = _flag_ok(active_flag)

func _on_interact(_by: Node) -> void:
	if Dialogue.active:
		Dialogue.request_advance()
		return
	var use_story := story_dialogue != null \
		and _flag_ok(required_flag) \
		and not (done_flag != "" and get_story_flag(done_flag))
	var normal: DialogueData = dialogue
	if use_parent_dialogue:
		var parent_node := get_parent()
		if parent_node != null and "dialogue" in parent_node and parent_node.dialogue != null:
			normal = parent_node.dialogue
	var data: DialogueData = story_dialogue if use_story else normal
	if data == null:
		return
	if use_story:
		_story_npc_id = data.npc_id
		if not Dialogue.conversation_ended.is_connected(_on_conversation_ended):
			Dialogue.conversation_ended.connect(_on_conversation_ended)
	Dialogue.start(data)

func _on_conversation_ended(npc_id: String) -> void:
	if npc_id != _story_npc_id:
		return
	Dialogue.conversation_ended.disconnect(_on_conversation_ended)
	if done_flag != "":
		set_story_flag(done_flag, true)
	if flicker_on_finish:
		get_tree().call_group("glitch_overlay", "flicker", 0.8, 1.0)
	story_beat_finished.emit()

func _flag_ok(flag: String) -> bool:
	return flag == "" or get_story_flag(flag)
