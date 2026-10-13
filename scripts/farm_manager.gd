class_name FarmManager
extends Node
## Drop one in a farm scene. Advances every FarmPlot when a day passes.
## The day itself lives in GameState (Coder 3): end_day() calls
## GameState.advance_day() and then grows every plot.
## Press N to skip a day (debug) until a real day trigger calls end_day().

signal day_advanced(day: int)

var harvest_counts := {}  # crop_id -> int

func _ready() -> void:
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

# DEBUG: remove once the real day cycle exists.
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_N:
		end_day()
		print("Day ", GameState.current_day)
