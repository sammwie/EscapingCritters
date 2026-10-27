class_name HidingSpot
extends Interactable
## A bush (or anything) the player can hide in. Press interact to hide,
## press interact again to come out. Guards can't see a hidden player.

@export var radius := 14.0

var is_hiding := false
var _return_pos := Vector2.ZERO
var _last_toggle := 0

func _ready() -> void:
	add_to_group("hiding_spot")
	prompt_text = "Hide"
	collision_layer = 2
	collision_mask = 0
	if not _has_shape():
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = radius + 6.0
		shape.shape = circle
		add_child(shape)

func _has_shape() -> bool:
	for child in get_children():
		if child is CollisionShape2D:
			return true
	return false

func _on_interact(_by: Node) -> void:
	_toggle()

func _unhandled_input(event: InputEvent) -> void:
	if is_hiding and event is InputEventKey and event.pressed and not event.echo \
			and (event.keycode == KEY_E or event.is_action_pressed("ui_accept")):
		_toggle()

func _toggle() -> void:
	var now := Time.get_ticks_msec()
	if now - _last_toggle < 250:
		return
	_last_toggle = now
	if is_hiding:
		release()
	else:
		_hide()

func _hide() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	is_hiding = true
	prompt_text = "Leave"
	_return_pos = player.global_position
	player.global_position = global_position
	player.set_meta("hidden", true)
	player.visible = false
	player.set_physics_process(false)
	queue_redraw()

func release() -> void:
	if not is_hiding:
		return
	is_hiding = false
	prompt_text = "Hide"
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player:
		player.global_position = _return_pos
		player.set_meta("hidden", false)
		player.visible = true
		player.set_physics_process(true)
	queue_redraw()

func _draw() -> void:
	# Placeholder bush (designers replace).
	var c := Color(0.12, 0.45, 0.2, 0.95) if not is_hiding else Color(0.2, 0.6, 0.3, 0.95)
	draw_circle(Vector2.ZERO, radius, c)
	draw_circle(Vector2(-4, -3), radius * 0.55, c.lightened(0.15))
