extends CharacterBody2D
## The critter. Builds its own 8-direction walk and idle animations from
## res://art/critter, so no SpriteFrames setup is needed in the editor.
## Freezes while dialogue is open.

@export var speed := 70.0
@export var art_root := "res://art/critter"
@export var walk_fps := 10.0
## 1.5 keeps pixels even at the camera's 4x zoom (1.5 x 4 = 6).
@export var sprite_scale := 1.5

const DIRS := ["east", "south-east", "south", "south-west", "west", "north-west", "north", "north-east"]

var sprite: AnimatedSprite2D
var facing := "south"

func _ready() -> void:
	add_to_group("player")
	# Hide the placeholder icon and use an animated sprite instead.
	for child in get_children():
		if child is Sprite2D:
			child.visible = false
	sprite = AnimatedSprite2D.new()
	sprite.name = "CritterSprite"
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.sprite_frames = _build_frames()
	sprite.scale = Vector2.ONE * sprite_scale
	add_child(sprite)
	_play("idle")
	_apply_spawn.call_deferred()

func _physics_process(_delta: float) -> void:
	if Dialogue.active:
		velocity = Vector2.ZERO
		_play("idle")
		return
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * speed
	move_and_slide()
	if dir == Vector2.ZERO:
		_play("idle")
	else:
		facing = DIRS[wrapi(roundi(dir.angle() / (PI / 4.0)), 0, 8)]
		_play("walk")

func _play(kind: String) -> void:
	var anim: String = kind + "_" + facing
	if sprite.sprite_frames.has_animation(anim) and sprite.animation != anim:
		sprite.play(anim)

func _build_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for dir in DIRS:
		var walk: String = "walk_" + dir
		frames.add_animation(walk)
		frames.set_animation_speed(walk, walk_fps)
		var i := 0
		while true:
			var path := "%s/animations/Walking/%s/frame_%03d.png" % [art_root, dir, i]
			if not ResourceLoader.exists(path):
				break
			frames.add_frame(walk, load(path))
			i += 1

		var idle: String = "idle_" + dir
		frames.add_animation(idle)
		var idle_path := "%s/rotations/%s.png" % [art_root, dir]
		if ResourceLoader.exists(idle_path):
			frames.add_frame(idle, load(idle_path))
		elif frames.get_frame_count(walk) > 0:
			frames.add_frame(idle, frames.get_frame_texture(walk, 0))
	return frames

# If we arrived through a SceneDoor, jump to the Marker2D it named.
func _apply_spawn() -> void:
	var tree_root := get_tree().root
	if not tree_root.has_meta("spawn_at"):
		return
	var spot: String = tree_root.get_meta("spawn_at")
	tree_root.remove_meta("spawn_at")
	var scene_root: Node = owner if owner else get_parent()
	var marker := scene_root.find_child(spot, true, false) as Node2D
	if marker == null:
		return
	global_position = marker.global_position
	facing = String(marker.get_meta("facing", facing))
	_play("idle")
	for child in get_children():
		if child is Camera2D:
			child.reset_smoothing()
