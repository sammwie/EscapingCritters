class_name KnowsAllTentacle
extends Node2D
## One Knows All tentacle strike (placeholder art, drawn in code).
## SLAM: a circle on the floor flashes, then a tentacle crashes down on it.
## BAR:  a stripe across the arena flashes, then a tentacle sweeps it.
## Hits the player once, at the moment it lands. Moving out or dodge-rolling is safe.

enum Kind { SLAM, BAR }

const WARN := Color(0.62, 0.18, 0.78)
const BODY := Color(0.2, 0.08, 0.28)
const HOLD := 0.35

var kind := Kind.SLAM
var radius := 22.0
var bar_size := Vector2.ZERO
var telegraph := 0.8
var player: Node2D
var from_global := Vector2.ZERO

var _t := 0.0
var _struck := false

static func slam(parent: Node, boss_pos: Vector2, at: Vector2, p_player: Node2D, tele: float, rad := 22.0) -> KnowsAllTentacle:
	var t := KnowsAllTentacle.new()
	t.kind = Kind.SLAM
	t.radius = rad
	t.telegraph = tele
	t.player = p_player
	t.from_global = boss_pos
	t.add_to_group("ka_tentacle")
	parent.add_child(t)
	t.global_position = at
	return t

static func bar(parent: Node, boss_pos: Vector2, rect: Rect2, p_player: Node2D, tele: float) -> KnowsAllTentacle:
	var t := KnowsAllTentacle.new()
	t.kind = Kind.BAR
	t.bar_size = rect.size
	t.telegraph = tele
	t.player = p_player
	t.from_global = boss_pos
	t.add_to_group("ka_tentacle")
	parent.add_child(t)
	t.global_position = rect.get_center()
	return t

func _ready() -> void:
	z_index = 10

func _physics_process(delta: float) -> void:
	_t += delta
	if not _struck and _t >= telegraph:
		_strike()
	elif _struck and _t >= telegraph + HOLD:
		queue_free()
	queue_redraw()

func _strike() -> void:
	_struck = true
	if player == null or not is_instance_valid(player):
		return
	var p := player.global_position
	var inside := false
	if kind == Kind.SLAM:
		inside = p.distance_to(global_position) <= radius
	else:
		inside = Rect2(global_position - bar_size / 2.0, bar_size).has_point(p)
	CameraShake.go(player.get_node_or_null("Camera2D") as Camera2D, 2.5, 0.2)
	if inside:
		var combat := player.get_node_or_null("PlayerCombat") as PlayerCombat
		if combat:
			combat.take_damage(1, global_position)

func _draw() -> void:
	if not _struck:
		var progress := clampf(_t / telegraph, 0.0, 1.0)
		var pulse := 0.18 + 0.14 * sin(_t * 24.0)
		if kind == Kind.SLAM:
			draw_circle(Vector2.ZERO, radius, Color(WARN, pulse))
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(WARN, 0.9), 1.5)
			draw_arc(Vector2.ZERO, radius * 0.85, -PI / 2.0, -PI / 2.0 + TAU * progress, 32, Color(1, 1, 1, 0.85), 2.0)
		else:
			var r := Rect2(-bar_size / 2.0, bar_size)
			draw_rect(r, Color(WARN, pulse))
			draw_rect(r, Color(WARN, 0.9), false, 1.5)
		return
	var fade := 1.0 - clampf((_t - telegraph) / HOLD, 0.0, 1.0)
	if kind == Kind.SLAM:
		_draw_tentacle(to_local(from_global), fade)
		draw_circle(Vector2.ZERO, radius, Color(BODY, 0.85 * fade))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(WARN, fade), 2.0)
	else:
		draw_rect(Rect2(-bar_size / 2.0, bar_size), Color(BODY, 0.85 * fade))

func _draw_tentacle(base: Vector2, fade: float) -> void:
	var segments := 14
	var perp := (-base).orthogonal().normalized()
	var prev := base
	for i in range(1, segments + 1):
		var u := float(i) / segments
		var p := base.lerp(Vector2.ZERO, u)
		p += perp * sin(u * PI * 2.0 + _t * 18.0) * 7.0 * sin(u * PI)
		draw_line(prev, p, Color(BODY, fade), lerpf(9.0, 4.0, u))
		prev = p
