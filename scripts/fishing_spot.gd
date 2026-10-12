class_name FishingSpot
extends Interactable
## A patch of water the player can fish in. Placeholder visuals: a blue
## rectangle that shows a yellow dot when a fish bites.
## Scene: Area2D (this script) > CollisionShape2D (RectangleShape2D, 64x40)
##                             > Node named "Fishing" (fishing.gd)
## Collision: Layer 2 only, Mask empty.
## Press E to cast, press E again when the dot appears.

@export var size := Vector2(64, 40)

@onready var fishing: Fishing = get_node_or_null("Fishing")

func _ready() -> void:
	if fishing == null:
		push_warning("FishingSpot '%s' needs a child node named Fishing." % name)
		return
	fishing.state_changed.connect(_on_state_changed)
	_on_state_changed(Fishing.State.IDLE)

func _draw() -> void:
	draw_rect(Rect2(-size / 2.0, size), Color("3b7ddd"))
	if fishing and fishing.state == Fishing.State.BITE:
		draw_circle(Vector2.ZERO, 8.0, Color("ffd23f"))

func _on_interact(_by: Node) -> void:
	if fishing == null:
		return
	if fishing.running:
		fishing.reel()
	else:
		fishing.start()

func _on_state_changed(new_state: int) -> void:
	match new_state:
		Fishing.State.IDLE: prompt_text = "Cast line"
		Fishing.State.WAITING: prompt_text = "Waiting... (E to cancel)"
		Fishing.State.BITE: prompt_text = "Reel in!"
	queue_redraw()
