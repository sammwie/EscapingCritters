class_name KnowsAllBoss
extends Node2D
## Knows All, the final boss (Level 4). He sits at one end of the arena and
## attacks with tentacles. Every attack is telegraphed (purple warning on the floor).
##
## Phase 1: single and double slams.
## Phase 2: triple slams and sweeping bars across the arena.
## Phase 3: fast slam chains, double bars and a shockwave ring (dodge-roll through it).
##
## Usage: add it to the level, then call begin_intro(player) and
## begin_fight(player, arena_rect). KnowsAllArena does this for you.
## Final art: put a PNG at res://art/knows_all/boss.png and it is used automatically.

signal health_changed(hp: int, max_hp: int)
signal phase_changed(phase: int)
signal intro_finished
signal defeated(at: Vector2)

enum Mode { IDLE, INTRO, FIGHT, DEAD }

const ART_FOLDER := "res://art/knows_all/walk"
const DIRS := ["east", "south-east", "south", "south-west", "west", "north-west", "north", "north-east"]
const WARN := Color(0.62, 0.18, 0.78)
const BODY := Color(0.14, 0.06, 0.2)
const FONT := preload("res://art/fonts/Silkscreen-Bold.ttf")
const RING_SPEED := 110.0

@export var max_hp := 24
@export var phase2_at := 0.66
@export var phase3_at := 0.33
@export var sprite_scale := 1.0
@export var walk_fps := 8.0

var hp := 24
var phase := 1
var hit_radius := 26.0
var mode := Mode.IDLE
var target: Node2D = null
var arena := Rect2()

var _anim: AnimatedSprite2D
var _facing := ""
var _cooldown := 1.5
var _attack_id := 0
var _busy := false
var _ring_warn := 0.0
var _ring_r := -1.0
var _ring_hit := false
var _t := 0.0

func _ready() -> void:
	add_to_group("enemy")
	z_index = 5
	hp = max_hp
	_build_sprite()


func _build_sprite() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var found := false
	for dir in DIRS:
		var list: Array[Texture2D] = []
		var i := 0
		while true:
			var path := "%s/%s/frame_%03d.png" % [ART_FOLDER, dir, i]
			if not ResourceLoader.exists(path):
				break
			list.append(load(path) as Texture2D)
			i += 1
		if list.is_empty():
			continue
		frames.add_animation(dir)
		frames.set_animation_speed(dir, walk_fps)
		frames.set_animation_loop(dir, true)
		for tex in list:
			frames.add_frame(dir, tex)
		found = true
	if not found:
		return
	_anim = AnimatedSprite2D.new()
	_anim.sprite_frames = frames
	_anim.scale = Vector2.ONE * sprite_scale
	_anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_anim)
	_face(Vector2.DOWN)

func _face(v: Vector2) -> void:
	if _anim == null or v.length() < 0.01:
		return
	var dir: String = DIRS[wrapi(roundi(v.angle() / (PI / 4.0)), 0, 8)]
	if dir == _facing or not _anim.sprite_frames.has_animation(dir):
		return
	_facing = dir
	_anim.play(dir)

# ---------- modes ----------

func begin_intro(player: Node2D) -> void:
	target = player
	mode = Mode.INTRO
	hp = max_hp
	phase = 1
	scale = Vector2.ONE * 0.2
	modulate.a = 0.0
	var rise := create_tween().set_parallel(true)
	rise.tween_property(self, "scale", Vector2.ONE, 1.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	rise.tween_property(self, "modulate:a", 1.0, 1.2)
	CameraShake.go(player.get_node_or_null("Camera2D") as Camera2D, 3.0, 1.6)
	get_tree().call_group("glitch_overlay", "flicker", 1.2, 1.0)
	await rise.finished
	intro_finished.emit()

func begin_fight(player: Node2D, rect: Rect2) -> void:
	target = player
	arena = rect
	mode = Mode.FIGHT
	hp = max_hp
	phase = 1
	_cooldown = 1.2
	_busy = false
	health_changed.emit(hp, max_hp)

## Starts the fight over (used after the player is defeated).
func reset_fight() -> void:
	_stop_attacks()
	hp = max_hp
	phase = 1
	mode = Mode.FIGHT
	_cooldown = 1.3
	modulate = Color.WHITE
	scale = Vector2.ONE
	health_changed.emit(hp, max_hp)

## Freezes the fight in place (used while the "try again" message shows).
func hold_still() -> void:
	_stop_attacks()
	_cooldown = 99.0

func _stop_attacks() -> void:
	_attack_id += 1
	_busy = false
	_ring_r = -1.0
	_ring_warn = 0.0
	for t in get_tree().get_nodes_in_group("ka_tentacle"):
		t.queue_free()

# ---------- loop ----------

func _physics_process(delta: float) -> void:
	_t += delta
	if is_instance_valid(target):
		_face(target.global_position - global_position)
	_ring_warn = maxf(_ring_warn - delta, 0.0)
	if mode == Mode.FIGHT and is_instance_valid(target):
		_cooldown -= delta
		if _cooldown <= 0.0 and not _busy:
			_start_attack()
		_update_ring(delta)
	queue_redraw()

func _tele() -> float:
	return [0.95, 0.8, 0.65][phase - 1]

func _pause() -> float:
	match phase:
		1:
			return randf_range(1.8, 2.4)
		2:
			return randf_range(1.3, 1.8)
	return randf_range(0.9, 1.3)

func _options_for_phase() -> Array:
	match phase:
		1:
			return ["slam", "slam", "slam2"]
		2:
			return ["slam2", "slam3", "bar", "bar"]
	return ["slam3", "slam4", "bars", "ring", "ring"]

func _alive(id: int) -> bool:
	return id == _attack_id and mode == Mode.FIGHT and is_instance_valid(target)

func _wait(id: int, seconds: float) -> bool:
	await get_tree().create_timer(seconds).timeout
	return _alive(id)

func _start_attack() -> void:
	_busy = true
	_attack_id += 1
	var id := _attack_id
	var pick: String = _options_for_phase().pick_random()
	match pick:
		"slam":
			await _atk_slams(id, 1, 0.0)
		"slam2":
			await _atk_slams(id, 2, 0.7)
		"slam3":
			await _atk_slams(id, 3, 0.5)
		"slam4":
			await _atk_slams(id, 4, 0.4)
		"bar":
			await _atk_bars(id, 1, 0.0)
		"bars":
			await _atk_bars(id, 2, 0.6)
		"ring":
			await _atk_ring(id)
	if id == _attack_id:
		_busy = false
		_cooldown = _pause()

# ---------- attacks ----------

func _atk_slams(id: int, count: int, gap: float) -> void:
	for i in count:
		KnowsAllTentacle.slam(get_parent(), global_position, target.global_position, target, _tele())
		if not await _wait(id, gap):
			return
	await _wait(id, _tele() + 0.4)

func _atk_bars(id: int, count: int, gap: float) -> void:
	var horizontal := randf() < 0.5
	for i in count:
		_spawn_bar(horizontal)
		horizontal = not horizontal
		if not await _wait(id, gap):
			return
	await _wait(id, _tele() + 0.4)

func _spawn_bar(horizontal: bool) -> void:
	var thick := 22.0
	var p := target.global_position
	var rect: Rect2
	if horizontal:
		var y := clampf(p.y, arena.position.y + thick / 2.0, arena.end.y - thick / 2.0)
		rect = Rect2(arena.position.x, y - thick / 2.0, arena.size.x, thick)
	else:
		var x := clampf(p.x, arena.position.x + thick / 2.0, arena.end.x - thick / 2.0)
		rect = Rect2(x - thick / 2.0, arena.position.y, thick, arena.size.y)
	KnowsAllTentacle.bar(get_parent(), global_position, rect, target, _tele())

func _atk_ring(id: int) -> void:
	_ring_warn = _tele() + 0.2
	if not await _wait(id, _ring_warn):
		return
	_ring_warn = 0.0
	_ring_r = 8.0
	_ring_hit = false
	CameraShake.go(target.get_node_or_null("Camera2D") as Camera2D, 2.5, 0.3)
	get_tree().call_group("glitch_overlay", "flicker", 0.3, 0.8)
	await _wait(id, arena.size.length() / RING_SPEED + 0.2)

func _update_ring(delta: float) -> void:
	if _ring_r < 0.0:
		return
	_ring_r += RING_SPEED * delta
	if not _ring_hit:
		var d := target.global_position.distance_to(global_position)
		if absf(d - _ring_r) <= 6.0:
			_ring_hit = true
			_hurt_player()
	if _ring_r > arena.size.length():
		_ring_r = -1.0

func _hurt_player() -> void:
	var combat := target.get_node_or_null("PlayerCombat") as PlayerCombat
	if combat:
		combat.take_damage(1, global_position)

# ---------- being hit ----------

func _phase_for(h: int) -> int:
	var f := float(h) / max_hp
	if f <= phase3_at:
		return 3
	if f <= phase2_at:
		return 2
	return 1

func take_hit(damage: int, _from_pos: Vector2) -> void:
	if mode != Mode.FIGHT or hp <= 0:
		return
	hp = maxi(hp - damage, 0)
	health_changed.emit(hp, max_hp)
	modulate = Color(3, 3, 3)
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.14)
	if hp <= 0:
		_die()
		return
	var new_phase := _phase_for(hp)
	if new_phase > phase:
		phase = new_phase
		_phase_change()

func _phase_change() -> void:
	_stop_attacks()
	_cooldown = 1.8
	phase_changed.emit(phase)
	CameraShake.go(target.get_node_or_null("Camera2D") as Camera2D, 4.0, 0.5)
	get_tree().call_group("glitch_overlay", "flicker", 0.6, 1.0)
	var pulse := create_tween()
	pulse.tween_property(self, "scale", Vector2.ONE * 1.2, 0.2)
	pulse.tween_property(self, "scale", Vector2.ONE, 0.3)

func _die() -> void:
	_stop_attacks()
	mode = Mode.DEAD
	remove_from_group("enemy")
	var cam: Camera2D = null
	if is_instance_valid(target):
		cam = target.get_node_or_null("Camera2D") as Camera2D
	for i in 5:
		modulate = Color(3, 3, 3)
		CameraShake.go(cam, 3.0 + i, 0.3)
		get_tree().call_group("glitch_overlay", "flicker", 0.3, 1.0)
		create_tween().tween_property(self, "modulate", Color(0.6, 0.3, 0.7), 0.25)
		await get_tree().create_timer(0.4).timeout
	var shrink := create_tween().set_parallel(true)
	shrink.tween_property(self, "scale", Vector2.ONE * 0.1, 0.9)
	shrink.tween_property(self, "modulate:a", 0.0, 0.9)
	await shrink.finished
	defeated.emit(global_position)
	queue_free()

# ---------- looks ----------

func _draw() -> void:
	if _anim == null:
		_draw_placeholder()
	if _ring_warn > 0.0:
		var pulse := 0.5 + 0.5 * sin(_t * 26.0)
		draw_arc(Vector2.ZERO, 34.0 + pulse * 6.0, 0.0, TAU, 48, Color(WARN, 0.9), 2.0)
		draw_string(FONT, Vector2(-3, -50), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 0.3, 0.25))
	if _ring_r > 0.0:
		draw_arc(Vector2.ZERO, _ring_r, 0.0, TAU, 96, Color(WARN, 0.95), 3.0)

func _draw_placeholder() -> void:
	for i in 8:
		var a := TAU * i / 8.0 + sin(_t * 1.5 + i) * 0.15
		var tip := Vector2.from_angle(a) * (40.0 + sin(_t * 3.0 + i * 1.7) * 5.0)
		draw_line(Vector2.from_angle(a) * 16.0, tip, BODY, 7.0)
	draw_circle(Vector2.ZERO, 26.0, BODY)
	draw_arc(Vector2.ZERO, 26.0, 0.0, TAU, 40, Color(WARN, 0.8), 1.5)
	var look := Vector2.ZERO
	if is_instance_valid(target):
		look = (target.global_position - global_position).normalized() * 2.5
	for ex in [-9.0, 9.0]:
		draw_circle(Vector2(ex, -5), 6.0, Color(1, 0.95, 0.8))
		draw_circle(Vector2(ex, -5) + look, 2.8, Color(0.5, 0.05, 0.1))
