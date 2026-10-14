class_name ButcherArena
extends Node2D
## The Butcher fight, staged outside his shop in the village.
## Level2Quest creates one of these and calls begin(). It:
##   - fades out, drops the player and the Butcher into a fenced arena, fades in
##   - locks the camera on the arena, darkens the village a little
##   - turns on PlayerCombat (hearts, attack, dodge) and the HUD
##   - if the player runs out of hearts: shows TRY AGAIN and restarts the fight
##   - when the Butcher falls: removes the fence, restores everything, emits `won`

signal won(at: Vector2)

const FENCE_COLOR := Color(0.78, 0.16, 0.2)

var rect := Rect2()
var player: CharacterBody2D
var boss: ButcherBoss
var combat: PlayerCombat
var hud: CombatHUD

var _fence: Node2D
var _barrier: StaticBody2D
var _camera: Camera2D
var _tint: CanvasModulate
var _fade_layer: CanvasLayer
var _fade: ColorRect
var _t := 0.0
var _resetting := false
var _finished := false

func begin(p_player: CharacterBody2D, p_boss: ButcherBoss, p_rect: Rect2) -> void:
	player = p_player
	boss = p_boss
	rect = p_rect
	_camera = player.get_node_or_null("Camera2D") as Camera2D
	_build_fade()
	player.set_physics_process(false)
	boss.set_physics_process(false)
	await _fade_to(1.0, 0.45)

	_build_barrier()
	_place_fighters()
	_lock_camera()
	_tint = CanvasModulate.new()
	_tint.color = Color.WHITE
	get_parent().add_child(_tint)
	create_tween().tween_property(_tint, "color", Color(0.8, 0.74, 0.76), 0.8)

	combat = PlayerCombat.new()
	combat.name = "PlayerCombat"
	player.add_child(combat)
	hud = CombatHUD.new()
	add_child(hud)
	await get_tree().process_frame
	combat.hearts_changed.connect(hud.set_hearts)
	combat.died.connect(_on_player_died)
	hud.set_hearts(combat.hearts, combat.max_hearts)
	boss.health_changed.connect(hud.set_boss_hp)
	boss.defeated.connect(_on_boss_defeated)

	boss.begin_fight(player, rect)
	boss.set_physics_process(true)
	await _fade_to(0.0, 0.5)
	get_tree().call_group("glitch_overlay", "flicker", 0.5, 1.0)
	CameraShake.go(_camera, 3.5, 0.5)
	hud.show_boss("THE BUTCHER", boss.hp, boss.max_hp)
	hud.flash_message("FIGHT!", 0.6)
	player.set_physics_process(true)

func _process(delta: float) -> void:
	_t += delta
	if _fence:
		_fence.queue_redraw()

# ---------- setup ----------

func _build_fade() -> void:
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 55
	add_child(_fade_layer)
	_fade = ColorRect.new()
	_fade.color = Color(0.08, 0.06, 0.05, 0.0)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_layer.add_child(_fade)

func _fade_to(alpha: float, seconds: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", alpha, seconds)
	await tween.finished

func _build_barrier() -> void:
	_barrier = StaticBody2D.new()
	_barrier.name = "ArenaBarrier"
	_barrier.collision_layer = 1
	_barrier.collision_mask = 0
	add_child(_barrier)
	var thick := 24.0
	var edges := [
		Rect2(rect.position.x - thick, rect.position.y - thick, rect.size.x + thick * 2.0, thick),
		Rect2(rect.position.x - thick, rect.end.y, rect.size.x + thick * 2.0, thick),
		Rect2(rect.position.x - thick, rect.position.y, thick, rect.size.y),
		Rect2(rect.end.x, rect.position.y, thick, rect.size.y),
	]
	for edge: Rect2 in edges:
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = edge.size
		shape.shape = box
		shape.position = edge.position + edge.size / 2.0
		_barrier.add_child(shape)
	_fence = Node2D.new()
	_fence.name = "ArenaFence"
	_fence.z_index = 15
	_fence.modulate.a = 0.0
	_fence.draw.connect(_draw_fence)
	add_child(_fence)
	create_tween().tween_property(_fence, "modulate:a", 1.0, 0.8)

func _draw_fence() -> void:
	var flicker := 0.75 + 0.25 * sin(_t * 14.0)
	var col := Color(FENCE_COLOR, flicker)
	var corners := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
	for i in 4:
		var a: Vector2 = corners[i]
		var b: Vector2 = corners[(i + 1) % 4]
		var length := a.distance_to(b)
		var dir := (b - a) / length
		var d := 0.0
		while d < length:
			var seg := minf(7.0, length - d)
			_fence.draw_line(a + dir * d, a + dir * (d + seg), col, 2.0)
			d += 11.0
	for corner: Vector2 in corners:
		_fence.draw_rect(Rect2(corner - Vector2(2, 6), Vector2(4, 12)), Color(0.2, 0.05, 0.07))
		_fence.draw_circle(corner + Vector2(0, -7), 2.2, col)

func _place_fighters() -> void:
	player.global_position = Vector2(rect.get_center().x, rect.end.y - 26.0)
	player.velocity = Vector2.ZERO
	player.set("facing", "north")
	boss.global_position = Vector2(rect.get_center().x, rect.position.y + 38.0)
	boss.velocity = Vector2.ZERO

func _lock_camera() -> void:
	if _camera == null:
		return
	_camera.position_smoothing_enabled = false
	_camera.top_level = true
	_camera.global_position = rect.get_center()
	_camera.offset = Vector2.ZERO

func _unlock_camera() -> void:
	if _camera == null or not is_instance_valid(_camera):
		return
	_camera.top_level = false
	_camera.position = Vector2.ZERO
	_camera.offset = Vector2.ZERO
	_camera.position_smoothing_enabled = true
	_camera.reset_smoothing()

# ---------- outcomes ----------

func _on_player_died() -> void:
	if _resetting or _finished:
		return
	_resetting = true
	boss.hold_still()
	hud.flash_message("TRY AGAIN", 1.2)
	await get_tree().create_timer(1.5).timeout
	await _fade_to(1.0, 0.4)
	_place_fighters()
	combat.reset()
	boss.reset_fight()
	hud.set_boss_hp(boss.hp, boss.max_hp)
	await _fade_to(0.0, 0.4)
	hud.flash_message("FIGHT!", 0.5)
	_resetting = false

func _on_boss_defeated(at: Vector2) -> void:
	if _finished:
		return
	_finished = true
	combat.disable()
	hud.hide_all()
	var fence_fade := create_tween()
	fence_fade.tween_property(_fence, "modulate:a", 0.0, 1.0)
	if _tint:
		create_tween().tween_property(_tint, "color", Color.WHITE, 1.0)
	await get_tree().create_timer(1.0).timeout
	_unlock_camera()
	_barrier.queue_free()
	won.emit(at)
	await get_tree().create_timer(1.2).timeout
	if _tint:
		_tint.queue_free()
	combat.queue_free()
	queue_free()
