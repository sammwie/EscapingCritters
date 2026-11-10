class_name FarmPlot
extends Interactable
## One tile of farmland. Placeholder visuals: a colored square drawn in code.
## Scene: Area2D (this script) > CollisionShape2D (RectangleShape2D, 32x32).
## Collision: Layer 2 only, Mask empty.
##
## Loop: EMPTY -> (plant) -> PLANTED -> (water) -> WATERED
##       -> (a day passes) -> grows a step -> PLANTED again, until GROWN
##       -> (harvest) -> EMPTY

signal planted(crop_id: StringName)
signal watered
signal harvested(crop_id: StringName)
signal state_changed(new_state: int)

enum State { EMPTY, PLANTED, WATERED, GROWN }

@export var crop_id: StringName = &"carrot"
@export var days_to_grow := 3
@export var size := Vector2(32, 32)
## Draw a light, see-through patch of tilled soil instead of a solid square,
## for plots that sit on soil that is already painted into the map.
@export var soft_look := false

var state := State.EMPTY
var growth := 0

const COLORS := {
	State.EMPTY: Color("8b5a2b"),    # bare soil
	State.PLANTED: Color("a97c50"),  # dry, planted
	State.WATERED: Color("5a3b1c"),  # dark, wet soil
	State.GROWN: Color("5cb85c"),    # ready to harvest
}

func _ready() -> void:
	add_to_group("farm_plots")
	_refresh()

const SOFT_COLORS := {
	State.EMPTY: Color(0.33, 0.2, 0.1, 0.35),
	State.PLANTED: Color(0.33, 0.2, 0.1, 0.45),
	State.WATERED: Color(0.16, 0.09, 0.04, 0.6),
	State.GROWN: Color(0.33, 0.2, 0.1, 0.3),
}

func _draw() -> void:
	if soft_look:
		_draw_soft()
		return
	draw_rect(Rect2(-size / 2.0, size), COLORS[state])
	# Little progress pips so growth is visible without art.
	if state != State.EMPTY and state != State.GROWN:
		for i in growth:
			draw_circle(Vector2(-size.x / 2.0 + 6 + i * 8, size.y / 2.0 - 6), 2.5, Color.WHITE)

func _draw_soft() -> void:
	var r := Rect2(-size / 2.0, size)
	# rounded-off patch: a rect with its corners trimmed
	draw_rect(r.grow_individual(-1, 0, -1, 0), SOFT_COLORS[state])
	draw_rect(r.grow_individual(0, -1, 0, -1), SOFT_COLORS[state])
	# furrows
	var furrow := Color(0.12, 0.07, 0.03, 0.35)
	for i in 3:
		var y := r.position.y + (i + 1) * size.y / 4.0
		draw_line(Vector2(r.position.x + 2, y), Vector2(r.end.x - 2, y), furrow, 1.0)
	# a soft outline on empty plots while planting is possible, so the
	# player can see where to plant
	if state == State.EMPTY and enabled:
		draw_rect(r, Color(1, 0.97, 0.9, 0.55), false, 1.0)

func _on_interact(_by: Node) -> void:
	match state:
		State.EMPTY:
			_set_state(State.PLANTED)
			growth = 0
			planted.emit(crop_id)
		State.PLANTED:
			_set_state(State.WATERED)
			watered.emit()
		State.GROWN:
			var id := crop_id
			_set_state(State.EMPTY)
			growth = 0
			harvested.emit(id)
		State.WATERED:
			pass  # already watered, wait for the day to pass

# Called by FarmManager (or whatever owns the day cycle).
func advance_day() -> void:
	if state == State.WATERED:
		growth += 1
		if growth >= days_to_grow:
			_set_state(State.GROWN)
		else:
			_set_state(State.PLANTED)  # needs watering again tomorrow

func _set_state(new_state: State) -> void:
	state = new_state
	_refresh()
	state_changed.emit(state)

func _refresh() -> void:
	match state:
		State.EMPTY: prompt_text = "Plant"
		State.PLANTED: prompt_text = "Water"
		State.WATERED: prompt_text = "Growing..."
		State.GROWN: prompt_text = "Harvest"
	queue_redraw()
