class_name PatrolGuard
extends Node2D
## Walks back and forth between its start position and start + patrol_offset.
## Emits `spotted` if the player stays inside its vision cone and isn't hidden.

signal spotted

@export var patrol_offset := Vector2(0, 200)
@export var speed := 40.0
@export var wait_time := 0.8
@export var vision_range := 90.0
@export var vision_angle := 70.0      ## full cone angle, degrees
@export var spot_time := 0.35         ## seconds in the cone before you're caught
@export var body_color := Color(0.75, 0.3, 0.3)

var player: Node2D
var facing := Vector2.DOWN
var _start := Vector2.ZERO
var _going_out := true
var _wait := 0.0
var _seen_for := 0.0
var _active := true

func _ready() -> void:
	add_to_group("patrol_guard")
	_start = position
	if patrol_offset != Vector2.ZERO:
		facing = patrol_offset.normalized()

func reset_guard() -> void:
	position = _start
	_going_out = true
	_wait = 0.0
	_seen_for = 0.0
	_active = true
	if patrol_offset != Vector2.ZERO:
		facing = patrol_offset.normalized()
	queue_redraw()

func set_active(value: bool) -> void:
	_active = value

func _physics_process(delta: float) -> void:
	if not _active:
		return
	if _wait > 0.0:
		_wait -= delta
	else:
		var target := _start + patrol_offset if _going_out else _start
		var to_target := target - position
		if to_target.length() <= speed * delta:
			position = target
			_going_out = not _going_out
			_wait = wait_time
		else:
			facing = to_target.normalized()
			position += facing * speed * delta
	_check_player(delta)
	queue_redraw()

func _check_player(delta: float) -> void:
	if player == null:
		return
	var seen := false
	if not player.get_meta("hidden", false):
		var to_player := player.global_position - global_position
		if to_player.length() <= vision_range \
				and absf(rad_to_deg(facing.angle_to(to_player))) <= vision_angle * 0.5:
			seen = true
	if seen:
		_seen_for += delta
		if _seen_for >= spot_time:
			_seen_for = 0.0
			_active = false
			spotted.emit()
	else:
		_seen_for = maxf(0.0, _seen_for - delta)

func _draw() -> void:
	# Placeholder visuals (designers replace these).
	var half := deg_to_rad(vision_angle * 0.5)
	var base := facing.angle()
	var pts := PackedVector2Array([Vector2.ZERO])
	for i in 13:
		var a := base - half + (half * 2.0) * float(i) / 12.0
		pts.append(Vector2.from_angle(a) * vision_range)
	var alpha := 0.18 + 0.4 * clampf(_seen_for / spot_time, 0.0, 1.0)
	draw_colored_polygon(pts, Color(1.0, 0.2, 0.2, alpha))
	draw_circle(Vector2.ZERO, 8.0, body_color)
