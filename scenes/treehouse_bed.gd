class_name TreehouseBed
extends Interactable
## The bed in the treehouse. Press E to sleep, which ends the day.
## Placeholder visuals: a purple rectangle with the current day above it.
## Scene: Area2D (this script) > CollisionShape2D (RectangleShape2D, 48x32)
##                             > Node named "Treehouse" (treehouse.gd)
## Collision: Layer 2 only, Mask empty.
## Set farm_manager_path to a FarmManager in the same scene so sleeping
## advances the crops. This replaces the debug N key once wired up.

@export var size := Vector2(48, 32)
@export var farm_manager_path: NodePath

@onready var treehouse: Treehouse = get_node_or_null("Treehouse")

func _ready() -> void:
	prompt_text = "Sleep until morning"
	if treehouse == null:
		push_warning("TreehouseBed '%s' needs a child node named Treehouse." % name)

func _draw() -> void:
	draw_rect(Rect2(-size / 2.0, size), Color("7a5fb0"))
	draw_string(ThemeDB.fallback_font, Vector2(-size.x / 2.0, -size.y / 2.0 - 6.0), "Day %d" % GameState.current_day)

func _on_interact(_by: Node) -> void:
	if treehouse == null:
		return
	treehouse.rest()
	var fm := _farm_manager()
	if fm:
		fm.end_day()
	queue_redraw()

func _farm_manager() -> FarmManager:
	if farm_manager_path.is_empty():
		return null
	return get_node_or_null(farm_manager_path) as FarmManager
