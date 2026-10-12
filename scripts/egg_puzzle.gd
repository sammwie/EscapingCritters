class_name EggPuzzle
extends Puzzle
## Farm puzzle (DRAFT, defaults from the spec; designers have not confirmed).
## Put Egg nodes anywhere under this node. Take every real egg to solve it;
## taking a fake one fails the puzzle. Reports to WorldState via Puzzle.complete().
##
## Spec defaults: 6 eggs, 2 fake, puzzle_id "farm_eggs".

signal egg_taken(real: bool)

var _real_total := 0
var _real_taken := 0

func _ready() -> void:
	if puzzle_id == &"":
		puzzle_id = &"farm_eggs"
	start()

func _on_start() -> void:
	_real_total = 0
	_real_taken = 0
	for egg in _eggs():
		egg.enabled = true
		if egg.is_safe:
			_real_total += 1
		if not egg.revealed.is_connected(_on_revealed):
			egg.revealed.connect(_on_revealed)

func _on_reset() -> void:
	for egg in _eggs():
		egg.opened = false
		egg.prompt_text = "Take egg"
		egg.queue_redraw()

func _on_revealed(safe: bool) -> void:
	if state != State.ACTIVE:
		return
	egg_taken.emit(safe)
	if not safe:
		fail()  # whatever owns the day cycle decides what failing costs (spec Q5)
		return
	_real_taken += 1
	if _real_taken >= _real_total:
		complete()

func _eggs() -> Array[Egg]:
	var out: Array[Egg] = []
	for n in find_children("*", "Egg", true, false):
		out.append(n as Egg)
	return out
