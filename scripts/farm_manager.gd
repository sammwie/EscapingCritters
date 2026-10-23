class_name FarmManager
extends Node
## Drop one in a farm scene. Advances every FarmPlot when a day passes.
## The day itself lives in GameState (Coder 3): end_day() calls
## GameState.advance_day() and then grows every plot.
## The Bed calls end_day() through the "farm_manager" group when the player
## sleeps. Press N to skip a day, in debug builds only (editor runs).

signal day_advanced(day: int)

var harvest_counts := {}  # crop_id -> int

func _ready() -> void:
	add_to_group("farm_manager")
	# Count harvests so the future shop/inventory can read them.
	await get_tree().process_frame
	for plot in get_tree().get_nodes_in_group("farm_plots"):
		plot.harvested.connect(_on_harvested)

func end_day() -> void:
	if GameState.has_method("advance_day"):
		GameState.call("advance_day")
	else:
		GameState.current_day += 1  # fallback until advance_day is on main
	for plot in get_tree().get_nodes_in_group("farm_plots"):
		plot.advance_day()
	day_advanced.emit(GameState.current_day)

func _on_harvested(crop_id: StringName) -> void:
	harvest_counts[crop_id] = harvest_counts.get(crop_id, 0) + 1

# DEBUG only (editor runs, never in an exported game).
func _unhandled_key_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_N:
		end_day()
		print("Day ", GameState.current_day)
