class_name PlayerCombat
extends Node
## Real-time combat for the player (Level 2 Butcher fight, Level 5 boss).
## Add as a child of the Player. Controls:  Space / J = attack,  Shift = dodge roll.
## Hearts: the player has `max_hearts`; at 0 the `died` signal fires.
## Dodging gives a short window where hits can't land.
##
## The player's normal movement script is paused while dodging or being
## knocked back, and this node moves the player itself during that time.

signal hearts_changed(hearts: int, max_hearts: int)
signal died
signal attacked

@export var max_hearts := 3
@export var attack_cooldown := 0.38
@export var attack_reach := 30.0
@export var attack_half_arc_deg := 75.0
@export var dodge_speed := 210.0
@export var dodge_time := 0.24
@export var dodge_cooldown := 0.7
@export var hurt_invulnerable := 1.1

const DIRS := ["east", "south-east", "south", "south-west", "west", "north-west", "north", "north-east"]

var hearts := 3
var enabled := true
var player: CharacterBody2D

var _attack_cd := 0.0
var _dodge_cd := 0.0
var _dodge_t := 0.0
var _dodge_dir := Vector2.ZERO
var _invuln := 0.0
var _knock_t := 0.0
var _knock_vel := Vector2.ZERO
var _dead := false

func _ready() -> void:
	CombatInput.ensure()
	player = get_parent() as CharacterBody2D
	hearts = max_hearts
	hearts_changed.emit(hearts, max_hearts)

func facing_vector() -> Vector2:
	var index := DIRS.find(String(player.get("facing")))
	if index < 0:
		index = 2
	return Vector2.from_angle(index * PI / 4.0)

func is_invulnerable() -> bool:
	return _invuln > 0.0

func _process(delta: float) -> void:
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	_dodge_cd = maxf(_dodge_cd - delta, 0.0)
	_invuln = maxf(_invuln - delta, 0.0)
	var sprite := player.get_node_or_null("CritterSprite") as AnimatedSprite2D
	if sprite:
		var blink := _invuln > 0.0 and _dodge_t <= 0.0 and (int(Time.get_ticks_msec() / 80.0) % 2 == 0)
		sprite.modulate.a = 0.35 if blink else 1.0

func _unhandled_input(event: InputEvent) -> void:
	if not enabled or _dead or Dialogue.active:
		return
	if _dodge_t > 0.0 or _knock_t > 0.0:
		return
	if event.is_action_pressed("attack") and _attack_cd <= 0.0:
		_do_attack()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("dodge") and _dodge_cd <= 0.0:
		_do_dodge()
		get_viewport().set_input_as_handled()

func _do_attack() -> void:
	_attack_cd = attack_cooldown
	var dir := facing_vector()
	# light aim assist: swing toward the nearest enemy that is close enough
	var best: Node2D = null
	var best_d := attack_reach * 1.5
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy is Node2D and enemy.has_method("take_hit"):
			var d := player.global_position.distance_to(enemy.global_position)
			if d < best_d:
				best_d = d
				best = enemy
	if best:
		dir = (best.global_position - player.global_position).normalized()
	SlashFX.spawn(player.get_parent(), player.global_position + dir * 8.0, dir, attack_reach)
	attacked.emit()
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not (enemy is Node2D and enemy.has_method("take_hit")):
			continue
		var to: Vector2 = enemy.global_position - player.global_position
		var radius: float = float(enemy.get("hit_radius")) if enemy.get("hit_radius") != null else 8.0
		if to.length() <= attack_reach + radius and absf(rad_to_deg(dir.angle_to(to))) <= attack_half_arc_deg:
			enemy.take_hit(1, player.global_position)
			CameraShake.go(player.get_node_or_null("Camera2D") as Camera2D, 1.5, 0.12)

func _do_dodge() -> void:
	_dodge_cd = dodge_cooldown
	_dodge_t = dodge_time
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_dodge_dir = dir.normalized() if dir != Vector2.ZERO else facing_vector()
	_invuln = maxf(_invuln, dodge_time + 0.08)
	player.set_physics_process(false)
	var sprite := player.get_node_or_null("CritterSprite") as Node2D
	if sprite:
		var spin := sprite.create_tween()
		spin.tween_property(sprite, "rotation", TAU * (1.0 if _dodge_dir.x >= 0.0 else -1.0), dodge_time)
		spin.tween_callback(func() -> void: sprite.rotation = 0.0)

func _physics_process(delta: float) -> void:
	if _dodge_t > 0.0:
		player.velocity = _dodge_dir * dodge_speed
		player.move_and_slide()
		_dodge_t -= delta
		if _dodge_t <= 0.0 and _knock_t <= 0.0:
			player.set_physics_process(true)
	elif _knock_t > 0.0:
		player.velocity = _knock_vel
		player.move_and_slide()
		_knock_t -= delta
		_knock_vel = _knock_vel.move_toward(Vector2.ZERO, 600.0 * delta)
		if _knock_t <= 0.0:
			player.set_physics_process(true)

## Called by enemies. Does nothing while the player is dodging or recovering.
func take_damage(amount: int, from_pos: Vector2) -> void:
	if not enabled or _dead or _invuln > 0.0:
		return
	hearts = maxi(hearts - amount, 0)
	hearts_changed.emit(hearts, max_hearts)
	_invuln = hurt_invulnerable
	var away := (player.global_position - from_pos).normalized()
	if away == Vector2.ZERO:
		away = Vector2.UP
	_knock_vel = away * 170.0
	_knock_t = 0.16
	_dodge_t = 0.0
	player.set_physics_process(false)
	CameraShake.go(player.get_node_or_null("Camera2D") as Camera2D, 3.0, 0.25)
	get_tree().call_group("glitch_overlay", "flicker", 0.25, 0.8)
	if hearts <= 0:
		_dead = true
		died.emit()

func reset() -> void:
	hearts = max_hearts
	_dead = false
	_invuln = 0.8
	_knock_t = 0.0
	_dodge_t = 0.0
	player.set_physics_process(true)
	hearts_changed.emit(hearts, max_hearts)

## Turns combat off and gives the player their normal movement back.
func disable() -> void:
	enabled = false
	_knock_t = 0.0
	_dodge_t = 0.0
	player.set_physics_process(true)
	var sprite := player.get_node_or_null("CritterSprite") as Node2D
	if sprite:
		sprite.modulate.a = 1.0
		sprite.rotation = 0.0
