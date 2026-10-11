extends Node
## AUTOLOAD as "GameState" (Project Settings > Globals). Agree on this with Coder 1.

signal corruption_changed(stage: int)

var current_level := 1
var current_day := 1
var corruption_stage := 0:
	set(value):
		corruption_stage = value
		corruption_changed.emit(value)

# Puddle puzzle: fixed within a playthrough, re-randomized on a new one.
var puzzle_seed := 0

func new_playthrough() -> void:
	puzzle_seed = randi()
	current_level = 1
	current_day = 1
	corruption_stage = 0
