class_name StoryInteractable
extends Interactable
## Interactable for story beats. Talks normally, then switches to a special
## conversation once a story flag is set (e.g. the Baker after the cat dies).

signal story_beat_finished

@export var dialogue: DialogueData          ## normal conversation
@export var story_dialogue: DialogueData    ## special one-time conversation
@export var active_flag := ""               ## only interactable once this flag is set ("" = always)
@export var required_flag := ""             ## story_dialogue plays only once this is set ("" = always)
@export var done_flag := ""                 ## set when the story conversation ends
@export var flicker_on_finish := true

# Fallback if GameState has no get_flag/set_flag yet (Coder 3 adds them).
static var _local_flags := {}

var _story_npc_id := ""

func _process(_delta: float) -> void:
	enabled = _flag_ok(active_flag)

func _on_interact(_by: Node) -> void:
	if Dialogue.active:
		Dialogue.request_advance()
		return
	var use_story := story_dialogue != null \
		and _flag_ok(required_flag) \
		and not (done_flag != "" and _get_flag(done_flag))
	var data: DialogueData = story_dialogue if use_story else dialogue
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
		_set_flag(done_flag, true)
	if flicker_on_finish:
		get_tree().call_group("glitch_overlay", "flicker", 0.8, 1.0)
	story_beat_finished.emit()

func _flag_ok(flag: String) -> bool:
	return flag == "" or _get_flag(flag)

func _get_flag(flag: String) -> bool:
	if GameState.has_method("get_flag"):
		return GameState.get_flag(flag)
	return _local_flags.get(flag, false)

func _set_flag(flag: String, value: bool) -> void:
	_local_flags[flag] = value
	if GameState.has_method("set_flag"):
		GameState.set_flag(flag, value)
