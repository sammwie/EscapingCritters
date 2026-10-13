class_name FarmManager
extends Node
## Drop one in a farm scene. Advances every FarmPlot when a day passes.
## For now, press N to skip a day (debug). Later, call end_day() from
## whatever owns the real day cycle (GameState / Coder 3).

signal day_advanced(day: int)

var day := 1
var harvest_counts := {}  # crop_id -> int

func _ready() -> void:
	# Count harvests so the future shop/inventory can read them.
	await get_tree().process_frame
	for plot in get_tree().get_nodes_in_group("farm_plots"):
		plot.harvested.connect(_on_harvested)

func end_day() -> void:
	day += 1
	for plot in get_tree().get_nodes_in_group("farm_plots"):
		plot.advance_day()
	day_advanced.emit(day)

func _on_harvested(crop_id: StringName) -> void:
	harvest_counts[crop_id] = harvest_counts.get(crop_id, 0) + 1

# DEBUG: remove once the real day cycle exists.
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_N:
		end_day()
		print("Day ", day)
