class_name ShopCounter
extends Interactable
## The shop counter. Press E to sell everything the farm and fishing spot
## have collected. Placeholder visuals: a brown rectangle with the gold total.
## Scene: Area2D (this script) > CollisionShape2D (RectangleShape2D, 64x32)
##                             > Node named "Shop" (shop.gd)
## Collision: Layer 2 only, Mask empty.
## In the Inspector, optionally point farm_manager_path / fishing_spot_path
## at those nodes in the same scene.

@export var size := Vector2(64, 32)
@export var farm_manager_path: NodePath
@export var fishing_spot_path: NodePath

@onready var shop: Shop = get_node_or_null("Shop")

var last_earned := 0

func _ready() -> void:
	prompt_text = "Sell goods"
	if shop == null:
		push_warning("ShopCounter '%s' needs a child node named Shop." % name)

func _draw() -> void:
	draw_rect(Rect2(-size / 2.0, size), Color("8b5a2b"))
	var gold := shop.gold if shop else 0
	var text := "Gold: %d" % gold
	if last_earned > 0:
		text += "  (+%d)" % last_earned
	draw_string(ThemeDB.fallback_font, Vector2(-size.x / 2.0, -size.y / 2.0 - 6.0), text)

func _on_interact(_by: Node) -> void:
	if shop == null:
		return
	var total := 0
	if not farm_manager_path.is_empty():
		var fm := get_node_or_null(farm_manager_path) as FarmManager
		if fm:
			total += shop.sell_all(fm.harvest_counts)
	if not fishing_spot_path.is_empty():
		var spot := get_node_or_null(fishing_spot_path) as FishingSpot
		if spot and spot.fishing:
			total += shop.sell_all(spot.fishing.catch_counts)
	last_earned = total
	queue_redraw()
