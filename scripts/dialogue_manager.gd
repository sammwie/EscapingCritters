extends Node
## AUTOLOAD as "Dialogue". Your UI listens to the signals and shows the text.

signal line_shown(speaker: String, text: String)
signal finished
signal skip_typing  # asks the dialogue box to reveal the full line now

# Freeze hook: NPCs listen to these, filtered by npc_id.
signal line_started(npc_id: String)
signal conversation_ended(npc_id: String)

var _visits := {}  # npc_id -> int
var _queue: Array[DialogueLine] = []
var active := false
var line_typing := false   # set by the dialogue box while a line is typing out
var current_npc_id := ""   # who we're talking to right now

func start(data: DialogueData) -> void:
	var visits: int = _visits.get(data.npc_id, 0)
	_visits[data.npc_id] = visits + 1
	current_npc_id = data.npc_id

	var source := data.lines
	if visits > 0 and not data.repeat_lines.is_empty():
		source = data.repeat_lines

	_queue.clear()
	for line in source:
		if GameState.corruption_stage >= line.min_corruption:
			_queue.append(line)
	active = true
	advance()

# Call this from interactions: skips typing first, then advances on the next press.
func request_advance() -> void:
	if line_typing:
		skip_typing.emit()
	else:
		advance()

func advance() -> void:
	if _queue.is_empty():
		active = false
		var id := current_npc_id
		current_npc_id = ""
		finished.emit()
		conversation_ended.emit(id)
		return
	var line: DialogueLine = _queue.pop_front()
	var text := line.text
	if line.glitch or GameState.corruption_stage >= 3:
		text = _glitch(text, GameState.corruption_stage)
	line_started.emit(current_npc_id)
	line_shown.emit(line.speaker, text)

const LOOKALIKES := {"A": "4", "E": "3", "I": "1", "O": "0", "S": "5", "T": "7", "B": "8", "G": "6"}

# Garbles some letters but keeps every word readable: only letters inside a
# word are swapped (never the first or last), never two in a row, and only
# for look-alike characters (O -> 0, E -> 3, ...).
func _glitch(text: String, stage: int) -> String:
	var chance := clampf(0.06 * stage, 0.06, 0.3)
	var out := ""
	var prev_swapped := false
	var count := text.length()
	for i in count:
		var c := text[i]
		var inside := i > 0 and i < count - 1 and text[i - 1] != " " and text[i + 1] != " "
		var key := c.to_upper()
		if inside and not prev_swapped and LOOKALIKES.has(key) and randf() < chance:
			out += LOOKALIKES[key]
			prev_swapped = true
		else:
			out += c
			prev_swapped = false
	return out
