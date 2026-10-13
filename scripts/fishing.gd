class_name Fishing
extends Activity
## Fishing logic only (no visuals). Cast, wait a random time, then a short
## bite window where you must reel in. Too early or too late = missed.
## Other systems (shop, inventory) listen to `caught` or read `catch_counts`.
## Put this as a child Node of a FishingSpot.

signal bite
signal caught(fish_id: StringName)
signal missed
signal state_changed(new_state: int)

enum State { IDLE, WAITING, BITE }

@export var fish_table: Array[StringName] = [&"minnow", &"trout", &"old_boot"]
@export var min_wait := 2.0
@export var max_wait := 5.0
@export var bite_window := 1.2

var state := State.IDLE
var catch_counts := {}  # fish_id -> int

var _timer: Timer
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	if activity_id == &"":
		activity_id = &"fishing"
	_rng.randomize()
	_timer = Timer.new()
	_timer.one_shot = true
	add_child(_timer)
	_timer.timeout.connect(_on_timer_timeout)

func _on_start() -> void:
	_set_state(State.WAITING)
	_timer.start(_rng.randf_range(min_wait, max_wait))

# Called when the player presses E while fishing.
func reel() -> void:
	match state:
		State.WAITING:
			_end_miss()  # reeled in too early
		State.BITE:
			_end_catch()

func _on_timer_timeout() -> void:
	match state:
		State.WAITING:
			_set_state(State.BITE)
			bite.emit()
			_timer.start(bite_window)
		State.BITE:
			_end_miss()  # too slow

func _end_catch() -> void:
	_timer.stop()
	var id: StringName = &"fish"
	if not fish_table.is_empty():
		id = fish_table[_rng.randi() % fish_table.size()]
	catch_counts[id] = catch_counts.get(id, 0) + 1
	caught.emit(id)
	finish({"caught": true, "fish_id": id})

func _end_miss() -> void:
	_timer.stop()
	missed.emit()
	finish({"caught": false})

func _on_finish(_result: Dictionary) -> void:
	_set_state(State.IDLE)

func _set_state(new_state: State) -> void:
	state = new_state
	state_changed.emit(state)
