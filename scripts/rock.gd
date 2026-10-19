class_name Rock
extends LyingObject
## A stepping stone in the puddle. Looks the same whether safe or not.
## The player tests it by jumping (handled by PuddlePuzzle), which calls
## jump_test(). Unsafe rocks sink (dark) and the player sinks too, safe ones
## hold (green). `targeted` shows a white ring: the rock a jump would hit.
## Scene: Area2D (this script) > CollisionShape2D (CircleShape2D, radius ~12).
## Collision: Layer 2 only, Mask empty.
## is_safe is set by PuddlePuzzle at start, so leave it alone in the Inspector.

@export var hop_time := 0.35
@export var hop_height := 22.0
@export var radius := 13.0

var tested := false
var targeted := false:
	set(v):
		if v != targeted:
			targeted = v
			queue_redraw()
var _jumper: Node2D
var _squash := 1.3   # each rock is a slightly different oval
var _size_mult := 1.0

func _ready() -> void:
	enabled = false  # no "Press E" prompt, jumping is the only way to test
	var h := absi(hash(String(name)))
	_squash = 1.2 + float(h % 30) / 100.0          # 1.20 to 1.49 wide
	_size_mult = 0.9 + float((h / 7) % 25) / 100.0  # 0.90 to 1.14 size
	queue_redraw()

func _draw() -> void:
	var r := radius * _size_mult
	var body := Color("9a9a9a")
	var rim := Color("6a6a70")
	var top := Color("b8b8bc")
	if tested:
		if is_safe:
			body = Color("6fbf73")
			rim = Color("3f8f48")
			top = Color("9bd99f")
		else:
			body = Color("1d2b4a")
			rim = Color("101a30")
			top = Color("2a3d66")
	draw_set_transform(Vector2(0, 2), 0.0, Vector2(_squash, 1.0))
	draw_arc(Vector2.ZERO, r + 4.0, 0.0, TAU, 28, Color(0.75, 0.92, 1.0, 0.55), 1.5)  # water ripple
	draw_circle(Vector2.ZERO, r + 1.5, rim)
	draw_circle(Vector2(0, -1), r, body)
	draw_circle(Vector2(-r * 0.2, -r * 0.35), r * 0.55, top)
	if targeted and not tested:
		draw_arc(Vector2.ZERO, r + 8.0, 0.0, TAU, 32, Color.WHITE, 2.5)  # jump target
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# Called by PuddlePuzzle when the player jumps at this rock.
func jump_test(by: Node2D) -> void:
	if tested:
		return
	_jumper = by
	targeted = false
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
		# Stay locked on the rock: PuddlePuzzle keeps the player's movement
		# off while it stands on a safe rock. Only hopping moves it.
		player.set_meta("hopping", false)
	else:
		# Sinks. PuddlePuzzle respawns the player and clears "hopping".
		create_tween().tween_property(player, "modulate:a", 0.0, 0.3)

func _hop_step(t: float, player: Node2D, from: Vector2, to: Vector2) -> void:
	player.global_position = from.lerp(to, t) + Vector2(0, -sin(t * PI) * hop_height)

# Called by PuddlePuzzle when the puzzle restarts.
func reset_rock() -> void:
	tested = false
	targeted = false
	queue_redraw()
