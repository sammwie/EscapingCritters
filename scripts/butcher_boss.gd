class_name ButcherBoss
extends CharacterBody2D
## The corrupted Town Butcher. Has two jobs in Level 2:
##   FOLLOW - the warning sign. He trails the player around the village and can
##            be talked to (the Talk prompt starts the fight).
##   FIGHT  - real-time action boss. He telegraphs every attack (red warning on
##            the ground and a "!"), so the player can dodge or hit and run.
##
## Attacks:  cleaver swing (close range) and a charge across the arena. If the
## charge hits a wall he is stunned and takes double damage.
## Below half health he gets faster and telegraphs for less time.
##
## Build one with ButcherBoss.new(), add it to the level, then call
## begin_follow(player) or begin_fight(player, arena_rect).

signal talked
signal health_changed(hp: int, max_hp: int)
signal defeated(at: Vector2)

enum Mode { IDLE, FOLLOW, FIGHT, DEAD }
enum St { WAIT, CHASE, TELE_SWING, SWING, TELE_CHARGE, CHARGE, RECOVER, STUNNED }

const DIRS := ["east", "south-east", "south", "south-west", "west", "north-west", "north", "north-east"]
const ART_FOLDER := "res://art/butcher_l2"
const CORRUPT_SHADER := preload("res://corrupt_tint.gdshader")
const FONT := preload("res://art/fonts/Silkscreen-Bold.ttf")
const WARN := Color(0.85, 0.15, 0.15)

@export var max_hp := 10
@export var follow_speed := 36.0
@export var follow_distance := 38.0
@export var chase_speed := 46.0
@export var charge_speed := 250.0

var hp := 10
var hit_radius := 8.0
var mode := Mode.IDLE
var st := St.WAIT
var target: Node2D = null
var arena := Rect2()

var _sprite: Sprite2D
var _mat: ShaderMaterial
var _talk: Interactable
var _textures := {}
var _facing := ""
var _timer := 0.0
var _decision := 1.2
var _aim := Vector2.DOWN
var _kb := Vector2.ZERO
var _charge_hit := false
var _last_attack := ""
var _t := 0.0

func _ready() -> void:
	add_to_group("enemy")
	collision_layer = 8
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var body := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 6.0
	body.shape = circle
	body.name = "Body"
	add_child(body)

	add_child(SoftShadow.make(Vector2(0, 10), Vector2(8, 3)))

	_sprite = Sprite2D.new()
	_sprite.name = "Sprite"
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2.ONE * 1.7
	_mat = ShaderMaterial.new()
	_mat.shader = CORRUPT_SHADER
	_mat.set_shader_parameter("amount", 0.0)
	_sprite.material = _mat
	add_child(_sprite)
	_load_textures()
	_set_facing("south")

	_talk = Interactable.new()
	_talk.name = "Talk"
	_talk.prompt_text = "Talk"
	_talk.collision_layer = 2
	_talk.collision_mask = 0
	_talk.enabled = false
	var talk_shape := CollisionShape2D.new()
	var talk_circle := CircleShape2D.new()
	talk_circle.radius = 18.0
	talk_shape.shape = talk_circle
	_talk.add_child(talk_shape)
	_talk.interacted.connect(func(_by: Node) -> void: talked.emit())
	add_child(_talk)
	hp = max_hp

# ---------- modes ----------

func begin_follow(player: Node2D) -> void:
	target = player
	mode = Mode.FOLLOW
	_talk.enabled = true
	_set_corruption(0.2, 0.5)

func begin_fight(player: Node2D, rect: Rect2) -> void:
	target = player
	arena = rect
	mode = Mode.FIGHT
	_talk.enabled = false
	hp = max_hp
	st = St.WAIT
	_timer = 1.3
	_decision = 1.0
	_kb = Vector2.ZERO
	health_changed.emit(hp, max_hp)
	_set_corruption(0.4, 0.8)
	var grow := create_tween()
	grow.tween_property(_sprite, "scale", Vector2.ONE * 2.0, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Starts the fight over (used after the player is defeated).
func reset_fight() -> void:
	hp = max_hp
	st = St.WAIT
	_timer = 1.3
	_decision = 1.0
	_kb = Vector2.ZERO
	_sprite.rotation = 0.0
	health_changed.emit(hp, max_hp)

## Freezes the fight in place (used while the "try again" message shows).
func hold_still() -> void:
	st = St.WAIT
	_timer = 99.0
	velocity = Vector2.ZERO

func _set_corruption(amount: float, fade: float) -> void:
	var tween := create_tween()
	tween.tween_method(func(v: float) -> void: _mat.set_shader_parameter("amount", v), float(_mat.get_shader_parameter("amount")), amount, fade)

# ---------- loop ----------

func _physics_process(delta: float) -> void:
	_t += delta
	match mode:
		Mode.FOLLOW:
			_follow()
		Mode.FIGHT:
			_fight(delta)
	queue_redraw()

func _follow() -> void:
	if target == null or not is_instance_valid(target):
		return
	var to := target.global_position - global_position
	_face(to)
	if Dialogue.active or to.length() <= follow_distance:
		velocity = Vector2.ZERO
	else:
		velocity = to.normalized() * follow_speed
	move_and_slide()

func _fight(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	_timer -= delta
	var to := target.global_position - global_position
	var phase2 := hp <= max_hp / 2
	var speed_mul := 1.25 if phase2 else 1.0
	var tele_mul := 0.8 if phase2 else 1.0
	velocity = Vector2.ZERO

	match st:
		St.WAIT:
			_face(to)
			if _timer <= 0.0:
				st = St.CHASE
				_decision = randf_range(0.9, 1.4)
		St.CHASE:
			_face(to)
			if to.length() > 34.0:
				velocity = to.normalized() * chase_speed * speed_mul
			_decision -= delta
			if _decision <= 0.0:
				_pick_attack(to, tele_mul)
		St.TELE_SWING:
			_face(_aim)
			if _timer <= 0.0:
				_do_swing()
		St.SWING:
			if _timer <= 0.0:
				_recover(0.55)
		St.TELE_CHARGE:
			if _timer > 0.22:
				_aim = to.normalized()   # keeps tracking, then locks in for the last moment
			_face(_aim)
			if _timer <= 0.0:
				st = St.CHARGE
				_timer = 0.55
				_charge_hit = false
		St.CHARGE:
			velocity = _aim * charge_speed * speed_mul
			if not _charge_hit and to.length() < 13.0:
				_charge_hit = true
				_hurt_player()
		St.RECOVER:
			if _timer <= 0.0:
				st = St.CHASE
				_decision = randf_range(0.8, 1.3)
		St.STUNNED:
			if _timer <= 0.0:
				_recover(0.3)

	velocity += _kb
	_kb = _kb.move_toward(Vector2.ZERO, 420.0 * delta)
	move_and_slide()

	if st == St.CHARGE and get_slide_collision_count() > 0 and _timer < 0.5:
		_stun()
	elif st == St.CHARGE and _timer <= 0.0:
		_recover(0.6)

func _pick_attack(to: Vector2, tele_mul: float) -> void:
	var want_swing := to.length() < 56.0 and randf() < 0.7
	if _last_attack == "swing" and to.length() > 40.0:
		want_swing = false
	if want_swing:
		_last_attack = "swing"
		st = St.TELE_SWING
		_timer = 0.6 * tele_mul
		_aim = to.normalized()
	else:
		_last_attack = "charge"
		st = St.TELE_CHARGE
		_timer = 0.9 * tele_mul
		_aim = to.normalized()

func _do_swing() -> void:
	st = St.SWING
	_timer = 0.2
	SlashFX.spawn(get_parent(), global_position + _aim * 10.0, _aim, 40.0, Color(1, 0.4, 0.35))
	var to := target.global_position - global_position
	if to.length() <= 40.0 and absf(rad_to_deg(_aim.angle_to(to))) <= 75.0:
		_hurt_player()
	CameraShake.go(target.get_node_or_null("Camera2D") as Camera2D, 1.5, 0.15)

func _recover(seconds: float) -> void:
	st = St.RECOVER
	_timer = seconds

func _stun() -> void:
	st = St.STUNNED
	_timer = 1.7
	_kb = -_aim * 60.0
	CameraShake.go(target.get_node_or_null("Camera2D") as Camera2D, 3.0, 0.3)
	get_tree().call_group("glitch_overlay", "flicker", 0.2, 0.7)

func _hurt_player() -> void:
	var combat := target.get_node_or_null("PlayerCombat") as PlayerCombat
	if combat:
		combat.take_damage(1, global_position)

# ---------- being hit ----------

func take_hit(damage: int, from_pos: Vector2) -> void:
	if mode != Mode.FIGHT or hp <= 0:
		return
	var multiplier := 2 if st == St.STUNNED else 1
	hp = maxi(hp - damage * multiplier, 0)
	health_changed.emit(hp, max_hp)
	_kb = (global_position - from_pos).normalized() * 110.0
	var flash := create_tween()
	_sprite.modulate = Color(3, 3, 3)
	flash.tween_property(_sprite, "modulate", Color.WHITE, 0.14)
	if hp <= 0:
		_die()

func _die() -> void:
	mode = Mode.DEAD
	st = St.WAIT
	velocity = Vector2.ZERO
	remove_from_group("enemy")
	_talk.enabled = false
	collision_layer = 0
	var tween := create_tween()
	tween.tween_property(_sprite, "rotation", deg_to_rad(90.0), 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_sprite, "scale", Vector2.ONE * 1.6, 0.5)
	get_tree().call_group("glitch_overlay", "flicker", 0.6, 1.0)
	CameraShake.go(target.get_node_or_null("Camera2D") as Camera2D, 4.0, 0.5)
	await get_tree().create_timer(1.1).timeout
	defeated.emit(global_position)
	var fade := create_tween()
	fade.tween_property(_sprite, "modulate:a", 0.0, 0.9)
	await fade.finished
	queue_free()

# ---------- looks ----------

func _load_textures() -> void:
	for dir in DIRS:
		var path := "%s/%s.png" % [ART_FOLDER, dir]
		if ResourceLoader.exists(path):
			_textures[dir] = load(path)

func _set_facing(dir: String) -> void:
	if dir == _facing or not _textures.has(dir):
		return
	_facing = dir
	_sprite.texture = _textures[dir]

func _face(v: Vector2) -> void:
	if v.length() < 0.01:
		return
	_set_facing(DIRS[wrapi(roundi(v.angle() / (PI / 4.0)), 0, 8)])

func _draw() -> void:
	if mode != Mode.FIGHT:
		return
	var pulse := 0.16 + 0.14 * sin(_t * 22.0)
	match st:
		St.TELE_SWING:
			var a := _aim.angle()
			var spread := deg_to_rad(75.0)
			var pts := PackedVector2Array([Vector2.ZERO])
			for i in 13:
				pts.append(Vector2.from_angle(a - spread + spread * 2.0 * i / 12.0) * 40.0)
			draw_colored_polygon(pts, Color(WARN, pulse + 0.1))
			draw_arc(Vector2.ZERO, 40.0, a - spread, a + spread, 14, Color(WARN, 0.9), 1.5)
			_draw_bang()
		St.TELE_CHARGE:
			var length := 170.0
			var side := _aim.orthogonal() * 8.0
			var pts := PackedVector2Array([side, _aim * length + side, _aim * length - side, -side])
			draw_colored_polygon(pts, Color(WARN, pulse))
			draw_line(Vector2.ZERO, _aim * length, Color(WARN, 0.8), 1.5)
			_draw_bang()
		St.STUNNED:
			for i in 3:
				var ang := _t * 5.0 + i * TAU / 3.0
				var p := Vector2(cos(ang) * 10.0, -22.0 + sin(ang) * 3.0)
				draw_circle(p, 1.8, Color(1, 0.85, 0.3))

func _draw_bang() -> void:
	draw_string(FONT, Vector2(-3, -26), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.1, 0.05, 0.05))
	draw_string(FONT, Vector2(-4, -27), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 0.3, 0.25))
