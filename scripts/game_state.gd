extends Node
## Autoload as GameState. Shared data and hooks; level owners supply scene paths.

signal corruption_changed(stage: int)
signal level_changed(level: int)
signal flag_changed(flag_name: String, value: bool)
signal day_changed(day: int)
signal night_changed(night: bool)
signal puzzle_solved(puzzle_id: StringName)
signal task_added(id: StringName, text: String)
signal task_completed(id: StringName)
signal tasks_changed
signal current_task_changed(task: Dictionary)

const STORY_FLAGS := ["note_read", "slept", "cat_dead", "baker_confronted", "hid_from_villagers", "pond_lost"]

var current_level := 1:
	set(value):
		if current_level == value:
			return
		current_level = value
		level_changed.emit(current_level)
		if current_level == 3 and not _resetting and not level3_scene_path.is_empty():
			_load_level3.call_deferred()
var current_day := 1
var is_night := false
var corruption_stage := 0:
	set(value):
		value = maxi(value, 0)
		if corruption_stage == value:
			return
		corruption_stage = value
		corruption_changed.emit(value)
		if is_inside_tree() and not _resetting:
			get_tree().call_group("glitch_overlay", "flicker")

# Assigned by the level owner; there is deliberately no substitute map.
var level3_scene_path := ""
var flags: Dictionary = {
	"note_read": false, "slept": false, "cat_dead": false,
	"baker_confronted": false, "hid_from_villagers": false, "pond_lost": false,
}
# Fixed within one playthrough; randomized for a new one.
var puzzle_seed := 0
var solved_puzzles: Dictionary = {}
var tasks: Array[Dictionary] = []
var current_task: Dictionary:
	get:
		for task in tasks:
			if not task.completed:
				return task.duplicate(true)
		return {}
var transition = SceneFade.new()
var _resetting := false

func _ready() -> void:
	add_child(transition)

func get_flag(flag_name: String) -> bool:
	return flags.get(flag_name, false)

func set_flag(flag_name: String, value: bool) -> void:
	if flag_name.is_empty() or get_flag(flag_name) == value:
		return
	flags[flag_name] = value
	flag_changed.emit(flag_name, value)

func set_night(value: bool) -> void:
	if is_night == value:
		return
	is_night = value
	night_changed.emit(is_night)

func advance_day() -> void:
	current_day += 1
	set_flag("slept", true)
	# The GDD's story overnight follows the Butcher note, not earlier farm sleeps.
	if get_flag("note_read"):
		set_flag("cat_dead", true)
	set_night(false)
	day_changed.emit(current_day)

func set_progress(level: int, stage: int) -> void:
	corruption_stage = stage
	current_level = level

func set_corruption_stage(stage: int) -> void:
	corruption_stage = stage

func mark_solved(puzzle_id: StringName) -> void:
	if puzzle_id == &"" or is_solved(puzzle_id):
		return
	solved_puzzles[puzzle_id] = true
	if puzzle_id == &"hiding":
		set_flag("hid_from_villagers", true)
	# Solving the pond is separate from its scripted loss.
	puzzle_solved.emit(puzzle_id)

func is_solved(puzzle_id: StringName) -> bool:
	return solved_puzzles.has(puzzle_id)

func add_task(id: StringName, text: String) -> void:
	if id == &"":
		return
	for task in tasks:
		if task.id == id:
			return
	var previous := current_task
	tasks.append({"id": id, "text": text, "completed": false})
	task_added.emit(id, text)
	_notify_tasks(previous)

func complete_task(id: StringName) -> void:
	for task in tasks:
		if task.id == id and not task.completed:
			var previous := current_task
			task.completed = true
			task_completed.emit(id)
			_notify_tasks(previous)
			return

func get_current_task() -> Dictionary:
	return current_task

func _notify_tasks(previous: Dictionary) -> void:
	tasks_changed.emit()
	if current_task != previous:
		current_task_changed.emit(current_task)

func configure_level3_scene(path: String) -> Error:
	if not ResourceLoader.exists(path, "PackedScene"):
		return ERR_FILE_NOT_FOUND
	level3_scene_path = path
	if current_level == 3:
		_load_level3.call_deferred()
	return OK

func _load_level3() -> void:
	while transition.busy:
		await transition.finished
	if current_level != 3 or level3_scene_path.is_empty():
		return
	var scene := get_tree().current_scene
	if scene == null or scene.scene_file_path != level3_scene_path:
		await change_scene(level3_scene_path)

func change_scene(path: String, spawn_at := "", duration := 0.35) -> Error:
	return await transition.change_scene(path, spawn_at, duration)

func swap_time_map(night: bool, path: String, spawn_at := "", duration := 0.35) -> Error:
	return await transition.change_scene(path, spawn_at, duration, set_night.bind(night))

func finish_pond_loss(path: String, level: int, stage: int, duration := 0.35) -> Error:
	return await transition.change_scene(path, "", duration, _record_pond_loss.bind(level, stage))

func _record_pond_loss(level: int, stage: int) -> void:
	set_flag("pond_lost", true)
	set_progress(level, stage)

func new_playthrough() -> void:
	_resetting = true
	puzzle_seed = randi()
	current_level = 1
	current_day = 1
	corruption_stage = 0
	for flag_name in flags.keys():
		set_flag(flag_name, false)
	flags.clear()
	for flag_name in STORY_FLAGS:
		flags[flag_name] = false
	set_night(false)
	solved_puzzles.clear()
	tasks.clear()
	_resetting = false
	day_changed.emit(current_day)
	tasks_changed.emit()
	current_task_changed.emit({})


class SceneFade extends CanvasLayer:
	## Owned by GameState so the fade survives the outgoing scene.

	signal finished
	var busy := false
	var _black: ColorRect
	var _was_paused := false

	func _ready() -> void:
		layer = 200
		process_mode = Node.PROCESS_MODE_ALWAYS
		_black = ColorRect.new()
		_black.color = Color(0, 0, 0, 0)
		_black.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(_black)
		_black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_black.hide()

	func _input(_event: InputEvent) -> void:
		if busy:
			get_viewport().set_input_as_handled()

	func change_scene(path: String, spawn_at := "", duration := 0.35, on_black := Callable()) -> Error:
		if busy:
			return ERR_BUSY
		if not ResourceLoader.exists(path, "PackedScene"):
			return ERR_FILE_NOT_FOUND
		var packed := load(path) as PackedScene
		if packed == null or not packed.can_instantiate():
			return ERR_CANT_CREATE
		_begin()
		await _fade(1.0, duration)
		if on_black.is_valid():
			on_black.call()
		var root := get_tree().root
		if not spawn_at.is_empty():
			root.set_meta("spawn_at", spawn_at)
		var result := get_tree().change_scene_to_packed(packed)
		if result == OK:
			await get_tree().scene_changed
			await get_tree().process_frame
		elif not spawn_at.is_empty():
			root.remove_meta("spawn_at")
		await _fade(0.0, duration)
		_end()
		return result

	func fade_action(action: Callable, duration := 0.35) -> void:
		while busy:
			await finished
		if not action.is_valid():
			return
		_begin()
		await _fade(1.0, duration)
		if action.is_valid():
			action.call()
		await _fade(0.0, duration)
		_end()

	func _begin() -> void:
		busy = true
		_was_paused = get_tree().paused
		get_tree().paused = true
		_black.show()

	func _fade(alpha: float, duration: float) -> void:
		var tween := create_tween()
		tween.tween_property(_black, "color:a", alpha, maxf(duration, 0.001))
		await tween.finished

	func _end() -> void:
		_black.hide()
		get_tree().paused = _was_paused
		busy = false
		finished.emit()
