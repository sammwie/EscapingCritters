class_name WallSqueeze
extends CanvasLayer
## The Level 2 scare: wooden walls slide in from all four sides of the screen,
## inching closer in jerky steps while the screen shakes, then pull back.
## It is a scripted story beat, so there is no fail state and nothing collides.
##
## Usage:  await WallSqueeze.play(self, camera)

const PANEL_ART := preload("res://art/interiors/townhall_interior.png")
const WALL_COLOR_EDGE := Color(0.1, 0.07, 0.05, 0.85)

## How far the walls close at each step (0 = open, 1 = touching in the middle).
const STEPS := [0.18, 0.32, 0.46, 0.58, 0.68]

var _camera: Camera2D
var _walls: Array[Control] = []   # top, bottom, left, right
var _progress := 0.0
var _size := Vector2(1920, 1080)

static func play(host: Node, camera: Camera2D) -> void:
	var scare := WallSqueeze.new()
	host.add_child(scare)
	await scare._run(camera)
	scare.queue_free()

func _run(camera: Camera2D) -> void:
	layer = 60
	_camera = camera
	_size = get_viewport().get_visible_rect().size
	_build()
	get_tree().call_group("glitch_overlay", "flicker", 0.5, 1.0)
	await get_tree().create_timer(0.4).timeout
	for step in STEPS:
		# a sudden lurch inward, then it stops and the room holds its breath
		var lurch := create_tween()
		lurch.tween_method(_set_progress, _progress, step, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		CameraShake.go(_camera, 2.5, 0.3)
		await lurch.finished
		await get_tree().create_timer(0.55).timeout
	# hold, shaking harder, with the screen glitching
	for i in 4:
		CameraShake.go(_camera, 4.0, 0.3)
		get_tree().call_group("glitch_overlay", "flicker", 0.3, 1.0)
		await get_tree().create_timer(0.35).timeout
	# the walls snap back
	var release := create_tween()
	release.tween_method(_set_progress, _progress, 0.0, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	get_tree().call_group("glitch_overlay", "flicker", 0.5, 1.0)
	await release.finished

func _build() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	for i in 4:
		var wall := Control.new()
		wall.clip_contents = true
		wall.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(wall)
		var tiles := TextureRect.new()
		var atlas := AtlasTexture.new()
		atlas.atlas = PANEL_ART
		atlas.region = Rect2(32, 32, 32, 32)  # one wood wainscot panel from the townhall art
		tiles.texture = atlas
		tiles.stretch_mode = TextureRect.STRETCH_TILE
		tiles.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tiles.scale = Vector2(3, 3)
		tiles.size = _size
		tiles.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wall.add_child(tiles)
		# dark inner edge so the wall reads as having depth
		var edge := ColorRect.new()
		edge.color = WALL_COLOR_EDGE
		edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		edge.name = "Edge"
		wall.add_child(edge)
		_walls.append(wall)
	_set_progress(0.0)

func _set_progress(p: float) -> void:
	_progress = p
	var half_w := _size.x * 0.5 * p
	var half_h := _size.y * 0.5 * p
	var edge := 14.0
	# top
	_place(_walls[0], Rect2(0, 0, _size.x, half_h), Rect2(0, half_h - edge, _size.x, edge))
	# bottom
	_place(_walls[1], Rect2(0, _size.y - half_h, _size.x, half_h), Rect2(0, 0, _size.x, edge))
	# left
	_place(_walls[2], Rect2(0, 0, half_w, _size.y), Rect2(half_w - edge, 0, edge, _size.y))
	# right
	_place(_walls[3], Rect2(_size.x - half_w, 0, half_w, _size.y), Rect2(0, 0, edge, _size.y))

func _place(wall: Control, rect: Rect2, edge_rect: Rect2) -> void:
	wall.position = rect.position
	wall.size = rect.size
	wall.visible = rect.size.x > 1.0 and rect.size.y > 1.0
	var edge := wall.get_node("Edge") as ColorRect
	edge.position = edge_rect.position
	edge.size = edge_rect.size
