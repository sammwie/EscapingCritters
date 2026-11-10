class_name VillageMap
extends Sprite2D
## The village background. Shows the normal town during Level 1 and swaps to
## the boarded-up Butcher map (with the stone arena) from the morning Level 2
## starts, permanently after that.
##
## Collision that only exists on one version of the map lives under two
## StaticBody2D children of the scene root, "NormalOnly" and "CorruptedOnly",
## which this script switches on and off along with the picture.
## Shared collision (buildings, trees, pond) lives in "MapCollision".

@export var normal_map: Texture2D
@export var corrupted_map: Texture2D

var _corrupted := false
var _first := true

func _ready() -> void:
	centered = false
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = -10
	_apply(_should_corrupt())

func _process(_delta: float) -> void:
	var want := _should_corrupt()
	if want != _corrupted:
		_apply(want)

static func _should_corrupt() -> bool:
	return Level2Quest.stage >= Level2Quest.Stage.EGGS or GameState.current_level >= 3

func _apply(corrupted: bool) -> void:
	if corrupted == _corrupted and not _first:
		return
	_first = false
	_corrupted = corrupted
	texture = corrupted_map if corrupted else normal_map
	var root := get_parent()
	_set_body(root.get_node_or_null("NormalOnly"), not corrupted)
	_set_body(root.get_node_or_null("CorruptedOnly"), corrupted)

func _set_body(body: Node, on: bool) -> void:
	var sb := body as StaticBody2D
	if sb == null:
		return
	sb.collision_layer = 1 if on else 0
