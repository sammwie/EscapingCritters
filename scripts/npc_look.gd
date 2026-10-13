class_name NPCLook
extends Node

## Add this as a child of any NPC node. Point art_folder at a character's
## art folder and it shows the right 8-direction sprite, turning to face
## the player when they walk close, then turning back when they leave.
## It only handles visuals, so Coder 2's NPC dialogue keeps working as is.

@export_dir var art_folder := "res://art/villager-01"
@export var face_player := true
@export var face_range := 40.0
## The camera zooms the whole world, so art stays at its native size.
@export var sprite_scale := 1.5
@export_enum("south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west")
var default_facing := "south"

# Ordered by angle, starting at east and going clockwise (Godot's y points down).
const DIRS := ["east", "south-east", "south", "south-west", "west", "north-west", "north", "north-east"]

var _textures := {}
var _sprite: Sprite2D
var _npc: Node2D
var _player: Node2D
var _facing := ""

func _ready() -> void:
	_npc = get_parent() as Node2D
	_load_textures()
	_sprite = _find_or_make_sprite()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2.ONE * sprite_scale
	set_facing(default_facing)

func _process(_delta: float) -> void:
	if not face_player or _npc == null:
		return
	var player := _get_player()
	if player == null:
		return
	var to_player := player.global_position - _npc.global_position
	if to_player.length() > face_range:
		set_facing(default_facing)
		return
	var index := wrapi(roundi(to_player.angle() / (PI / 4.0)), 0, 8)
	set_facing(DIRS[index])

func set_facing(dir: String) -> void:
	if dir == _facing or not _textures.has(dir):
		return
	_facing = dir
	_sprite.texture = _textures[dir]

func _load_textures() -> void:
	# Some art folders keep the PNGs inside a "rotations" subfolder, some don't.
	var folder := art_folder.trim_suffix("/")
	if not ResourceLoader.exists(folder + "/south.png") and ResourceLoader.exists(folder + "/rotations/south.png"):
		folder += "/rotations"
	for dir in DIRS:
		var path: String = "%s/%s.png" % [folder, dir]
		if ResourceLoader.exists(path):
			_textures[dir] = load(path)
	if _textures.is_empty():
		push_warning("NPCLook: no sprites found in " + art_folder)

func _find_or_make_sprite() -> Sprite2D:
	var parent := get_parent()
	for child in parent.get_children():
		if child is Sprite2D:
			return child
	# No Sprite2D: hide any placeholder AnimatedSprite2D and add our own.
	for child in parent.get_children():
		if child is AnimatedSprite2D:
			child.visible = false
	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	parent.add_child.call_deferred(sprite)
	return sprite

func _get_player() -> Node2D:
	if is_instance_valid(_player):
		return _player
	_player = get_tree().get_first_node_in_group("player") as Node2D
	if _player == null and get_tree().current_scene:
		_player = get_tree().current_scene.find_child("Player", true, false) as Node2D
	return _player
