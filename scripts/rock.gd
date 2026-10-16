class_name Rock
extends LyingObject
## A stepping stone in the puddle. Looks the same whether safe or not.
## The player tests it by jumping (Space, handled by PuddlePuzzle), which
## calls jump_test(). Unsafe rocks sink (dark) and the player sinks too,
## safe ones hold (green).
## Scene: Area2D (this script) > CollisionShape2D (CircleShape2D, radius ~12).
## Collision: Layer 2 only, Mask empty.
## is_safe is set by PuddlePuzzle at start, so leave it alone in the Inspector.

@export var hop_time := 0.35
@export var hop_height := 22.0

var tested := false
var _jumper: Node2D

func _ready() -> void:
	enabled = false  # no "Press E" prompt, jumping is the only way to test
	queue_redraw()

func _draw() -> void:
	var col := Color("9a9a9a")
	if tested:
		col = Color("6fbf73") if is_safe else Color("1d2b4a")  # holds / sinks
	draw_circle(Vector2.ZERO, 12.0, col)

# Called by PuddlePuzzle when the player jumps at this rock.
func jump_test(by: Node2D) -> void:
	if tested:
		return
	_jumper = by
	_on_interact(by)  # emits revealed(is_safe), then _play_reveal()

func _play_reveal() -> void:
	tested = true
	queue_redraw()
	if _jumper:
		_hop_player(_jumper)

func _hop_player(player: Node2D) -> void:
	var from := player.global_position
	var to := global_position
	player.set_meta("hopping", true)
	player.set_physics_process(false)
	var tw := create_tween()
	tw.tween_method(_hop_step.bind(player, from, to), 0.0, 1.0, hop_time)
	await tw.finished
	if is_safe:
		player.set_physics_process(true)
		player.set_meta("hopping", false)
	else:
		# Sinks. PuddlePuzzle respawns the player and clears "hopping".
		create_tween().tween_property(player, "modulate:a", 0.0, 0.3)

func _hop_step(t: float, player: Node2D, from: Vector2, to: Vector2) -> void:
	player.global_position = from.lerp(to, t) + Vector2(0, -sin(t * PI) * hop_height)

# Called by PuddlePuzzle when the puzzle restarts.
func reset_rock() -> void:
	tested = false
	queue_redraw()
