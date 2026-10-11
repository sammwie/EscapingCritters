extends Node
## AUTOLOAD as "Dialogue". Your UI listens to the signals and shows the text.

signal line_shown(speaker: String, text: String)
signal finished
signal skip_typing  # asks the dialogue box to reveal the full line now

var _visits := {}  # npc_id -> int
var _queue: Array[DialogueLine] = []
var active := false
var line_typing := false  # set by the dialogue box while a line is typing out

func start(data: DialogueData) -> void:
	var visits: int = _visits.get(data.npc_id, 0)
	_visits[data.npc_id] = visits + 1

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
		finished.emit()
		return
	var line: DialogueLine = _queue.pop_front()
	var text := line.text
	if line.glitch or GameState.corruption_stage >= 3:
		text = _glitch(text, GameState.corruption_stage)
	line_shown.emit(line.speaker, text)

# Randomly swaps characters; more corruption = more scrambling.
func _glitch(text: String, stage: int) -> String:
	var chance := clampf(0.04 * stage, 0.02, 0.3)
	var junk := "#@%&?/\\0123456789"
	var out := ""
	for c in text:
		if c != " " and randf() < chance:
			out += junk[randi() % junk.length()]
		else:
			out += c
	return out
