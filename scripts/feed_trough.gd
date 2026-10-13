class_name FeedTrough
extends Interactable
## The chicken feed trough. Press E to fill it, which tells Level1Quest
## the chickens are fed (and the hens lay eggs).
## Scene: Area2D (this script) > CollisionShape2D. Layer 2, mask empty.

const SHEET := preload("res://art/animals/trough.png")

var _sprite: Sprite2D

func _ready() -> void:
	prompt_text = "Feed chickens"
	add_to_group("feed_troughs")
	_sprite = Sprite2D.new()
	_sprite.texture = SHEET
	_sprite.hframes = 2
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)
	refresh()

func refresh() -> void:
	_sprite.frame = 1 if Level1Quest.fed else 0
	enabled = Level1Quest.stage >= Level1Quest.Stage.FEED and not Level1Quest.fed

func _on_interact(_by: Node) -> void:
	Level1Quest.feed_chickens()
	refresh()
